import json
import logging
import sys
from contextvars import ContextVar
from datetime import datetime, timezone
from typing import Optional

request_id_ctx_var: ContextVar[Optional[str]] = ContextVar("request_id", default=None)
experiment_id_ctx_var: ContextVar[Optional[str]] = ContextVar("experiment_id", default=None)


class StructuredJsonFormatter(logging.Formatter):
    """
    Outputs log records as structured JSON dictionaries containing timestamp,
    severity, logger name, message, location, and injected context IDs.
    """

    def format(self, record: logging.LogRecord) -> str:
        log_entry = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "location": f"{record.filename}:{record.lineno}",
        }

        req_id = request_id_ctx_var.get()
        if req_id:
            log_entry["request_id"] = req_id

        exp_id = experiment_id_ctx_var.get()
        if exp_id:
            log_entry["experiment_id"] = exp_id

        # Merge standard extra attributes if passed
        for key, value in record.__dict__.items():
            if key not in {
                "args", "asctime", "created", "exc_info", "exc_text", "filename",
                "funcName", "levelname", "levelno", "lineno", "module", "msecs",
                "msg", "name", "pathname", "process", "processName", "relativeCreated",
                "stack_info", "thread", "threadName", "context_tags"
            } and not key.startswith("_"):
                log_entry[key] = value

        if record.exc_info:
            log_entry["exception"] = self.formatException(record.exc_info)

        return json.dumps(log_entry, default=str)


class ContextTextFormatter(logging.Formatter):
    """
    Human-readable text formatter that prepends request_id and experiment_id
    tags when active.
    """

    def format(self, record: logging.LogRecord) -> str:
        req_id = request_id_ctx_var.get()
        exp_id = experiment_id_ctx_var.get()

        tags = []
        if req_id:
            tags.append(f"req:{req_id[:8]}")
        if exp_id:
            tags.append(f"exp:{exp_id[:8]}")

        record.context_tags = f"[{'|'.join(tags)}] " if tags else ""
        return super().format(record)


def setup_logging(
    log_level: Optional[str] = None,
    log_format: Optional[str] = None,
) -> None:
    """Configures application logging with optional JSON or human-readable formats."""
    from app.core.config import settings

    level_str = log_level or settings.LOG_LEVEL
    format_str = log_format or settings.LOG_FORMAT
    numeric_level = getattr(logging, level_str.upper(), logging.INFO)

    if format_str.lower() == "json":
        formatter = StructuredJsonFormatter()
    else:
        formatter = ContextTextFormatter(
            fmt="%(asctime)s [%(levelname)s] %(context_tags)s%(name)s (%(filename)s:%(lineno)d): %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
        )

    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(formatter)

    root_logger = logging.getLogger()
    root_logger.setLevel(numeric_level)

    # Remove existing handlers to avoid duplicates
    if root_logger.hasHandlers():
        root_logger.handlers.clear()

    root_logger.addHandler(handler)

    # Silence overly verbose external loggers
    logging.getLogger("aiosqlite").setLevel(logging.WARNING)
    logging.getLogger("httpcore").setLevel(logging.WARNING)
    logging.getLogger("httpx").setLevel(logging.WARNING)


logger = logging.getLogger("parallax_eval")

