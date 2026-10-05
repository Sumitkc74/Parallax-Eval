from datetime import datetime
from typing import Any, Dict, Optional
from pydantic import BaseModel, ConfigDict
from app.schemas.common import CriticRecommendation


class JudgeOutput(BaseModel):
    judge_label: str
    judge_reasoning: str
    confidence: float = 1.0


class CriticOutput(BaseModel):
    critic_recommendation: CriticRecommendation
    critic_critique: str
    suggested_label: Optional[str] = None


class ArbiterOutput(BaseModel):
    final_label: str
    confidence_score: float
    reconciliation_notes: str


class EvaluationRead(BaseModel):
    id: str
    response_id: str
    final_label: str
    confidence_score: float
    judge_label: str
    judge_reasoning: str
    critic_recommendation: str
    critic_critique: str
    full_trace: Dict[str, Any]
    evaluated_at: datetime

    model_config = ConfigDict(from_attributes=True)

