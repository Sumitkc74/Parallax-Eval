import pytest
from app.services.analytics_service import calculate_cohens_kappa, _compute_language_metrics
from app.schemas.common import HarmfulSafetyLabel, BenignSafetyLabel


def test_cohens_kappa_perfect_agreement():
    rater1 = ["Safe Refusal", "Unsafe Compliance", "Safe Refusal", "Partial Compliance"]
    rater2 = ["Safe Refusal", "Unsafe Compliance", "Safe Refusal", "Partial Compliance"]
    kappa = calculate_cohens_kappa(rater1, rater2)
    assert kappa == 1.0


def test_cohens_kappa_disagreement():
    rater1 = ["Safe Refusal", "Safe Refusal", "Safe Refusal", "Safe Refusal"]
    rater2 = ["Unsafe Compliance", "Unsafe Compliance", "Unsafe Compliance", "Unsafe Compliance"]
    kappa = calculate_cohens_kappa(rater1, rater2)
    # Expected chance agreement matches or exceeds, kappa <= 0
    assert kappa is not None
    assert kappa <= 0.0


def test_compute_language_metrics_math():
    mock_evals = [
        {"prompt_type": "harmful", "final_label": HarmfulSafetyLabel.SAFE_REFUSAL.value},
        {"prompt_type": "harmful", "final_label": HarmfulSafetyLabel.SAFE_REFUSAL.value},
        {"prompt_type": "harmful", "final_label": HarmfulSafetyLabel.UNSAFE_COMPLIANCE.value},
        {"prompt_type": "harmful", "final_label": HarmfulSafetyLabel.PARTIAL_COMPLIANCE.value},
        {"prompt_type": "benign", "final_label": BenignSafetyLabel.APPROPRIATE_COMPLIANCE.value},
        {"prompt_type": "benign", "final_label": BenignSafetyLabel.OVER_REFUSAL.value},
    ]

    metrics = _compute_language_metrics(mock_evals, "en")
    assert metrics.harmful_count == 4
    assert metrics.benign_count == 2
    assert metrics.safe_refusal_count == 2
    assert metrics.harmful_refusal_rate == 0.5   # 2 / 4
    assert metrics.unsafe_compliance_rate == 0.25 # 1 / 4
    assert metrics.partial_compliance_rate == 0.25 # 1 / 4
    assert metrics.benign_compliance_rate == 0.5  # 1 / 2
    assert metrics.over_refusal_rate == 0.5       # 1 / 2


def test_system_performance_metrics():
    from app.schemas.analytics import SystemPerformanceMetrics
    perf = SystemPerformanceMetrics(
        en_avg_latency_ms=250.0,
        ne_avg_latency_ms=500.0,
        latency_inflation_ratio=2.0,
        en_total_tokens=1000,
        ne_total_tokens=2500,
        token_inflation_ratio=2.5,
        total_tokens_consumed=3500,
    )
    assert perf.latency_inflation_ratio == 2.0
    assert perf.token_inflation_ratio == 2.5
    assert perf.total_tokens_consumed == 3500


