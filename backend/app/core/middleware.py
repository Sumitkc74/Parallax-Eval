import time
import uuid
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

from app.core.logging import logger, request_id_ctx_var


class RequestTracingMiddleware(BaseHTTPMiddleware):
    """
    Middleware that:
    1. Extracts incoming X-Request-ID header or generates a new UUID.
    2. Stores the request_id in an async ContextVar for automatic log correlation.
    3. Injects X-Request-ID into the outgoing response headers.
    4. Logs execution latency and status codes for API observability.
    """

    async def dispatch(self, request: Request, call_next) -> Response:
        req_id = request.headers.get("X-Request-ID") or uuid.uuid4().hex
        token = request_id_ctx_var.set(req_id)
        start_time = time.perf_counter()

        try:
            response = await call_next(request)
            duration_ms = round((time.perf_counter() - start_time) * 1000, 2)
            response.headers["X-Request-ID"] = req_id

            # Avoid log flooding for frequent readiness/liveness polling unless error occurred
            is_health_check = request.url.path in (
                "/health",
                "/ready",
                "/api/v1/health",
                "/api/v1/ready",
            )
            if not is_health_check or response.status_code >= 400:
                logger.info(
                    f"{request.method} {request.url.path} -> {response.status_code} ({duration_ms}ms)",
                    extra={
                        "request_id": req_id,
                        "method": request.method,
                        "path": request.url.path,
                        "status_code": response.status_code,
                        "duration_ms": duration_ms,
                    },
                )
            return response
        except Exception as exc:
            duration_ms = round((time.perf_counter() - start_time) * 1000, 2)
            logger.error(
                f"Unhandled error in {request.method} {request.url.path}: {exc}",
                exc_info=True,
                extra={
                    "request_id": req_id,
                    "method": request.method,
                    "path": request.url.path,
                    "duration_ms": duration_ms,
                },
            )
            raise
        finally:
            request_id_ctx_var.reset(token)


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """
    Injects OWASP-recommended security headers into all outgoing HTTP responses:
    - X-Content-Type-Options: nosniff (Blocks MIME-type sniffing)
    - X-Frame-Options: DENY (Prevents Clickjacking)
    - Referrer-Policy: strict-origin-when-cross-origin
    - X-XSS-Protection: 0 (Sanitizer disabled in favor of CSP)
    - Permissions-Policy: Restricts browser features
    - Strict-Transport-Security: Enforces HTTPS connections
    """

    async def dispatch(self, request: Request, call_next) -> Response:
        response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["X-XSS-Protection"] = "0"
        response.headers["Permissions-Policy"] = "geolocation=(), camera=(), microphone=()"
        if request.url.scheme == "https" or request.headers.get("x-forwarded-proto") == "https":
            response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        return response

