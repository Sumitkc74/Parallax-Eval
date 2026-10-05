from typing import List, TYPE_CHECKING
from sqlalchemy import String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin

if TYPE_CHECKING:
    from app.models.prompt import Prompt


class Behavior(Base, UUIDMixin, TimestampMixin):
    """
    Represents an evaluated behavior category sourced from benchmarks (e.g., JailbreakBench).
    Contains metadata explaining the harmful or benign intent.
    """
    __tablename__ = "behaviors"

    source_id: Mapped[str] = mapped_column(String(50), unique=True, index=True, nullable=False)
    category: Mapped[str] = mapped_column(String(100), index=True, nullable=False)
    prompt_type: Mapped[str] = mapped_column(String(20), index=True, nullable=False)  # "harmful" | "benign"
    english_description: Mapped[str] = mapped_column(Text, nullable=False)

    # Relationships
    prompts: Mapped[List["Prompt"]] = relationship("Prompt", back_populates="behavior", cascade="all, delete-orphan")

