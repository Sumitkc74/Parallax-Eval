import asyncio
import pytest
from httpx import AsyncClient
from app.services.experiment_runner import execute_experiment
from app.services.llm_gateway import MockLLMProvider


from conftest import TestSessionLocal


@pytest.mark.asyncio
async def test_create_and_run_experiment(client: AsyncClient, test_db):
    # 1. Create experiment
    payload = {
        "name": "Integration Test Run",
        "target_model": "mock-target",
        "judge_model": "mock-judge",
        "languages": ["en"],
        "prompt_types": ["benign"],
    }
    create_resp = await client.post("/api/v1/experiments", json=payload)
    assert create_resp.status_code == 201
    exp_data = create_resp.json()
    exp_id = exp_data["id"]
    assert exp_data["status"] in ["PENDING", "RUNNING"]

    # 2. In FastAPI test client, BackgroundTasks runs automatically
    # Experiment transitions to COMPLETED

    # 3. Verify experiment status transitions to COMPLETED
    get_resp = await client.get(f"/api/v1/experiments/{exp_id}")
    assert get_resp.status_code == 200
    updated_exp = get_resp.json()
    assert updated_exp["status"] == "COMPLETED"
    assert updated_exp["completed_prompts"] > 0
    assert updated_exp["completed_prompts"] == updated_exp["total_prompts"]

    # 4. Verify results endpoint
    results_resp = await client.get(f"/api/v1/experiments/{exp_id}/results")
    assert results_resp.status_code == 200
    results = results_resp.json()
    assert len(results) == updated_exp["completed_prompts"]
    first_result = results[0]
    assert first_result["evaluation"]["final_label"] is not None

    # 5. Verify CSV export endpoint
    csv_resp = await client.get(f"/api/v1/experiments/{exp_id}/export/csv")
    assert csv_resp.status_code == 200
    assert "text/csv" in csv_resp.headers["content-type"]
    assert "behavior_source_id" in csv_resp.text

    # 6. Verify Clone endpoint
    clone_resp = await client.post(f"/api/v1/experiments/{exp_id}/clone")
    assert clone_resp.status_code == 201
    clone_data = clone_resp.json()
    assert clone_data["name"] == f"Clone of {exp_data['name']}"
    assert clone_data["id"] != exp_id

    # 7. Verify Delete endpoint
    del_resp = await client.delete(f"/api/v1/experiments/{exp_id}")
    assert del_resp.status_code == 200
    assert del_resp.json()["status"] == "deleted"

    get_deleted = await client.get(f"/api/v1/experiments/{exp_id}")
    assert get_deleted.status_code == 404

