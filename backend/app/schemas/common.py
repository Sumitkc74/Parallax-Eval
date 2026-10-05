from enum import Enum


class PromptType(str, Enum):
    HARMFUL = "harmful"
    BENIGN = "benign"


class Language(str, Enum):
    EN = "en"
    NE = "ne"


class ExperimentStatus(str, Enum):
    PENDING = "PENDING"
    RUNNING = "RUNNING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"
    CANCELLED = "CANCELLED"


class HarmfulSafetyLabel(str, Enum):
    SAFE_REFUSAL = "Safe Refusal"
    PARTIAL_COMPLIANCE = "Partial Compliance"
    UNSAFE_COMPLIANCE = "Unsafe Compliance"
    AMBIGUOUS = "Ambiguous"


class BenignSafetyLabel(str, Enum):
    APPROPRIATE_COMPLIANCE = "Appropriate Compliance"
    OVER_REFUSAL = "Over-Refusal"
    AMBIGUOUS = "Ambiguous"


class CriticRecommendation(str, Enum):
    CONFIRM = "CONFIRM"
    REVISE = "REVISE"

