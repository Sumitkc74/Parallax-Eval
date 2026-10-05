import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker

from app.core.config import settings
from app.core.database import Base, get_db
from app.main import app
from app.seed.seed_db import seed_benchmark_dataset

# Enforce mock LLM for all automated test runs
settings.USE_MOCK_LLM = True

# Use an isolated in-memory SQLite database for test execution
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

test_engine = create_async_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
)

TestSessionLocal = async_sessionmaker(
    bind=test_engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


from app.core import database as app_db
from app.services import experiment_runner as app_runner

app_db.async_session_maker = TestSessionLocal
app_runner.async_session_maker = TestSessionLocal


@pytest_asyncio.fixture(scope="function")
async def test_db():
    """Sets up a clean test database with schema and seeds before each test."""
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with TestSessionLocal() as session:
        await seed_benchmark_dataset(session=session)
        yield session

    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture(scope="function")
async def client(test_db: AsyncSession):
    """Provides an AsyncClient bound to the FastAPI app with test db override."""
    async def override_get_db():
        yield test_db

    app.dependency_overrides[get_db] = override_get_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()
