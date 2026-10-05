import json
from pathlib import Path
from typing import Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import async_session_maker
from app.core.logging import logger
from app.models import Behavior, Prompt


async def seed_benchmark_dataset(session: Optional[AsyncSession] = None) -> int:
    """
    Seeds initial benchmark behaviors and paired English/Nepali prompts from seed_dataset.json.
    Idempotent: skips behaviors that already exist by source_id.
    """
    json_path = Path(__file__).parent / "seed_dataset.json"
    if not json_path.exists():
        logger.warning(f"Seed dataset file not found at {json_path}")
        return 0

    with open(json_path, "r", encoding="utf-8") as f:
        items = json.load(f)

    async def _execute_seed(s: AsyncSession) -> int:
        inserted_count = 0
        for item in items:
            source_id = item["source_id"]
            existing = await s.execute(select(Behavior).where(Behavior.source_id == source_id))
            if existing.scalar_one_or_none():
                continue

            behavior = Behavior(
                source_id=source_id,
                category=item["category"],
                prompt_type=item["prompt_type"],
                english_description=item["english_description"],
            )
            s.add(behavior)
            await s.flush()

            pair_id = f"PAIR-{source_id}"

            # Add English prompt
            en_prompt = Prompt(
                behavior_id=behavior.id,
                pair_id=pair_id,
                language="en",
                prompt_text=item["english_prompt"],
                translation_notes="Original source prompt in English.",
                is_validated=True,
            )
            s.add(en_prompt)

            # Add Nepali prompt
            ne_prompt = Prompt(
                behavior_id=behavior.id,
                pair_id=pair_id,
                language="ne",
                prompt_text=item["nepali_prompt"],
                translation_notes=item.get("translation_notes", "Human translated and verified."),
                is_validated=True,
            )
            s.add(ne_prompt)
            inserted_count += 1

        await s.commit()
        return inserted_count

    if session is not None:
        count = await _execute_seed(session)
    else:
        async with async_session_maker() as s:
            count = await _execute_seed(s)

    logger.info(f"Seeded {count} new benchmark behaviors.")
    return count

