from typing import List, Optional, TYPE_CHECKING
from sqlalchemy import Boolean, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin

if TYPE_CHECKING:
    from app.models.behavior import Behavior
    from app.models.response import ModelResponse


class Prompt(Base, UUIDMixin, TimestampMixin):
    """
    Represents an instantiated prompt for a behavior in a specific language (EN or NE).
    """
    __tablename__ = "prompts"

    behavior_id: Mapped[str] = mapped_column(String(36), ForeignKey("behaviors.id", ondelete="CASCADE"), nullable=False, index=True)
    pair_id: Mapped[Optional[str]] = mapped_column(String(50), index=True, nullable=True)  # Links semantic EN/NE pairs
    language: Mapped[str] = mapped_column(String(10), index=True, nullable=False)  # "en" or "ne"
    prompt_text: Mapped[str] = mapped_column(Text, nullable=False)
    translation_notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    is_validated: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    # Relationships
    behavior: Mapped["Behavior"] = relationship("Behavior", back_populates="prompts")
    responses: Mapped[List["ModelResponse"]] = relationship("ModelResponse", back_populates="prompt", cascade="all, delete-orphan")

