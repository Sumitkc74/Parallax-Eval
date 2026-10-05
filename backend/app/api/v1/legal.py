import os
from fastapi import APIRouter
from pydantic import BaseModel
from typing import Dict, Any, List

router = APIRouter(prefix="/legal", tags=["Legal, Compliance & Governance"])


class LegalSummaryResponse(BaseModel):
    platform_name: str
    license: str
    version: str
    age_restriction: str
    cookie_consent_required: bool
    cookie_policy_statement: str
    zero_pii_rule: str
    acceptable_use_summary: str
    refund_cancellation_policy: str
    disclaimers: List[str]
    compliance_standards: List[str]


class ConsentInfoResponse(BaseModel):
    title: str
    what_data_is_collected: List[str]
    why_data_is_collected: List[str]
    where_data_is_stored: str
    data_subject_rights: List[str]
    age_limit_years: int
    zero_pii_warning: str


def _read_doc_file(filename: str) -> str:
    from pathlib import Path
    current = Path(__file__).resolve()
    # Search both project root docs and backend docs
    candidates = [
        current.parents[4] / "docs" / filename,
        current.parents[3] / "docs" / filename,
        Path.cwd() / "docs" / filename,
        Path.cwd() / "backend" / "docs" / filename,
    ]
    for p in candidates:
        if p.exists() and p.is_file():
            try:
                with open(p, "r", encoding="utf-8") as f:
                    return f.read()
            except Exception:
                pass
    return f"# {filename}\n\nThis legal document is currently available in the project repository under `docs/{filename}`."


@router.get("/summary", response_model=LegalSummaryResponse)
async def get_legal_summary():
    """
    Returns high-level legal, regulatory, and data governance disclosures.
    """
    return LegalSummaryResponse(
        platform_name="Parallax-Eval Cross-Lingual Safety Evaluation Platform",
        license="Apache License, Version 2.0 (Open Source)",
        version="1.0.0",
        age_restriction="Minimum 18 years old (or legal majority in jurisdiction). Not intended for minors under COPPA/GDPR-K.",
        cookie_consent_required=False,
        cookie_policy_statement="Parallax-Eval does NOT use persistent tracking, profiling, or third-party advertising cookies. Only functional local storage is used for client API endpoint settings.",
        zero_pii_rule="Strictly prohibited: users must never submit real names, government IDs, credentials, or private personal data into benchmark prompts.",
        acceptable_use_summary="Permitted exclusively for lawful academic benchmarking, AI safety research, and defensive evaluation. Strictly prohibits weapon design, unauthorized cyberattacks, or real-world harm.",
        refund_cancellation_policy="Parallax-Eval core software is 100% free and open-source. Model inference charges are billed directly by third-party API providers (OpenAI, Google, Azure) under their independent terms.",
        disclaimers=[
            "High-Risk Content: Evaluates adversarial and harmful prompt behaviors; target LLM outputs may contain offensive or toxic text.",
            "No Professional Advice: System outputs do not constitute certified medical, legal, financial, or tactical guidance.",
            "No Absolute Safety Guarantee: Safety guardrails and prompt inoculations reduce disparities but do not guarantee 100% immunity to novel jailbreaks.",
            "AS-IS Basis: Provided without warranty of any kind pursuant to Section 7 of the Apache 2.0 License.",
        ],
        compliance_standards=[
            "Nepal Privacy Act, 2075 (वैयक्तिक गोपनीयता सम्बन्धी ऐन, २०७५)",
            "Nepal National Cyber Security Policy, 2080",
            "General Data Protection Regulation (GDPR) Articles 16, 17, 89",
            "California Consumer Privacy Act (CCPA)",
            "NIST AI Risk Management Framework (NIST AI RMF 1.0)",
            "OWASP Top 10 for Large Language Model Applications (LLM06)",
            "EU AI Act (Regulation 2024/1689) Transparency Standards",
            "FTC AI Marketing Guidelines (2023)",
        ],
    )


@router.get("/consent-info", response_model=ConsentInfoResponse)
async def get_consent_info():
    """
    Returns structured data collection consent details and user rights.
    """
    return ConsentInfoResponse(
        title="Parallax-Eval Research & Data Governance Consent",
        what_data_is_collected=[
            "Benchmark prompt texts (English & Nepali pairs)",
            "Evaluated behavior categories and benign/harmful intent tags",
            "Target LLM synthetic text completions",
            "Automated judge, critic, and arbiter classification verdicts",
            "Optional human rapid-review agreement annotations",
            "Execution telemetry (token counts, latencies, guardrail intervention flags)",
        ],
        why_data_is_collected=[
            "RQ1 Research: Measuring cross-lingual safety disparities between English and Nepali",
            "RQ2 Research: Validating multi-agent judge reliability against human ground truth",
            "Statistical Rigor: Calculating McNemar's paired chi-square test and bootstrap 95% confidence intervals",
            "Automated Remediation: Synthesizing Direct Preference Optimization (DPO) datasets and bilingual inoculation prompts",
        ],
        where_data_is_stored="Locally within the user's SQLite/PostgreSQL database and temporary runtime memory. External LLM transmission occurs strictly via TLS 1.3 to customer-configured API endpoints.",
        data_subject_rights=[
            "Right to Access & Portability: Download full datasets and reports via CSV, JSON, or Markdown export.",
            "Right to Rectification: Edit and correct any custom prompt pair via PUT /api/v1/behaviors/{id}.",
            "Right to Erasure: Permanently delete custom prompt pairs and cascade-purge associated records via DELETE /api/v1/behaviors/{id}.",
            "Right to Opt-Out: Discontinue usage or delete the local database file at any time without penalty.",
        ],
        age_limit_years=18,
        zero_pii_warning="WARNING: Do not enter Personally Identifiable Information (PII), confidential passwords, financial records, or medical details.",
    )


@router.get("/privacy-policy")
async def get_privacy_policy():
    """Returns the full Privacy Policy in Markdown."""
    return {"content": _read_doc_file("PRIVACY_POLICY.md")}


@router.get("/terms-of-service")
async def get_terms_of_service():
    """Returns the full Terms of Service in Markdown."""
    return {"content": _read_doc_file("TERMS_OF_SERVICE.md")}


@router.get("/licenses")
async def get_licenses_and_attributions():
    """Returns the open-source licenses, SBOM, and third-party attributions in Markdown."""
    return {"content": _read_doc_file("LICENSES_AND_ATTRIBUTION.md")}


@router.get("/third-party-api-compliance")
async def get_third_party_compliance():
    """Returns third-party AI provider compliance analysis."""
    return {"content": _read_doc_file("THIRD_PARTY_API_COMPLIANCE.md")}


@router.get("/audit-report")
async def get_legal_audit_report():
    """Returns the legal, governance, and regulatory compliance audit report."""
    return {"content": _read_doc_file("LEGAL_AUDIT.md")}

