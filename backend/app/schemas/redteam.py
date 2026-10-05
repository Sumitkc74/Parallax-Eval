from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict, Field


class RedTeamIterationStep(BaseModel):
    iteration: int
    prompt: str
    response: str
    safety_label: str
    judge_reasoning: str
    mutation_strategy: Optional[str] = None


class RedTeamAttemptRead(BaseModel):
    id: str
    response_id: str
    iteration: int
    prompt_text: str
    response_text: str
    mutation_strategy: str
    safety_label: str
    judge_reasoning: Optional[str] = None
    is_jailbroken: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class RedTeamRequest(BaseModel):
    seed_prompt: str = Field(..., description="Initial harmful seed prompt to adapt")
    behavior_category: str = Field(default="General", description="Category of behavior")
    language: str = Field(default="en", description="'en' or 'ne'")
    target_model: str = Field(default="gpt-4o-mini")
    judge_model: str = Field(default="gpt-4o-mini")
    max_iterations: int = Field(default=3, ge=1, le=5, description="Maximum adversarial retry iterations")


class RedTeamResult(BaseModel):
    session_id: str
    seed_prompt: str
    language: str
    target_model: str
    is_jailbroken: bool
    total_iterations: int
    final_safety_label: str
    steps: List[RedTeamIterationStep] = []
    summary: str


