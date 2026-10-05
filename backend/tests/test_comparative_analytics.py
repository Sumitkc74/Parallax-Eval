import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.models import Experiment, ModelResponse, AutomatedEvaluation, Prompt
from app.services.analytics_service import compute_experiment_comparison


@pytest.mark.asyncio
async def test_compute_experiment_comparison_identical(test_db):
    # Retrieve existing seeded prompts with behavior eagerly loaded
    prompts = (await test_db.execute(select(Prompt).options(selectinload(Prompt.behavior)))).scalars().all()
    assert len(prompts) > 0

    # Create baseline experiment
    exp_base = Experiment(
        name="Baseline Exp",
        target_model="model-v1",
        judge_model="judge-v1",
        status="COMPLETED",
        total_prompts=len(prompts),
        completed_prompts=len(prompts),
        config={},
    )
    # Create candidate experiment (identical)
    exp_cand = Experiment(
        name="Candidate Exp",
        target_model="model-v2",
        judge_model="judge-v1",
        status="COMPLETED",
        total_prompts=len(prompts),
        completed_prompts=len(prompts),
        config={},
    )
    test_db.add_all([exp_base, exp_cand])
    await test_db.commit()
    await test_db.refresh(exp_base)
    await test_db.refresh(exp_cand)

    # Seed mock responses and evaluations for both
    for p in prompts[:4]:
        label = "Safe Refusal" if p.behavior.prompt_type == "harmful" else "Appropriate Compliance"
        
        # Baseline response & eval
        resp_b = ModelResponse(experiment_id=exp_base.id, prompt_id=p.id, response_text="I refuse.")
        test_db.add(resp_b)
        await test_db.flush()
        eval_b = AutomatedEvaluation(
            response_id=resp_b.id,
            final_label=label,
            confidence_score=1.0,
            judge_label=label,
            judge_reasoning="Reasoning",
            critic_recommendation="CONFIRM",
            critic_critique="Critique",
        )
        test_db.add(eval_b)

        # Candidate response & eval
        resp_c = ModelResponse(experiment_id=exp_cand.id, prompt_id=p.id, response_text="I refuse.")
        test_db.add(resp_c)
        await test_db.flush()
        eval_c = AutomatedEvaluation(
            response_id=resp_c.id,
            final_label=label,
            confidence_score=1.0,
            judge_label=label,
            judge_reasoning="Reasoning",
            critic_recommendation="CONFIRM",
            critic_critique="Critique",
        )
        test_db.add(eval_c)

    await test_db.commit()

    comparison = await compute_experiment_comparison(test_db, exp_base.id, exp_cand.id)
    assert comparison.baseline_id == exp_base.id
    assert comparison.candidate_id == exp_cand.id
    assert comparison.total_regressions == 0
    assert comparison.total_improvements == 0
    assert comparison.safety_gate_passed is True
    assert comparison.metrics_by_language["en"].unsafe_compliance_rate.delta == 0.0


@pytest.mark.asyncio
async def test_compute_experiment_comparison_regression_detected(test_db):
    prompts = (await test_db.execute(select(Prompt).options(selectinload(Prompt.behavior)))).scalars().all()
    harmful_prompt = next(p for p in prompts if p.behavior.prompt_type == "harmful" and p.language == "en")

    exp_base = Experiment(
        name="Baseline Safe",
        target_model="model-v1",
        judge_model="judge-v1",
        status="COMPLETED",
        total_prompts=1,
        completed_prompts=1,
        config={},
    )
    exp_cand = Experiment(
        name="Candidate Regressed",
        target_model="model-v2",
        judge_model="judge-v1",
        status="COMPLETED",
        total_prompts=1,
        completed_prompts=1,
        config={},
    )
    test_db.add_all([exp_base, exp_cand])
    await test_db.commit()
    await test_db.refresh(exp_base)
    await test_db.refresh(exp_cand)

    # Baseline was Safe Refusal
    resp_b = ModelResponse(experiment_id=exp_base.id, prompt_id=harmful_prompt.id, response_text="I cannot do that.")
    test_db.add(resp_b)
    await test_db.flush()
    eval_b = AutomatedEvaluation(
        response_id=resp_b.id,
        final_label="Safe Refusal",
        confidence_score=1.0,
        judge_label="Safe Refusal",
        judge_reasoning="Harmful request",
        critic_recommendation="CONFIRM",
        critic_critique="Critique",
    )
    test_db.add(eval_b)

    # Candidate regressed to Unsafe Compliance
    resp_c = ModelResponse(experiment_id=exp_cand.id, prompt_id=harmful_prompt.id, response_text="Sure, here is the harmful output.")
    test_db.add(resp_c)
    await test_db.flush()
    eval_c = AutomatedEvaluation(
        response_id=resp_c.id,
        final_label="Unsafe Compliance",
        confidence_score=1.0,
        judge_label="Unsafe Compliance",
        judge_reasoning="Model complied",
        critic_recommendation="CONFIRM",
        critic_critique="Critique",
    )
    test_db.add(eval_c)

    await test_db.commit()

    comparison = await compute_experiment_comparison(test_db, exp_base.id, exp_cand.id)
    assert comparison.total_regressions == 1
    assert comparison.safety_gate_passed is False
    reg = comparison.regressions[0]
    assert reg.prompt_id == harmful_prompt.id
    assert reg.baseline_label == "Safe Refusal"
    assert reg.candidate_label == "Unsafe Compliance"
    assert reg.regression_type == "REGRESSION"


@pytest.mark.asyncio
async def test_api_compare_endpoint(client: AsyncClient, test_db):
    exp1 = Experiment(
        name="Exp 1",
        target_model="m1",
        judge_model="j1",
        status="COMPLETED",
        config={},
    )
    exp2 = Experiment(
        name="Exp 2",
        target_model="m2",
        judge_model="j1",
        status="COMPLETED",
        config={},
    )
    test_db.add_all([exp1, exp2])
    await test_db.commit()
    await test_db.refresh(exp1)
    await test_db.refresh(exp2)

    response = await client.get(f"/api/v1/analytics/compare?baseline_id={exp1.id}&candidate_id={exp2.id}")
    assert response.status_code == 200
    data = response.json()
    assert data["baseline_id"] == exp1.id
    assert data["candidate_id"] == exp2.id
    assert "metrics_by_language" in data
    assert "safety_gate_passed" in data
