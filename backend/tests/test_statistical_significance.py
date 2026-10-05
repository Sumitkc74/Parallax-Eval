import pytest
from app.services.analytics_service import (
    calculate_mcnemar_test,
    calculate_bootstrap_ci,
)
from app.schemas.analytics import StatisticalSignificance


def test_mcnemar_identical_pairs():
    # Both languages safe for all 20 pairs
    pairs = [(True, True)] * 20
    result = calculate_mcnemar_test(pairs)
    assert isinstance(result, StatisticalSignificance)
    assert result.statistic == 0.0
    assert result.p_value == 1.0
    assert not result.is_statistically_significant
    assert "no discordant pairs" in result.interpretation


def test_mcnemar_significant_divergence():
    # Severe cross-lingual regression: 15 pairs safe in EN but unsafe in NE; 0 reverse
    pairs = [(True, False)] * 15 + [(True, True)] * 5
    result = calculate_mcnemar_test(pairs)
    assert result.statistic > 10.0
    assert result.p_value < 0.01
    assert result.is_statistically_significant
    assert "Statistically significant cross-lingual divergence detected" in result.interpretation


def test_mcnemar_balanced_discordance():
    # Symmetric discordance: 3 EN safe / NE unsafe, 3 NE safe / EN unsafe
    pairs = [(True, False)] * 3 + [(False, True)] * 3 + [(True, True)] * 14
    result = calculate_mcnemar_test(pairs)
    assert result.p_value >= 0.05
    assert not result.is_statistically_significant


def test_bootstrap_confidence_interval():
    # 80% success rate across 100 observations
    outcomes = [1] * 80 + [0] * 20
    ci_lower, ci_upper = calculate_bootstrap_ci(outcomes, n_bootstrap=500, alpha=0.05)

    assert 0.70 <= ci_lower <= 0.80
    assert 0.80 <= ci_upper <= 0.90
    assert ci_lower <= 0.80 <= ci_upper


def test_bootstrap_empty_outcomes():
    ci_lower, ci_upper = calculate_bootstrap_ci([])
    assert ci_lower == 0.0
    assert ci_upper == 0.0

