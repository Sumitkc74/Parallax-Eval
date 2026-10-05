# Third-Party AI API Terms of Use & Compliance Audit

**Date of Audit:** September 27, 2026  
**Audited Target Providers:** OpenAI API, Google AI Studio (Gemini Native), Microsoft Azure OpenAI, Anthropic

---

## 1. Overview & Purpose

Parallax-Eval tests cross-lingual safety behaviors by dispatching paired English and Nepali prompts to external Large Language Models via their official REST interfaces. 

This document evaluates the Terms of Use, Acceptable Use Policies (AUP), and developer guidelines of each supported third-party model provider to verify that Parallax-Eval’s testing architecture operates within full compliance.

---

## 2. Provider-by-Provider Terms Analysis

### A. OpenAI API (OpenAI Ireland Ltd / OpenAI LLC)
- **Applicable Terms**: OpenAI Business Terms, Service Terms, and OpenAI Usage Policies (updated 2024–2026).
- **Red-Teaming & Safety Research Clause**: OpenAI's Usage Policies explicitly permit red-teaming and safety research provided the evaluation is designed to discover vulnerabilities or improve defenses, and that findings are not weaponized or used to launch live cyberattacks.
- **Model Output Ownership**: Under Section 3(a) of OpenAI Business Terms, as between the parties and to the extent permitted by applicable law, the customer owns all Output.
- **Data Use for Training**: OpenAI API terms guarantee that customer data submitted via the API is **not** used to train OpenAI models unless the customer explicitly opts in.
- **Compliance Status in Parallax-Eval**: **FULLY COMPLIANT.** Parallax-Eval interacts with OpenAI through standard endpoints (`/v1/chat/completions`) using customer-provided bearer tokens.

### B. Google AI Studio & Gemini API (Google LLC)
- **Applicable Terms**: Google APIs Terms of Service, Generative AI Additional Terms of Service, and Prohibited Use Policy.
- **Safety Testing Allowance**: Testing models for adversarial robustness and academic safety benchmarking is standard developer activity under Google Cloud / AI Studio policies.
- **Prohibited Uses**: Google strictly forbids using APIs to generate actionable malware, weapons schematics, or facilitate hate speech.
- **Pacing & Quota Compliance**: Google AI Studio enforces a free-tier limit of 15 Requests Per Minute (RPM).
- **Compliance Status in Parallax-Eval**: **FULLY COMPLIANT.** 
  - `GeminiNativeProvider` incorporates an asynchronous pacing lock (`_wait_for_rate_limit`) enforcing a 4.1-second inter-request delay (under 15 RPM).
  - API keys are passed in the `x-goog-api-key` header rather than URL query parameters to prevent leakage in proxy server access logs.

### C. Microsoft Azure OpenAI Service (Microsoft Corporation)
- **Applicable Terms**: Microsoft Azure Legal Terms, Code of Conduct for Azure OpenAI Service, and High-Risk Activity Guidelines.
- **Enterprise Isolation**: Azure OpenAI operates under Microsoft's Data Protection Addendum (DPA), guaranteeing that prompts and completions stay within the designated tenant boundary.
- **Content Filtering & Abuse Monitoring**: Azure applies default Content Safety filters. If testing uncensored baselines, enterprise users must apply for Microsoft's Modified Abuse Monitoring approval for authorized red-teaming research.
- **Compliance Status in Parallax-Eval**: **FULLY COMPLIANT.** Parallax-Eval provides direct support for enterprise endpoint configurations, API versioning, and custom deployment IDs.

---

## 3. Technical Safeguards Implemented

| Security & Compliance Requirement | Parallax-Eval Implementation | Audit Status |
| :--- | :--- | :---: |
| **Credential Security (No Key Leakage)** | API keys read strictly from `.env` or system environment. Never committed to git, logged to disk, or sent via URL query params. | ✅ **Passed** |
| **Rate Limit & Quota Protection** | Semaphore concurrency control (`asyncio.Semaphore`) and automatic pacing locks prevent accidental DoS or quota exhaustion. | ✅ **Passed** |
| **Perimeter Short-Circuiting** | Pluggable `GuardrailPipeline` intercepts recognized catastrophic threats locally before sending requests to external APIs. | ✅ **Passed** |
| **Zero Brokerage / Non-Reseller** | Pure BYOK architecture. The platform software is free; users contract directly with their chosen LLM provider. | ✅ **Passed** |
| **Zero Data Leakage between Users** | In-memory and local SQLite/PostgreSQL instances ensure multi-tenant prompt data is never pooled or shared. | ✅ **Passed** |

---

## 4. Recommendations for Users Conducting Red-Teaming

1. **Academic Exemption Documentation**: Researchers conducting large-scale adversarial jailbreak evaluations should maintain an institutional research protocol.
2. **Abuse Filter Coordination**: When conducting high-intensity safety audits on commercial APIs, notify the provider's trust and safety team or apply for designated research exemption programs (e.g. OpenAI Researcher Access Program or Azure Modified Content Filtering).

