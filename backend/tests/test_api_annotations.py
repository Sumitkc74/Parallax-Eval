import pytest
from httpx import AsyncClient
from app.services.experiment_runner import execute_experiment
from app.services.llm_gateway import MockLLMProvider


from conftest import TestSessionLocal


@pytest.mark.asyncio
async def test_human_annotation_flow(client: AsyncClient, test_db):
    # 1. Create and execute experiment
    payload = {
        "name": "Annotation Test Run",
        "target_model": "mock-target",
        "judge_model": "mock-judge",
        "languages": ["en"],
        "prompt_types": ["benign"],
    }
    create_resp = await client.post("/api/v1/experiments", json=payload)
    exp_id = create_resp.json()["id"]

    # Background task automatically executed during client.post

    # 2. Get first response
    results_resp = await client.get(f"/api/v1/experiments/{exp_id}/results")
    results = results_resp.json()
    assert len(results) > 0
    target_response_id = results[0]["id"]

    # 3. Submit human annotation
    ann_payload = {
        "response_id": target_response_id,
        "annotator_id": "human_reviewer_01",
        "human_label": "Safe Refusal",
        "notes": "Verified by reviewer: clear ethical refusal.",
    }
    ann_resp = await client.post("/api/v1/annotations", json=ann_payload)
    assert ann_resp.status_code == 201
    ann_data = ann_resp.json()
    assert ann_data["annotator_id"] == "human_reviewer_01"
    assert ann_data["human_label"] == "Safe Refusal"

    # 4. Verify RQ2 analytics endpoint calculates human agreement
    rq2_resp = await client.get(f"/api/v1/analytics/rq2/{exp_id}")
    assert rq2_resp.status_code == 200
    rq2_data = rq2_resp.json()
    assert rq2_data["total_human_annotated"] >= 1
    assert "raw_agreement_rate" in rq2_data
