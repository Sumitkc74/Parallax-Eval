from datetime import datetime, timezone
from typing import List, Optional
from fastapi import APIRouter, BackgroundTasks, Depends, Header, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.core.errors import ResourceNotFoundException
from app.models import Experiment, ModelResponse, Prompt
from app.schemas.experiment import ExperimentCreate, ExperimentRead, ExperimentWithResponsesRead
from app.schemas.response import ModelResponseWithDetailsRead
from app.services.experiment_runner import execute_experiment
from app.services.worker_supervisor import supervisor

router = APIRouter(prefix="/experiments", tags=["Experiments"])


@router.post("", response_model=ExperimentRead, status_code=status.HTTP_201_CREATED)
async def create_experiment(
    payload: ExperimentCreate,
    background_tasks: BackgroundTasks,
    x_idempotency_key: Optional[str] = Header(None, alias="X-Idempotency-Key"),
    db: AsyncSession = Depends(get_db),
):
    """Creates a new safety evaluation experiment and begins execution in the background."""
    # Idempotency check: prevent duplicate background tasks on double submission
    if x_idempotency_key:
        stmt = (
            select(Experiment)
            .where(
                Experiment.name == payload.name,
                Experiment.target_model == payload.target_model,
                Experiment.status.in_(["PENDING", "RUNNING"]),
            )
            .order_by(Experiment.created_at.desc())
        )
        existing = (await db.execute(stmt)).scalars().first()
        if existing and existing.config and existing.config.get("idempotency_key") == x_idempotency_key:
            return existing

    config_dict = {
        "idempotency_key": x_idempotency_key,
        "temperature": payload.temperature,
        "max_tokens": payload.max_tokens,
        "languages": [l.value for l in payload.languages] if payload.languages else ["en", "ne"],
        "prompt_types": [p.value for p in payload.prompt_types] if payload.prompt_types else ["harmful", "benign"],
        "behavior_ids": payload.behavior_ids,
        "guardrail_enabled": payload.guardrail_enabled,
        "guardrail_type": payload.guardrail_type,
        "evaluation_mode": payload.evaluation_mode,
        "max_red_team_iterations": payload.max_red_team_iterations,
        "defense_strategy": payload.defense_strategy or "NONE",
        "custom_base_url": payload.custom_base_url,
        "custom_api_key": payload.custom_api_key,
    }

    experiment = Experiment(
        name=payload.name,
        target_model=payload.target_model,
        judge_model=payload.judge_model,
        status="PENDING",
        config=config_dict,
        total_prompts=0,
        completed_prompts=0,
    )
    db.add(experiment)
    await db.commit()
    await db.refresh(experiment)

    # Launch background execution task via FastAPI BackgroundTasks
    background_tasks.add_task(execute_experiment, experiment.id)

    return experiment


