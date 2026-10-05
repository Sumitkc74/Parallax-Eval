import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_health_check(client: AsyncClient):
    response = await client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["project"] == "Parallax-Eval"
    assert "version" in data


@pytest.mark.asyncio
async def test_readiness_probe(client: AsyncClient):
    # Test readiness at /ready and /api/v1/ready
    resp_v1 = await client.get("/api/v1/ready")
    assert resp_v1.status_code == 200
    data_v1 = resp_v1.json()
    assert data_v1["status"] == "ready"
    assert data_v1["database"] == "connected"

    resp_root = await client.get("/ready")
    assert resp_root.status_code == 200
    assert resp_root.json()["status"] == "ready"


@pytest.mark.asyncio
async def test_request_id_middleware(client: AsyncClient):
    # Auto-generated X-Request-ID
    resp = await client.get("/health")
    assert resp.status_code == 200
    assert "x-request-id" in resp.headers
    generated_id = resp.headers["x-request-id"]
    assert len(generated_id) > 0

    # Custom incoming X-Request-ID is preserved
    custom_id = "test-custom-trace-uuid-999"
    resp2 = await client.get("/health", headers={"X-Request-ID": custom_id})
    assert resp2.status_code == 200
    assert resp2.headers["x-request-id"] == custom_id


@pytest.mark.asyncio
async def test_metrics_endpoint(client: AsyncClient):
    response = await client.get("/api/v1/metrics")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "experiments" in data
    assert "evaluations" in data


