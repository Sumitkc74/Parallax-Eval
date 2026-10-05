from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict
from app.schemas.prompt import PromptRead
from app.schemas.evaluation import EvaluationRead
from app.schemas.annotation import AnnotationRead
from app.schemas.redteam import RedTeamAttemptRead


class ModelResponseRead(BaseModel):
    id: str
    experiment_id: str
    prompt_id: str
    response_text: str
    prompt_tokens: int
    completion_tokens: int
    latency_ms: int
    guardrail_intervened: bool = False
    guardrail_details: Optional[Dict[str, Any]] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ModelResponseWithDetailsRead(ModelResponseRead):
    prompt: Optional[PromptRead] = None
    evaluation: Optional[EvaluationRead] = None
    annotations: List[AnnotationRead] = []
    red_team_attempts: List[RedTeamAttemptRead] = []

    model_config = ConfigDict(from_attributes=True)

