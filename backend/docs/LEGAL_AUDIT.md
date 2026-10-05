# Legal, Governance & Regulatory Compliance Audit

**Audit Date:** September 27, 2026  
**Auditor:** Parallax-Eval Autonomous Legal & Governance Compliance Suite  
**Scope:** Full-Stack Codebase (FastAPI Backend, PostgreSQL/SQLite DB, Flutter Client, Documentation)  
**Overall Compliance Grade:** **A- (Enterprise & Academic Ready)**

---

## 1. Executive Summary

This comprehensive audit evaluates the legal, regulatory, and ethical risks of **Parallax-Eval**, a platform designed for cross-lingual AI safety evaluation and adversarial red-teaming across English and Nepali. 

The platform implements robust software engineering defenses, privacy-by-design principles, and zero-PII architectural boundaries. This report assesses compliance with international regulations and identifies specific items requiring formal legal counsel prior to high-stakes enterprise deployment.

---

## 2. Regulatory Compliance Scorecard

| Domain / Regulation | Key Standard | Parallax-Eval Implementation | Compliance Status |
| :--- | :--- | :--- | :---: |
| **Data Protection & Privacy** | GDPR / CCPA / Nepal Privacy Act 2075 | Zero-PII rule, full Right to Erasure (`DELETE /api/v1/behaviors/{id}`), Right to Rectification (`PUT /api/v1/behaviors/{id}`), no persistent tracking cookies. | ✅ **Compliant** |
| **Acceptable Use & Harm Prevention** | NIST AI RMF / OWASP LLM06 | Strict AUP prohibiting real-world harm, weapons manufacturing, and unauthorized cyberattacks. Disclaimers for high-risk advice. | ✅ **Compliant** |
| **Age Verification & Child Safety** | COPPA / GDPR-K | Explicit 18+ age restriction requirement in Terms of Service and interactive Consent Form modal. | ✅ **Compliant** |
| **Third-Party API Terms of Use** | OpenAI / Google / Azure Terms | BYOK architecture, API key header encryption, 15 RPM pacing lock, guardrail pre-screening. | ✅ **Compliant** |
| **Open-Source Licensing & SBOM** | Apache-2.0 / MIT / BSD | 100% permissive dependencies; 0 GPL/AGPL copyleft contamination; standard Material/Cupertino icon licenses; full attribution. | ✅ **Compliant** |
| **Consumer Protection & Marketing** | FTC AI Guidelines (2023) | All benchmark claims mathematically substantiated via McNemar's test and 1,000-resample bootstrap CIs; no deceptive guarantees. | ✅ **Compliant** |
| **Charges, Refunds & Billing** | Commercial Law / UCC | Explicit disclosure that platform software is free; users contract directly with third-party model providers for token fees. | ✅ **Compliant** |

---

## 3. Detailed Regulatory Findings

### A. Data Subject Rights & Nepal Privacy Act, 2075 (2018)
- **Findings**: The platform evaluation database stores benchmark behaviors and prompts. To guarantee full compliance with Sections 6, 7, and 8 of the Nepal Privacy Act 2075 and Articles 16 & 17 of GDPR:
  - Users can correct their prompt pairs via `PUT /api/v1/behaviors/{id}`.
  - Users can completely expunge their records via `DELETE /api/v1/behaviors/{id}`, which triggers cascade deletion across all prompt variants, model responses, annotations, and evaluations.
  - The platform does not use tracking or advertising cookies.

### B. EU AI Act (Regulation (EU) 2024/1689)
- **Classification**: Parallax-Eval is an **AI evaluation and testing platform**, not a high-risk standalone AI deployer under Annex III.
- **Transparency Obligations (Article 50)**: The system clearly labels all model responses as synthetic, AI-generated completions. Multi-agent evaluation classifications are explicitly presented with confidence scores and reasoning traces.
- **Article 5 (Prohibited AI Practices)**: Parallax-Eval does not deploy cognitive behavioral manipulation, social scoring, or biometric categorization. Testing harmful behaviors is conducted purely for vulnerability assessment.

### C. Intellectual Property & AI-Generated Content
- **U.S. Copyright Office Guidance (March 2023)**: Pure AI-generated completions lack human authorship and cannot be copyrighted. Users retain ownership of original prompts they author.
- **Academic Fair Use (17 U.S.C. § 107)**: Incorporating standard evaluation behaviors from academic benchmarks operates squarely within non-commercial scientific fair use.

### D. FTC AI Marketing Claims Audit
- Under the FTC’s 2023 guidance (*"Keep your AI claims in check"*), AI companies cannot make unsubstantiated claims regarding safety or capabilities:
  - **Audit Result**: Parallax-Eval makes **zero unsubstantiated claims**. It does not promise "100% unhackable safety." Instead, it provides empirical, statistical parity measurement with exact $p$-values and confidence intervals.

---

## 4. ⚠️ Matters Requiring Review by Qualified Legal Counsel

While Parallax-Eval meets engineering and regulatory best practices, the following four specific items should be reviewed by qualified legal counsel if the platform is commercialized, deployed as a multi-tenant cloud service, or exported internationally:

### 1. Dual-Use & Export Control (Wassenaar Arrangement / EAR)
- **The Issue**: Parallax-Eval incorporates an **Adaptive Red-Team Mutator** (`backend/app/services/redteam_engine.py`) that iteratively mutates prompts to bypass safety guardrails.
- **Legal Consideration**: Certain automated vulnerability exploit tools fall under Wassenaar Arrangement Category 4 ("Surveillance / Intrusion Software") or U.S. Export Administration Regulations (EAR). While academic defensive benchmarking is typically exempt, legal counsel should verify export classification (ECCN 5D002 / EAR99) before distributing the mutation engine in foreign jurisdictions.

### 2. Cross-Border Data Transfers under Nepal Privacy Act 2075
- **The Issue**: Section 24 of the Nepal Privacy Act 2075 governs the transmission of data outside Nepal.
- **Legal Consideration**: When a user in Nepal enters prompts that are evaluated by OpenAI or Microsoft Azure servers located in the United States or European Union, cross-border data transfer rules may be invoked if any personally identifiable information is entered. Counsel should review standard contractual clauses (SCCs) for cross-border research pipelines.

### 3. Institutional Review Board (IRB) Clearance for Human Annotators
- **The Issue**: The Rapid Human Review interface presents human evaluators with toxic, abusive, or self-harm prompts to collect ground-truth labels.
- **Legal & Ethical Consideration**: Academic institutions and corporate employers have a legal duty of care regarding psychological safety. Legal and ethical counsel should determine whether an Institutional Review Board (IRB) protocol or psychological distress disclaimer is required for human annotators reviewing adversarial content.

### 4. Enterprise Indemnification & BYOK Liability Shield
- **The Issue**: If a user enters a custom API key and generates offensive material, the user might attempt to hold Parallax-Eval liable for third-party API suspension or damages.
- **Legal Consideration**: Counsel should ensure that the Apache-2.0 Section 8 limitation of liability is supplemented with a mandatory clickwrap indemnification agreement if the software is hosted as a SaaS application.

