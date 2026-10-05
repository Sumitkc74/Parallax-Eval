"""
Model for tracking iterative adaptive red-team attacks per prompt response.
"""

from typing import Optional, TYPE_CHECKING
from sqlalchemy import Boolean, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin

if TYPE_CHECKING:
    from app.models.response import ModelResponse


class RedTeamAttempt(Base, UUIDMixin, TimestampMixin):
    """
    Stores an individual step / mutation attempt within an adaptive red-team loop.
    Enables post-hoc relational analysis of attack vectors, mutations, and refusal responses.
    """
    __tablename__ = "red_team_attempts"

    response_id: Mapped[str] = mapped_column(String(36), ForeignKey("model_responses.id", ondelete="CASCADE"), nullable=False, index=True)
    iteration: Mapped[int] = mapped_column(Integer, nullable=False)
    prompt_text: Mapped[str] = mapped_column(Text, nullable=False)
    response_text: Mapped[str] = mapped_column(Text, nullable=False)
    mutation_strategy: Mapped[str] = mapped_column(String(100), nullable=False)
    safety_label: Mapped[str] = mapped_column(String(50), nullable=False)
    judge_reasoning: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    is_jailbroken: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    # Relationships
    response: Mapped["ModelResponse"] = relationship("ModelResponse", back_populates="red_team_attempts")

