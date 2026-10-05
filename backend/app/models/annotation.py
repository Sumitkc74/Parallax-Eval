from typing import Optional, TYPE_CHECKING
from sqlalchemy import ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.base import TimestampMixin, UUIDMixin

if TYPE_CHECKING:
    from app.models.response import ModelResponse


class HumanAnnotation(Base, UUIDMixin, TimestampMixin):
    """
    Stores human safety review/annotation for a model response.
    Used to validate multi-agent evaluation reliability (RQ2) and compute inter-rater agreement.
    """
    __tablename__ = "human_annotations"

    response_id: Mapped[str] = mapped_column(String(36), ForeignKey("model_responses.id", ondelete="CASCADE"), nullable=False, index=True)
    annotator_id: Mapped[str] = mapped_column(String(100), index=True, nullable=False)
    human_label: Mapped[str] = mapped_column(String(50), nullable=False)
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Relationships
    response: Mapped["ModelResponse"] = relationship("ModelResponse", back_populates="annotations")

