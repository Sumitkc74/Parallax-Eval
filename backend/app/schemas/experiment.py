from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict, Field
from app.schemas.common import ExperimentStatus, Language, PromptType
from app.schemas.response import ModelResponseWithDetailsRead


class ExperimentCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=200, json_schema_extra={"example": "GPT-4o-mini JailbreakBench Baseline"})
    target_model: str = Field(default="gpt-4o-mini", max_length=100, json_schema_extra={"example": "gpt-4o-mini"})
    judge_model: str = Field(default="gpt-4o-mini", max_length=100, json_schema_extra={"example": "gpt-4o-mini"})
    languages: Optional[List[Language]] = Field(default=[Language.EN, Language.NE], description="Languages to include in experiment")
    prompt_types: Optional[List[PromptType]] = Field(default=[PromptType.HARMFUL, PromptType.BENIGN], description="Harmful and/or benign")
    behavior_ids: Optional[List[str]] = Field(default=None, description="Optional filter of specific behavior IDs")
    temperature: float = Field(default=0.0, ge=0.0, le=2.0)
    max_tokens: int = Field(default=1024, ge=1, le=4096)

    # Milestone 1: Guardrail Interceptor Configuration
    guardrail_enabled: bool = Field(default=False, description="Whether to route inputs/outputs through safety guardrails")
    guardrail_type: Optional[str] = Field(default="regex_heuristic", description="Type of guardrail: 'regex_heuristic', 'regex_only', 'heuristic_only'")

    # Milestone 4: Evaluation Mode (Static vs Adaptive Red-Team Batch)
    evaluation_mode: Optional[str] = Field(default="STATIC", description="'STATIC' single-turn baseline or 'ADAPTIVE_RED_TEAM' multi-turn feedback loop")
    max_red_team_iterations: int = Field(default=3, ge=1, le=5, description="Maximum mutation rounds if evaluation_mode is ADAPTIVE_RED_TEAM")

    # Defense and Mitigation Strategies
    defense_strategy: Optional[str] = Field(
        default="NONE",
        description="Mitigation strategy: 'NONE', 'SYSTEM_PROMPT_INOCULATION', 'TRANSLATION_PIVOT', 'HYBRID'",
    )

    # Custom Model and Endpoint Configuration (e.g. Ollama, vLLM, OpenRouter, Private Endpoints)
    custom_base_url: Optional[str] = Field(
        default=None,
        description="Optional custom OpenAI-compatible endpoint URL (e.g. http://localhost:11434/v1 for Ollama)",
    )
    custom_api_key: Optional[str] = Field(
        default=None,
        description="Optional custom API key for the custom endpoint",
    )



class ExperimentRead(BaseModel):
    id: str
    name: str
    target_model: str
    judge_model: str
    status: str
    config: Dict[str, Any]
    total_prompts: int
    completed_prompts: int
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    error_message: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ExperimentWithResponsesRead(ExperimentRead):
    responses: List[ModelResponseWithDetailsRead] = []

    model_config = ConfigDict(from_attributes=True)

