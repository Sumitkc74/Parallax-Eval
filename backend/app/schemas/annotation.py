from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field


class AnnotationBase(BaseModel):
    human_label: str = Field(..., min_length=1, max_length=50)
    annotator_id: str = Field(..., min_length=1, max_length=100)
    notes: Optional[str] = Field(default=None, max_length=2000)


class AnnotationCreate(AnnotationBase):
    response_id: str


class AnnotationRead(AnnotationBase):
    id: str
    response_id: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

