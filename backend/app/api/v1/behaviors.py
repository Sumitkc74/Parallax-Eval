import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.core.errors import ResourceNotFoundException, ExperimentConflictException
from app.models import Behavior, Prompt
from app.schemas.behavior import (
    BehaviorWithPromptsRead,
    BehaviorCreate,
    BehaviorRead,
    CustomBehaviorCreate,
    CustomBehaviorUpdate,
    PromptTranslationRequest,
    PromptTranslationResponse,
)
from app.services.translation_service import TranslationService
from app.seed.seed_db import seed_benchmark_dataset

router = APIRouter(prefix="/behaviors", tags=["Behaviors & Prompts"])


@router.get("", response_model=List[BehaviorWithPromptsRead])
async def list_behaviors(
    prompt_type: Optional[str] = Query(None, description="Filter by harmful or benign"),
    category: Optional[str] = Query(None, description="Filter by category"),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(Behavior).options(selectinload(Behavior.prompts)).order_by(Behavior.source_id)
    if prompt_type:
        stmt = stmt.where(Behavior.prompt_type == prompt_type)
    if category:
        stmt = stmt.where(Behavior.category == category)

    result = await db.execute(stmt)
    return result.scalars().all()


@router.get("/taxonomy", tags=["Behaviors & Prompts"])
async def get_safety_taxonomy():
    """Returns the centralized safety classification taxonomy, rubrics, and guidelines."""
    from app.core.taxonomy import get_full_taxonomy
    return get_full_taxonomy()


@router.get("/{behavior_id}", response_model=BehaviorWithPromptsRead)
async def get_behavior(behavior_id: str, db: AsyncSession = Depends(get_db)):
    stmt = select(Behavior).where(Behavior.id == behavior_id).options(selectinload(Behavior.prompts))
    result = await db.execute(stmt)
    behavior = result.scalar_one_or_none()
    if not behavior:
        raise ResourceNotFoundException("Behavior", behavior_id)
    return behavior


@router.put("/{behavior_id}", response_model=BehaviorWithPromptsRead)
async def update_behavior(
    behavior_id: str,
    payload: CustomBehaviorUpdate,
    db: AsyncSession = Depends(get_db),
):
    """
    Updates an existing behavior and its associated prompt variants (Right to Rectification / GDPR Art. 16).
    """
    stmt = select(Behavior).where(Behavior.id == behavior_id).options(selectinload(Behavior.prompts))
    result = await db.execute(stmt)
    behavior = result.scalar_one_or_none()
    if not behavior:
        raise ResourceNotFoundException("Behavior", behavior_id)

    if payload.category is not None:
        behavior.category = payload.category
    if payload.prompt_type is not None:
        behavior.prompt_type = payload.prompt_type.value
    if payload.english_description is not None:
        behavior.english_description = payload.english_description

    if payload.english_prompt is not None or payload.nepali_prompt is not None:
        for prompt in behavior.prompts:
            if prompt.language == "en" and payload.english_prompt is not None:
                prompt.prompt_text = payload.english_prompt
            elif prompt.language == "ne" and payload.nepali_prompt is not None:
                prompt.prompt_text = payload.nepali_prompt

    await db.commit()
    stmt = select(Behavior).where(Behavior.id == behavior_id).options(selectinload(Behavior.prompts))
    result = await db.execute(stmt)
    return result.scalar_one()


@router.delete("/{behavior_id}", status_code=status.HTTP_200_OK)
async def delete_behavior(behavior_id: str, db: AsyncSession = Depends(get_db)):
    """
    Permanently deletes a behavior and all its child prompts (Right to Erasure / GDPR Art. 17).
    """
    stmt = select(Behavior).where(Behavior.id == behavior_id)
    result = await db.execute(stmt)
    behavior = result.scalar_one_or_none()
    if not behavior:
        raise ResourceNotFoundException("Behavior", behavior_id)

    await db.delete(behavior)
    await db.commit()
    return {"message": f"Behavior '{behavior_id}' and all associated prompts successfully deleted."}


@router.post("/seed", status_code=201)
async def seed_behaviors(db: AsyncSession = Depends(get_db)):
    """Triggers idempotent database seeding of benchmark behaviors."""
    count = await seed_benchmark_dataset(session=db)
    return {"message": f"Successfully seeded {count} behaviors."}


@router.post("/custom", response_model=BehaviorWithPromptsRead, status_code=status.HTTP_201_CREATED)
async def create_custom_prompt_pair(payload: CustomBehaviorCreate, db: AsyncSession = Depends(get_db)):
    """
    Creates a new custom behavior with semantically paired English and Nepali prompts.
    The custom behavior is persisted in the benchmark database and will be automatically
    included in all subsequent experiments and evaluations.
    """
    if payload.source_id:
        existing = (await db.execute(select(Behavior).where(Behavior.source_id == payload.source_id))).scalar_one_or_none()
        if existing:
            raise ExperimentConflictException(f"Behavior with source_id '{payload.source_id}' already exists.")

    source_id = payload.source_id or f"CUSTOM-{uuid.uuid4().hex[:6].upper()}"
    pair_id = f"PAIR-{source_id}"

    behavior = Behavior(
        source_id=source_id,
        category=payload.category,
        prompt_type=payload.prompt_type.value,
        english_description=payload.english_description or payload.english_prompt[:200],
    )
    db.add(behavior)
    await db.flush()

    en_prompt = Prompt(
        behavior_id=behavior.id,
        pair_id=pair_id,
        language="en",
        prompt_text=payload.english_prompt,
        is_validated=True,
    )
    ne_prompt = Prompt(
        behavior_id=behavior.id,
        pair_id=pair_id,
        language="ne",
        prompt_text=payload.nepali_prompt,
        is_validated=True,
    )
    db.add_all([en_prompt, ne_prompt])
    await db.commit()

    stmt = select(Behavior).where(Behavior.id == behavior.id).options(selectinload(Behavior.prompts))
    result = await db.execute(stmt)
    return result.scalar_one()


@router.post("/translate", response_model=PromptTranslationResponse)
async def translate_prompt(payload: PromptTranslationRequest):
    """
    Translates an English prompt into natural Devanagari Nepali so users can inspect,
    verify, and edit the cross-lingual prompt before saving it into the benchmark database.
    """
    translated = await TranslationService.translate_english_to_nepali(payload.text)
    return PromptTranslationResponse(
        translated_text=translated,
        source_language=payload.source_language,
        target_language=payload.target_language,
    )

