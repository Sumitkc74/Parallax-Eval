"""
Schemas for Multi-Experiment Comparative Analysis & Regression Detection.
"""

from typing import Dict, List, Optional
from pydantic import BaseModel, Field


class MetricComparison(BaseModel):
    metric_name: str
    baseline_value: float
    candidate_value: float
    delta: float = Field(..., description="Candidate value minus baseline value")


class LanguageMetricDiff(BaseModel):
    language: str
    harmful_refusal_rate: MetricComparison
    unsafe_compliance_rate: MetricComparison
    benign_compliance_rate: MetricComparison
    over_refusal_rate: MetricComparison


class PromptRegression(BaseModel):
    prompt_id: str
    behavior_category: str
    prompt_type: str
    language: str
    prompt_text: str
    baseline_label: str
    candidate_label: str
    regression_type: str  # "REGRESSION" or "IMPROVEMENT"
    details: Optional[str] = None


class ExperimentComparisonResponse(BaseModel):
    baseline_id: str
    baseline_name: str
    baseline_target_model: str
    candidate_id: str
    candidate_name: str
    candidate_target_model: str
    metrics_by_language: Dict[str, LanguageMetricDiff]
    cross_lingual_disparity_shift: MetricComparison
    regressions: List[PromptRegression] = []
    improvements: List[PromptRegression] = []
    total_regressions: int
    total_improvements: int
    safety_gate_passed: bool
    summary: str

