import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_list_behaviors(client: AsyncClient):
    response = await client.get("/api/v1/behaviors")
    assert response.status_code == 200
    behaviors = response.json()
    assert len(behaviors) > 0
    first = behaviors[0]
    assert "source_id" in first
    assert "category" in first
    assert "prompts" in first
    assert len(first["prompts"]) == 2  # EN and NE pair


@pytest.mark.asyncio
async def test_filter_behaviors_by_type(client: AsyncClient):
    response = await client.get("/api/v1/behaviors?prompt_type=benign")
    assert response.status_code == 200
    behaviors = response.json()
    assert all(b["prompt_type"] == "benign" for b in behaviors)

