import pytest
from httpx import AsyncClient

from app.models import Experiment
from app.services.worker_supervisor import supervisor


@pytest.mark.asyncio
async def test_supervisor_zombie_recovery(test_db):
    # Insert an artificial 'RUNNING' zombie experiment
    zombie = Experiment(
        name="Zombie Orphan Test",
        target_model="mock-target",
        judge_model="mock-judge",
        status="RUNNING",
        total_prompts=10,
        completed_prompts=3,
        config={},
    )
    test_db.add(zombie)
    await test_db.commit()
    await test_db.refresh(zombie)

    class SessionFactoryWrapper:
        def __call__(self):
            return self
        async def __aenter__(self):
            return test_db
        async def __aexit__(self, exc_type, exc_val, exc_tb):
            pass

    recovered = await supervisor.recover_zombie_experiments(SessionFactoryWrapper())
    assert recovered == 1

    await test_db.refresh(zombie)
    assert zombie.status == "FAILED"
    assert "recovered by startup supervisor" in zombie.error_message
    assert zombie.completed_at is not None


@pytest.mark.asyncio
async def test_supervisor_registration_and_cancellation():
    exp_id = "test-exp-1234"
    event = await supervisor.register_experiment(exp_id)
    assert not supervisor.is_cancelled(exp_id)
    assert not event.is_set()

    # Request cancellation
    res = await supervisor.request_cancellation(exp_id)
    assert res is True
    assert supervisor.is_cancelled(exp_id)
    assert event.is_set()

    # Clean up
    await supervisor.unregister_experiment(exp_id)
    assert not supervisor.is_cancelled(exp_id)


@pytest.mark.asyncio
async def test_api_cancel_experiment(client: AsyncClient, test_db):
    # Create an experiment in PENDING state
    exp = Experiment(
        name="Cancellation API Test",
        target_model="mock-target",
        judge_model="mock-judge",
        status="PENDING",
        total_prompts=5,
        completed_prompts=0,
        config={},
    )
    test_db.add(exp)
    await test_db.commit()
    await test_db.refresh(exp)

    # Call cancel endpoint
    response = await client.post(f"/api/v1/experiments/{exp.id}/cancel")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "CANCELLED"
    assert data["completed_at"] is not None

