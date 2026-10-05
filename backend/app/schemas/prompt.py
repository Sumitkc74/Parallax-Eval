from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict
from app.schemas.common import Language


class PromptBase(BaseModel):
    language: Language
    prompt_text: str
    pair_id: Optional[str] = None
    translation_notes: Optional[str] = None
    is_validated: bool = True


class PromptCreate(PromptBase):
    behavior_id: str


class PromptRead(PromptBase):
    id: str
    behavior_id: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

