import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.models import Experiment, ModelResponse, RedTeamAttempt
from app.services.experiment_runner import execute_experiment
from app.services.llm_gateway import MockLLMProvider


@pytest.mark.asyncio
async def test_batch_adaptive_red_team_execution(test_db):
    # Setup mock provider
    mock_provider = MockLLMProvider()

    # Create an experiment with evaluation_mode = ADAPTIVE_RED_TEAM
    exp = Experiment(
        name="Batch Adaptive Red-Team Test",
        target_model="mock-target",
        judge_model="mock-judge",
        status="PENDING",
        config={
            "languages": ["en"],
            "prompt_types": ["harmful"],
            "evaluation_mode": "ADAPTIVE_RED_TEAM",
            "max_red_team_iterations": 2,
        },
    )
    test_db.add(exp)
    await test_db.commit()
    await test_db.refresh(exp)

    class SessionFactoryWrapper:
        def __call__(self):
            return self
        async def __aenter__(self):
            return test_db
        async def __aexit__(self, exc_type, exc_val, exc_tb):
            pass

    # Execute experiment
    await execute_experiment(
        experiment_id=exp.id,
        provider=mock_provider,
        session_factory=SessionFactoryWrapper(),
    )

    await test_db.refresh(exp)
    assert exp.status == "COMPLETED"
    assert exp.completed_prompts > 0

    # Query responses and their relational red_team_attempts
    stmt = (
        select(ModelResponse)
        .where(ModelResponse.experiment_id == exp.id)
        .options(selectinload(ModelResponse.red_team_attempts))
    )
    responses = (await test_db.execute(stmt)).scalars().all()
    assert len(responses) > 0

    first_resp = responses[0]
    assert len(first_resp.red_team_attempts) > 0
    first_attempt = first_resp.red_team_attempts[0]
    assert isinstance(first_attempt, RedTeamAttempt)
    assert first_attempt.iteration >= 1
    assert first_attempt.prompt_text != ""
    assert first_attempt.mutation_strategy != ""


@pytest.mark.asyncio
async def test_batch_red_team_results_api(client: AsyncClient, test_db):
    mock_provider = MockLLMProvider()

    # Create and run batch red team experiment
    exp = Experiment(
        name="API Red-Team Results Test",
        target_model="mock-target",
        judge_model="mock-judge",
        status="PENDING",
        config={
            "languages": ["ne"],
            "prompt_types": ["harmful"],
            "evaluation_mode": "ADAPTIVE_RED_TEAM",
            "max_red_team_iterations": 2,
        },
    )
    test_db.add(exp)
    await test_db.commit()
    await test_db.refresh(exp)

    class SessionFactoryWrapper:
        def __call__(self):
            return self
        async def __aenter__(self):
            return test_db
        async def __aexit__(self, exc_type, exc_val, exc_tb):
            pass

    await execute_experiment(
        experiment_id=exp.id,
        provider=mock_provider,
        session_factory=SessionFactoryWrapper(),
    )

    # Call results endpoint
    response = await client.get(f"/api/v1/experiments/{exp.id}/results")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) > 0
    resp_item = data[0]
    assert "red_team_attempts" in resp_item
    assert len(resp_item["red_team_attempts"]) > 0
    attempt = resp_item["red_team_attempts"][0]
    assert "mutation_strategy" in attempt
    assert "safety_label" in attempt
