from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict, Field
from app.schemas.common import PromptType
from app.schemas.prompt import PromptRead


class BehaviorBase(BaseModel):
    source_id: str
    category: str
    prompt_type: PromptType
    english_description: str


class BehaviorCreate(BehaviorBase):
    pass


class CustomBehaviorCreate(BaseModel):
    category: str = Field(..., min_length=1, max_length=100, description="Threat or safety category (e.g. Cybersecurity, Hate Speech, General)")
    prompt_type: PromptType = Field(default=PromptType.HARMFUL, description="harmful or benign benchmark intent")
    english_prompt: str = Field(..., min_length=1, max_length=15000, description="English prompt text")
    nepali_prompt: str = Field(..., min_length=1, max_length=15000, description="Semantically equivalent Nepali prompt text")
    english_description: Optional[str] = Field(default=None, max_length=1000, description="Description of the evaluated behavior")
    source_id: Optional[str] = Field(default=None, max_length=50, description="Optional custom source identifier")


class BehaviorRead(BehaviorBase):
    id: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class BehaviorWithPromptsRead(BehaviorRead):
    prompts: List[PromptRead] = []

    model_config = ConfigDict(from_attributes=True)


class PromptTranslationRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=15000, description="English prompt text to translate")
    source_language: str = Field(default="en", max_length=10, description="Source language code (e.g. 'en')")
    target_language: str = Field(default="ne", max_length=10, description="Target language code (e.g. 'ne')")


class PromptTranslationResponse(BaseModel):
    translated_text: str = Field(..., description="Translated prompt text in target language script")
    source_language: str
    target_language: str


class CustomBehaviorUpdate(BaseModel):
    category: Optional[str] = Field(None, min_length=1, max_length=100, description="Updated threat category")
    prompt_type: Optional[PromptType] = Field(None, description="Updated prompt intent")
    english_prompt: Optional[str] = Field(None, min_length=1, max_length=15000, description="Updated English prompt")
    nepali_prompt: Optional[str] = Field(None, min_length=1, max_length=15000, description="Updated Nepali prompt")
    english_description: Optional[str] = Field(None, max_length=1000, description="Updated behavior description")

