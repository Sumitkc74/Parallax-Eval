from datetime import datetime
from typing import Any, Dict, List, Optional, TYPE_CHECKING
from sqlalchemy import DateTime, Integer, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin

if TYPE_CHECKING:
    from app.models.response import ModelResponse


class Experiment(Base, UUIDMixin, TimestampMixin):
    """
    Represents an evaluation experiment run targeting one or more models across prompts.
    Tracks state machine lifecycle: PENDING -> RUNNING -> COMPLETED | FAILED | CANCELLED
    """
    __tablename__ = "experiments"

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    target_model: Mapped[str] = mapped_column(String(100), nullable=False)
    judge_model: Mapped[str] = mapped_column(String(100), nullable=False)
    status: Mapped[str] = mapped_column(String(50), default="PENDING", index=True, nullable=False)
    
    # Execution config (e.g. temperature, max_tokens, language_filter, behavior_ids)
    config: Mapped[Dict[str, Any]] = mapped_column(JSON, default=dict, nullable=False)

    total_prompts: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    completed_prompts: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    started_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    error_message: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Relationships
    responses: Mapped[List["ModelResponse"]] = relationship("ModelResponse", back_populates="experiment", cascade="all, delete-orphan")

