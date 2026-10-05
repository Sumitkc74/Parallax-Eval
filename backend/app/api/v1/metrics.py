"""
System Observability & Operational Metrics Endpoint.
Exports platform health, evaluation throughput, token consumption,
and guardrail interception metrics across languages.
"""

from typing import Any, Dict
from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.models import Experiment, ModelResponse, RedTeamAttempt, Prompt
from app.services.worker_supervisor import supervisor

router = APIRouter(prefix="/metrics", tags=["System Observability & Metrics"])


@router.get("", response_model=Dict[str, Any])
async def get_system_metrics(db: AsyncSession = Depends(get_db)):
    """
    Returns platform-wide operational telemetry:
    - Experiment lifecycle state distributions
    - Throughput & total responses evaluated
    - Guardrail intervention counts by language
    - Token consumption and red-team mutation attempts
    """
    # 1. Experiment distribution by status
    exp_status_stmt = select(Experiment.status, func.count(Experiment.id)).group_by(Experiment.status)
    exp_status_res = await db.execute(exp_status_stmt)
    status_counts = dict(exp_status_res.all())

    # 2. Total responses and token metrics
    resp_agg_stmt = select(
        func.count(ModelResponse.id),
        func.coalesce(func.sum(ModelResponse.prompt_tokens), 0),
        func.coalesce(func.sum(ModelResponse.completion_tokens), 0),
        func.coalesce(func.avg(ModelResponse.latency_ms), 0.0),
    )
    resp_agg = (await db.execute(resp_agg_stmt)).one()
    total_responses, total_prompt_tokens, total_completion_tokens, avg_latency = resp_agg

    # 3. Guardrail interventions
    guard_total_stmt = select(func.count(ModelResponse.id)).where(ModelResponse.guardrail_intervened == True)
    total_guardrail_interventions = (await db.execute(guard_total_stmt)).scalar() or 0

    # Guardrail interventions by language
    guard_lang_stmt = (
        select(Prompt.language, func.count(ModelResponse.id))
        .join(Prompt, ModelResponse.prompt_id == Prompt.id)
        .where(ModelResponse.guardrail_intervened == True)
        .group_by(Prompt.language)
    )
    guard_lang_res = await db.execute(guard_lang_stmt)
    guardrail_by_lang = dict(guard_lang_res.all())

    # 4. Red-team attempts count
    rt_stmt = select(func.count(RedTeamAttempt.id))
    total_rt_attempts = (await db.execute(rt_stmt)).scalar() or 0

    # 5. In-flight tasks in worker supervisor
    active_in_flight = len(supervisor._cancellation_events)

    return {
        "status": "healthy",
        "experiments": {
            "total": sum(status_counts.values()),
            "by_status": status_counts,
            "in_flight_supervisor_tasks": active_in_flight,
        },
        "evaluations": {
            "total_responses": total_responses,
            "average_latency_ms": round(float(avg_latency), 2),
            "total_tokens_consumed": int(total_prompt_tokens + total_completion_tokens),
            "total_prompt_tokens": int(total_prompt_tokens),
            "total_completion_tokens": int(total_completion_tokens),
        },
        "guardrails": {
            "total_interventions": total_guardrail_interventions,
            "interventions_by_language": guardrail_by_lang,
        },
        "adaptive_red_team": {
            "total_mutation_attempts": total_rt_attempts,
        },
    }

