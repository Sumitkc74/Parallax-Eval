import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.taxonomy import (
    get_allowed_labels,
    validate_label_for_prompt_type,
    get_taxonomy_definition,
    get_full_taxonomy,
    TAXONOMY_REGISTRY,
)
from app.models import Prompt
from app.schemas.common import HarmfulSafetyLabel, BenignSafetyLabel, PromptType
from app.services.analytics_service import calculate_confusion_matrix


@pytest.mark.asyncio
async def test_taxonomy_endpoint(client: AsyncClient):
    """Verifies that the /api/v1/behaviors/taxonomy endpoint returns the full rubric."""
    resp = await client.get("/api/v1/behaviors/taxonomy")
    assert resp.status_code == 200
    data = resp.json()
    
    assert HarmfulSafetyLabel.SAFE_REFUSAL.value in data
    assert HarmfulSafetyLabel.UNSAFE_COMPLIANCE.value in data
    assert BenignSafetyLabel.APPROPRIATE_COMPLIANCE.value in data
    assert BenignSafetyLabel.OVER_REFUSAL.value in data

    safe_refusal = data[HarmfulSafetyLabel.SAFE_REFUSAL.value]
    assert "criteria" in safe_refusal
    assert "boundary_distinction" in safe_refusal
    assert len(safe_refusal["example_indicators"]) > 0


def test_taxonomy_helper_functions():
    """Tests the taxonomy helper validation functions."""
    harmful_labels = get_allowed_labels(PromptType.HARMFUL.value)
    assert HarmfulSafetyLabel.SAFE_REFUSAL.value in harmful_labels
    assert BenignSafetyLabel.APPROPRIATE_COMPLIANCE.value not in harmful_labels

    benign_labels = get_allowed_labels(PromptType.BENIGN.value)
    assert BenignSafetyLabel.APPROPRIATE_COMPLIANCE.value in benign_labels
    assert HarmfulSafetyLabel.UNSAFE_COMPLIANCE.value not in benign_labels

    assert validate_label_for_prompt_type(PromptType.HARMFUL.value, HarmfulSafetyLabel.SAFE_REFUSAL.value) is True
    assert validate_label_for_prompt_type(PromptType.HARMFUL.value, BenignSafetyLabel.OVER_REFUSAL.value) is False

    rubric = get_taxonomy_definition(HarmfulSafetyLabel.SAFE_REFUSAL.value)
    assert rubric is not None
    assert rubric.prompt_type == "harmful"


def test_confusion_matrix_calculation():
    """Verifies accuracy, precision, recall, macro-F1, and weighted-F1 calculations."""
    actual = ["Safe Refusal", "Safe Refusal", "Unsafe Compliance", "Over-Refusal"]
    predicted = ["Safe Refusal", "Unsafe Compliance", "Unsafe Compliance", "Over-Refusal"]

    cm = calculate_confusion_matrix(actual=actual, predicted=predicted)
    assert cm is not None
    assert cm.accuracy == 0.75  # 3 out of 4 correct
    assert len(cm.classes) == 3
    assert cm.matrix["Safe Refusal"]["Safe Refusal"] == 1
    assert cm.matrix["Safe Refusal"]["Unsafe Compliance"] == 1

    # Precision for Safe Refusal: TP=1, FP=0 -> 1.0
    sr_metric = next(m for m in cm.per_class_metrics if m.label == "Safe Refusal")
    assert sr_metric.precision == 1.0
    assert sr_metric.recall == 0.5  # TP=1, FN=1 -> 0.5

    assert cm.macro_f1 > 0.0
    assert cm.weighted_f1 > 0.0


@pytest.mark.asyncio
async def test_prompt_pair_id_linkage(test_db: AsyncSession):
    """Verifies that seeded prompts have non-null pair_ids connecting EN and NE counterparts."""
    stmt = select(Prompt).where(Prompt.pair_id.isnot(None))
    result = await test_db.execute(stmt)
    prompts = result.scalars().all()
    assert len(prompts) > 0

    # Ensure pairs share matching pair_ids
    pair_groups = {}
    for p in prompts:
        pair_groups.setdefault(p.pair_id, []).append(p)

    for pair_id, pair_prompts in pair_groups.items():
        assert pair_id.startswith("PAIR-")
        langs = {p.language for p in pair_prompts}
        assert "en" in langs
        assert "ne" in langs
