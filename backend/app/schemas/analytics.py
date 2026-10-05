from typing import Any, Dict, List, Optional
from pydantic import BaseModel


class LanguageSafetyMetrics(BaseModel):
    language: str
    total_prompts: int
    harmful_count: int
    benign_count: int
    
    # Harmful metrics
    safe_refusal_count: int
    partial_compliance_count: int
    unsafe_compliance_count: int
    harmful_ambiguous_count: int
    harmful_refusal_rate: float      # HRR: Safe Refusal / harmful_count
    unsafe_compliance_rate: float    # UCR: Unsafe Compliance / harmful_count
    partial_compliance_rate: float   # PCR: Partial Compliance / harmful_count

    # Benign metrics
    appropriate_compliance_count: int
    over_refusal_count: int
    benign_ambiguous_count: int
    benign_compliance_rate: float    # BCR: Appropriate Compliance / benign_count
    over_refusal_rate: float         # ORR: Over-Refusal / benign_count


class StatisticalSignificance(BaseModel):
    test_name: str
    statistic: float
    p_value: float
    is_statistically_significant: bool  # True if p_value < 0.05
    interpretation: str


class MetricConfidenceInterval(BaseModel):
    metric: str
    language: str
    point_estimate: float
    ci_lower: float
    ci_upper: float
    confidence_level: float = 0.95


class CrossLingualDelta(BaseModel):
    delta_hrr: float   # HRR(EN) - HRR(NE)
    delta_ucr: float   # UCR(EN) - UCR(NE)
    delta_orr: float   # ORR(EN) - ORR(NE)
    delta_bcr: float   # BCR(EN) - BCR(NE)
    significance: Optional[StatisticalSignificance] = None
    confidence_intervals: Optional[List[MetricConfidenceInterval]] = None


class BehaviorComparisonItem(BaseModel):
    behavior_id: str
    source_id: str
    category: str
    prompt_type: str
    en_prompt: str
    en_response: Optional[str] = None
    en_label: Optional[str] = None
    ne_prompt: str
    ne_response: Optional[str] = None
    ne_label: Optional[str] = None
    is_safety_divergent: bool = False  # e.g., refused in EN but complied in NE


class SystemPerformanceMetrics(BaseModel):
    en_avg_latency_ms: float = 0.0
    ne_avg_latency_ms: float = 0.0
    latency_inflation_ratio: float = 1.0
    en_total_tokens: int = 0
    ne_total_tokens: int = 0
    token_inflation_ratio: float = 1.0  # Language / Tokenization Tax (Tokens_NE / Tokens_EN)
    total_tokens_consumed: int = 0


class CategoryDisparityMetric(BaseModel):
    category: str
    total_prompts: int
    en_ucr: float
    ne_ucr: float
    delta_ucr: float
    en_hrr: float
    ne_hrr: float
    delta_hrr: float
    divergent_count: int
    risk_level: str  # "CRITICAL", "ELEVATED", "PARITY"


class RQ1Metrics(BaseModel):
    experiment_id: str
    target_model: str
    en_metrics: Optional[LanguageSafetyMetrics] = None
    ne_metrics: Optional[LanguageSafetyMetrics] = None
    cross_lingual_delta: Optional[CrossLingualDelta] = None
    divergent_behavior_count: int = 0
    comparisons: List[BehaviorComparisonItem] = []
    performance_metrics: Optional[SystemPerformanceMetrics] = None
    category_breakdown: List[CategoryDisparityMetric] = []


class ClassPerformanceMetric(BaseModel):
    label: str
    precision: float
    recall: float
    f1_score: float
    support: int


class ConfusionMatrixResult(BaseModel):
    classes: List[str]
    matrix: Dict[str, Dict[str, int]]  # matrix[actual_human_label][predicted_automated_label] = count
    accuracy: float
    macro_f1: float
    weighted_f1: float
    per_class_metrics: List[ClassPerformanceMetric]


class RQ2Metrics(BaseModel):
    experiment_id: str
    total_automated_evaluations: int
    critic_confirmed_count: int
    critic_revised_count: int
    critic_revision_rate: float

    total_human_annotated: int
    agreement_count: int
    raw_agreement_rate: float
    cohens_kappa: Optional[float] = None
    
    label_distribution_automated: Dict[str, int] = {}
    label_distribution_human: Dict[str, int] = {}
    confusion_matrix: Optional[ConfusionMatrixResult] = None


class DPOTrainingPair(BaseModel):
    behavior_id: str
    category: str
    prompt: str
    chosen: str  # Safe refusal in Nepali
    rejected: str  # Unsafe compliance produced by target LLM
    source_en_label: Optional[str] = None


class RemediationCategorySummary(BaseModel):
    category: str
    failure_count: int
    vulnerability_rate: float
    key_threat_terms: List[str] = []


class RemediationReport(BaseModel):
    experiment_id: str
    target_model: str
    total_failures: int
    cross_lingual_gap_count: int  # Instances where EN was safe refusal, but NE was unsafe compliance
    vulnerable_categories: List[RemediationCategorySummary]
    recommended_system_prompt_patch: str
    mitigation_action_items: List[str]
    dpo_dataset: List[DPOTrainingPair]


