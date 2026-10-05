from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.router import api_v1_router
from app.api.v1 import health
from app.core.config import settings
from app.core.middleware import RequestTracingMiddleware, SecurityHeadersMiddleware
from app.core.database import engine, Base, async_session_maker
from app.core.logging import setup_logging, logger
from app.seed.seed_db import seed_benchmark_dataset
from app.services.worker_supervisor import supervisor


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan event handler to initialize database tables, seed baseline data, and recover zombie jobs."""
    setup_logging()
    logger.info(f"Starting {settings.PROJECT_NAME} v{settings.VERSION} [{settings.ENVIRONMENT}]")

    # In development/SQLite mode, automatically create tables if not present
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    # Seed baseline benchmark data if empty
    async with async_session_maker() as session:
        await seed_benchmark_dataset(session)

    # Startup recovery: sweep orphaned 'RUNNING' experiment tasks left by previous process crash
    await supervisor.recover_zombie_experiments(async_session_maker)

    yield

    logger.info(f"Shutting down {settings.PROJECT_NAME}")
    await engine.dispose()


app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description=(
        "Full-stack Cross-Lingual English–Nepali LLM Safety Evaluation Platform. "
        "Provides REST APIs for experiment orchestration, multi-agent LangGraph "
        "Judge–Critic safety classification, human annotations, and research analytics."
    ),
    lifespan=lifespan,
)

# Configure Middleware
# Note: In FastAPI/Starlette, the last added middleware is the outermost wrapper.
app.add_middleware(SecurityHeadersMiddleware)
app.add_middleware(RequestTracingMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=False,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
    expose_headers=["X-Request-ID", "Content-Disposition"],
)

# Mount API routes
app.include_router(api_v1_router, prefix=settings.API_V1_STR)
app.include_router(health.router, include_in_schema=False)


@app.get("/", include_in_schema=False)
async def root():
    return {
        "message": f"Welcome to {settings.PROJECT_NAME} API. Visit /docs for OpenAPI documentation.",
        "version": settings.VERSION,
    }

