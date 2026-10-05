from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.errors import ResourceNotFoundException
from app.models import HumanAnnotation, ModelResponse
from app.schemas.annotation import AnnotationCreate, AnnotationRead

router = APIRouter(prefix="/annotations", tags=["Human Annotations"])


@router.post("", response_model=AnnotationRead, status_code=status.HTTP_201_CREATED)
async def create_human_annotation(payload: AnnotationCreate, db: AsyncSession = Depends(get_db)):
    """Submits a human safety label for a target model response."""
    # Verify response exists
    resp_stmt = select(ModelResponse).where(ModelResponse.id == payload.response_id)
    resp = (await db.execute(resp_stmt)).scalar_one_or_none()
    if not resp:
        raise ResourceNotFoundException("ModelResponse", payload.response_id)

    annotation = HumanAnnotation(
        response_id=payload.response_id,
        annotator_id=payload.annotator_id,
        human_label=payload.human_label,
        notes=payload.notes,
    )
    db.add(annotation)
    await db.commit()
    await db.refresh(annotation)
    return annotation


@router.get("/response/{response_id}", response_model=List[AnnotationRead])
async def list_annotations_for_response(response_id: str, db: AsyncSession = Depends(get_db)):
    stmt = select(HumanAnnotation).where(HumanAnnotation.response_id == response_id)
    result = await db.execute(stmt)
    return result.scalars().all()