@router.get("", response_model=List[ExperimentRead])
async def list_experiments(
    status_filter: Optional[str] = Query(None, alias="status"),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(Experiment).order_by(Experiment.created_at.desc())
    if status_filter:
        stmt = stmt.where(Experiment.status == status_filter.upper())
    result = await db.execute(stmt)
    return result.scalars().all()


@router.get("/{experiment_id}", response_model=ExperimentRead)
async def get_experiment(experiment_id: str, db: AsyncSession = Depends(get_db)):
    stmt = select(Experiment).where(Experiment.id == experiment_id)
    result = await db.execute(stmt)
    exp = result.scalar_one_or_none()
    if not exp:
        raise ResourceNotFoundException("Experiment", experiment_id)
    return exp


@router.delete("/{experiment_id}", status_code=200)
async def delete_experiment(experiment_id: str, db: AsyncSession = Depends(get_db)):
    """Deletes an experiment and all associated model responses and evaluations."""
    stmt = select(Experiment).where(Experiment.id == experiment_id)
    result = await db.execute(stmt)
    exp = result.scalar_one_or_none()
    if not exp:
        raise ResourceNotFoundException("Experiment", experiment_id)

    await db.delete(exp)
    await db.commit()
    return {"status": "deleted", "id": experiment_id}


@router.post("/{experiment_id}/clone", response_model=ExperimentRead, status_code=201)
async def clone_experiment(
    experiment_id: str,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
):
    """Clones an experiment's configuration and launches a fresh background evaluation run."""
    stmt = select(Experiment).where(Experiment.id == experiment_id)
    result = await db.execute(stmt)
    source_exp = result.scalar_one_or_none()
    if not source_exp:
        raise ResourceNotFoundException("Experiment", experiment_id)

    new_experiment = Experiment(
        name=f"Clone of {source_exp.name}",
        target_model=source_exp.target_model,
        judge_model=source_exp.judge_model,
        status="PENDING",
        config=source_exp.config or {},
        total_prompts=0,
        completed_prompts=0,
    )
    db.add(new_experiment)
    await db.commit()
    await db.refresh(new_experiment)

    background_tasks.add_task(execute_experiment, new_experiment.id)
    return new_experiment


@router.get("/{experiment_id}/results", response_model=List[ModelResponseWithDetailsRead])
async def get_experiment_results(experiment_id: str, db: AsyncSession = Depends(get_db)):
    """Retrieves all model responses, prompts, and evaluations for an experiment."""
    stmt = (
        select(ModelResponse)
        .where(ModelResponse.experiment_id == experiment_id)
        .options(
            selectinload(ModelResponse.prompt).selectinload(Prompt.behavior),
            selectinload(ModelResponse.evaluation),
            selectinload(ModelResponse.annotations),
            selectinload(ModelResponse.red_team_attempts),
        )
        .order_by(ModelResponse.created_at.asc())
    )
    result = await db.execute(stmt)
    return result.scalars().all()


@router.get("/{experiment_id}/export/csv")
async def export_experiment_csv(experiment_id: str, db: AsyncSession = Depends(get_db)):
    """Exports all prompt responses, evaluations, and annotations as a downloadable CSV."""
    import csv
    import io
    from fastapi.responses import StreamingResponse

    stmt = select(Experiment).where(Experiment.id == experiment_id)
    exp = (await db.execute(stmt)).scalar_one_or_none()
    if not exp:
        raise ResourceNotFoundException("Experiment", experiment_id)

    results_stmt = (
        select(ModelResponse)
        .where(ModelResponse.experiment_id == experiment_id)
        .options(
            selectinload(ModelResponse.prompt).selectinload(Prompt.behavior),
            selectinload(ModelResponse.evaluation),
            selectinload(ModelResponse.annotations),
        )
        .order_by(ModelResponse.created_at.asc())
    )
    responses = (await db.execute(results_stmt)).scalars().all()

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow([
        "experiment_id",
        "experiment_name",
        "target_model",
        "behavior_source_id",
        "category",
        "prompt_type",
        "language",
        "prompt_text",
        "response_text",
        "latency_ms",
        "final_label",
        "confidence_score",
        "judge_label",
        "critic_recommendation",
        "human_label",
    ])

    for r in responses:
        b_source = r.prompt.behavior.source_id if r.prompt and r.prompt.behavior else ""
        category = r.prompt.behavior.category if r.prompt and r.prompt.behavior else ""
        p_type = r.prompt.behavior.prompt_type if r.prompt and r.prompt.behavior else ""
        lang = r.prompt.language if r.prompt else ""
        p_text = r.prompt.prompt_text if r.prompt else ""
        f_label = r.evaluation.final_label if r.evaluation else ""
        c_score = r.evaluation.confidence_score if r.evaluation else ""
        j_label = r.evaluation.judge_label if r.evaluation else ""
        c_rec = r.evaluation.critic_recommendation if r.evaluation else ""
        h_label = r.annotations[0].human_label if r.annotations else ""

        def _sanitize_csv_cell(val):
            if isinstance(val, str) and val.startswith(("=", "+", "-", "@", "\t", "\r")):
                return f"'{val}"
            return val

        writer.writerow([
            _sanitize_csv_cell(x) for x in [
                exp.id,
                exp.name,
                exp.target_model,
                b_source,
                category,
                p_type,
                lang,
                p_text,
                r.response_text,
                r.latency_ms,
                f_label,
                c_score,
                j_label,
                c_rec,
                h_label,
            ]
        ])

    output.seek(0)
    filename = f"experiment_{experiment_id[:8]}_results.csv"
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )


@router.post("/{experiment_id}/cancel", response_model=ExperimentRead)
async def cancel_experiment(experiment_id: str, db: AsyncSession = Depends(get_db)):
    """
    Cancels an in-flight background evaluation experiment gracefully.
    Signals worker supervisor cancellation token and transitions experiment to CANCELLED.
    """
    stmt = select(Experiment).where(Experiment.id == experiment_id)
    result = await db.execute(stmt)
    exp = result.scalar_one_or_none()
    if not exp:
        raise ResourceNotFoundException("Experiment", experiment_id)

    if exp.status in ["COMPLETED", "FAILED", "CANCELLED"]:
        return exp

    # Signal active background task to abort gracefully
    await supervisor.request_cancellation(experiment_id)

    exp.status = "CANCELLED"
    exp.completed_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(exp)
    return exp
