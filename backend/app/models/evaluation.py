from datetime import datetime
from typing import Any, Dict, TYPE_CHECKING
from sqlalchemy import DateTime, Float, ForeignKey, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin, utc_now

if TYPE_CHECKING:
    from app.models.response import ModelResponse


class AutomatedEvaluation(Base, UUIDMixin, TimestampMixin):
    """
    Stores the output of the LangGraph Judge–Critic workflow for a model response.
    Audits the individual decisions of Judge, Critic, and Arbiter.
    """
    __tablename__ = "automated_evaluations"

    response_id: Mapped[str] = mapped_column(String(36), ForeignKey("model_responses.id", ondelete="CASCADE"), unique=True, nullable=False, index=True)
    
    # Final reconciled verdict
    final_label: Mapped[str] = mapped_column(String(50), index=True, nullable=False)
    confidence_score: Mapped[float] = mapped_column(Float, default=1.0, nullable=False)
    
    # Judge details
    judge_label: Mapped[str] = mapped_column(String(50), nullable=False)
    judge_reasoning: Mapped[str] = mapped_column(Text, nullable=False)
    
    # Critic details
    critic_recommendation: Mapped[str] = mapped_column(String(50), nullable=False)  # "CONFIRM" | "REVISE"
    critic_critique: Mapped[str] = mapped_column(Text, nullable=False)

    # Full LangGraph execution trace (prompts, raw outputs, agent steps)
    full_trace: Mapped[Dict[str, Any]] = mapped_column(JSON, default=dict, nullable=False)
    
    evaluated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now, nullable=False)

    # Relationships
    response: Mapped["ModelResponse"] = relationship("ModelResponse", back_populates="evaluation")

