import json
from fastapi import APIRouter, Depends, Query
from fastapi.responses import PlainTextResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.errors import ResourceNotFoundException
from app.models import Experiment
from app.schemas.analytics import RQ1Metrics, RQ2Metrics, RemediationReport
from app.schemas.comparison import ExperimentComparisonResponse
from app.services.analytics_service import (
    compute_rq1_metrics,
    compute_rq2_metrics,
    compute_experiment_comparison,
    generate_remediation_report,
    generate_executive_audit_report,
)

router = APIRouter(prefix="/analytics", tags=["Research Analytics (RQ1 / RQ2)"])


@router.get("/compare", response_model=ExperimentComparisonResponse)
async def compare_experiments(
    baseline_id: str = Query(..., description="ID of baseline experiment"),
    candidate_id: str = Query(..., description="ID of candidate or updated experiment"),
    ucr_tolerance: float = Query(0.0, ge=0.0, le=1.0, description="Allowed delta threshold for Unsafe Compliance Rate"),
    db: AsyncSession = Depends(get_db),
):
    """
    Compares two experiments side-by-side to detect safety regressions across languages.
    Computes metric deltas, identifies individual prompt regressions/improvements,
    and returns an automated pass/fail CI/CD safety gate.
    """
    return await compute_experiment_comparison(
        db=db,
        baseline_id=baseline_id,
        candidate_id=candidate_id,
        ucr_tolerance=ucr_tolerance,
    )


@router.get("/rq1/{experiment_id}", response_model=RQ1Metrics)
async def get_rq1_analytics(experiment_id: str, db: AsyncSession = Depends(get_db)):
    """
    RQ1: Do selected LLMs demonstrate different safety behavior when semantically equivalent
    prompts are presented in English and Nepali?
    Returns HRR, UCR, BCR, ORR, Deltas, and pairwise behavior comparisons.
    """
    exp_stmt = select(Experiment).where(Experiment.id == experiment_id)
    exp = (await db.execute(exp_stmt)).scalar_one_or_none()
    if not exp:
        raise ResourceNotFoundException("Experiment", experiment_id)

    return await compute_rq1_metrics(db, experiment_id)


@router.get("/rq2/{experiment_id}", response_model=RQ2Metrics)
async def get_rq2_analytics(experiment_id: str, db: AsyncSession = Depends(get_db)):
    """
    RQ2: How reliably does a Safety Judge–Critic multi-agent workflow classify English and
    Nepali LLM responses compared with human evaluation?
    Returns Critic revision frequency, automated vs. human agreement, and Cohen's Kappa.
    """
    exp_stmt = select(Experiment).where(Experiment.id == experiment_id)
    exp = (await db.execute(exp_stmt)).scalar_one_or_none()
    if not exp:
        raise ResourceNotFoundException("Experiment", experiment_id)

    return await compute_rq2_metrics(db, experiment_id)


@router.get("/remediation/{experiment_id}", response_model=RemediationReport)
async def get_remediation_analytics(experiment_id: str, db: AsyncSession = Depends(get_db)):
    """
    Synthesizes an automated vulnerability remediation report and DPO training dataset
    by analyzing cross-lingual safety failures (e.g. Safe Refusal in English vs Unsafe Compliance in Nepali).
    """
    exp_stmt = select(Experiment).where(Experiment.id == experiment_id)
    exp = (await db.execute(exp_stmt)).scalar_one_or_none()
    if not exp:
        raise ResourceNotFoundException("Experiment", experiment_id)

    return await generate_remediation_report(db, experiment_id)


@router.get("/remediation/{experiment_id}/dpo-export")
async def export_dpo_dataset(experiment_id: str, db: AsyncSession = Depends(get_db)):
    """
    Exports the generated DPO dataset as JSONL for direct fine-tuning alignment.
    """
    exp_stmt = select(Experiment).where(Experiment.id == experiment_id)
    exp = (await db.execute(exp_stmt)).scalar_one_or_none()
    if not exp:
        raise ResourceNotFoundException("Experiment", experiment_id)

    report = await generate_remediation_report(db, experiment_id)
    lines = [json.dumps(pair.model_dump(), ensure_ascii=False) for pair in report.dpo_dataset]
    content = "\n".join(lines)
    return PlainTextResponse(content=content, media_type="application/x-jsonlines")


@router.get("/report/{experiment_id}/markdown")
async def get_executive_report_markdown(experiment_id: str, db: AsyncSession = Depends(get_db)):
    """
    Generates a full, publication-ready academic and executive Safety Audit Report in Markdown.
    Includes statistical significance, bootstrap CIs, tokenization tax, category disparity,
    and alignment action items.
    """
    exp_stmt = select(Experiment).where(Experiment.id == experiment_id)
    exp = (await db.execute(exp_stmt)).scalar_one_or_none()
    if not exp:
        raise ResourceNotFoundException("Experiment", experiment_id)

    report_md = await generate_executive_audit_report(db, experiment_id)
    return PlainTextResponse(content=report_md, media_type="text/markdown")




