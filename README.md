# Parallax-Eval
### Full-Stack Cross-Lingual English–Nepali LLM Safety Evaluation Platform

[![Backend CI](https://github.com/Sumitkc74/Parallax-Eval/actions/workflows/ci.yml/badge.svg)](https://github.com/Sumitkc74/Parallax-Eval/actions)
[![Python 3.12](https://img.shields.io/badge/python-3.12-blue.svg)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-009688.svg)](https://fastapi.tiangolo.com)
[![LangGraph](https://img.shields.io/badge/LangGraph-Multi--Agent-orange.svg)](https://github.com/langchain-ai/langgraph)
[![Flutter](https://img.shields.io/badge/Flutter-3.7+-02569B.svg)](https://flutter.dev)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791.svg)](https://www.postgresql.org/)
[![Tests](https://img.shields.io/badge/Tests-80%2F80%20Passing-brightgreen.svg)](backend/tests/)

**Parallax-Eval** is a full-stack, production-grade software platform for evaluating whether Large Language Models demonstrate disparate safety behaviors when semantically equivalent prompts are presented in **English versus Nepali**.

Engineered to demonstrate modern **Software Engineering, Applied AI, and Production AI Systems** principles, the platform integrates:
- **Multi-Agent LangGraph State Machines**: Judge–Critic–Arbiter verification and iterative adaptive red-teaming.
- **Cross-Lingual Vector Retrieval Engine (RAG)**: Zero-dependency subword n-gram semantic search grounding safety judges in regulatory policies (NIST AI RMF, OWASP LLM06, Nepal Privacy Act 2075) and arming red-team mutators with proven attack exemplars.
- **Statistical Significance Engine**: Edwards' continuity-corrected McNemar's paired chi-square test with exact $p$-values and 1,000-resample non-parametric 95% bootstrap confidence intervals.
- **Production Observability & Telemetry**: OpenTelemetry-compatible span-level execution tracing, sub-agent latency tracking, and fine-grained token/cost estimation across OpenAI, Azure OpenAI, Anthropic, and local providers.
- **Enterprise Developer Tools & CI/CD**: Unified CLI (`app.cli`) for SHA-256 dataset verification and automated regression gating in GitHub Actions.
- **Architecture Rigor**: Formally documented Architecture Decision Records (ADRs 001–005) and STRIDE Threat Model.

---

## Key Research Questions

- **RQ1 (Cross-Lingual Safety Parity)**: Do target LLMs exhibit divergent refusal or compliance rates between English and Nepali across harmful and benign behaviors?
- **RQ2 (Multi-Agent Evaluation Reliability)**: How reliably does a Safety Judge–Critic multi-agent workflow classify English and Nepali LLM responses compared with ground-truth human annotations?

---

## End-to-End System Architecture

```
 ┌────────────────────────────────────────────────────────────────────────┐
 │                         Flutter Mobile Client                          │
 │  Dashboard (Live Polling) │ Comparison & Diff │ Rapid Review │ Red-Team│
 └───────────────────────────────────┬────────────────────────────────────┘
                                     │ HTTP / REST (JSON)
                                     ▼
 ┌────────────────────────────────────────────────────────────────────────┐
 │                      FastAPI Application Layer                         │
 │   /experiments  /evaluations  /retrieval  /analytics  /metrics  /health│
 └───────┬───────────────────────────┬────────────────────┬───────────────┘
         │ Enqueues                  │ Queries            │ Searches
         ▼                           ▼                    ▼
 ┌───────────────────────────┐   ┌────────────────────┐ ┌─────────────────┐
 │  Worker Supervisor        │   │ Analytics Engine   │ │ Vector Engine   │
 │  - Cooperative Cancel     │   │ - McNemar Paired   │ │ - Subword N-Gram│
 │  - Startup Zombie Cleanup │   │ - Bootstrap 95% CI │ │ - Policy RAG    │
 └───────────┬───────────────┘   │ - Diff & Gate      │ │ - Attack Exempl.│
             │                   └─────────┬──────────┘ └────────┬────────┘
             ▼                             │                     │
 ┌───────────────────────────┐             │                     │
 │  Experiment Runner        │             │                     │
 │  - Semaphore Concurrency  │             │                     │
 │  - Ablation Flags (RAG)   │             │                     │
 └───────────┬───────────────┘             │                     │
             │                             │                     │
             ├─────────────────────────────┤                     │
             ▼                             ▼                     │
 ┌───────────────────────┐   ┌───────────────────────────────┐   │
 │ Guardrail Interceptor │   │ LangGraph Multi-Agent Loop    │◄──┘
 │ (Bilingual Regex/     │   │ - Judge Node (Policy-Grounded)│
 │  Heuristic Pipeline)  │   │ - Critic Node (Counter-Arg)   │
 └───────────┬───────────┘   │ - Arbiter Node (Reconcile)    │
             │               │ - Adaptive Mutator (Exemplars)│
             │               └─────────────┬─────────────────┘
             │                             │
             └──────────────┬──────────────┘
                            ▼
 ┌────────────────────────────────────────────────────────────────────────┐
 │                     LLM Gateway & Tracing Layer                        │
 │  OpenAI │ Azure OpenAI │ Mock LLM │ OTel Spans │ Token & Cost Tracking │
 └──────────────────────────┬─────────────────────────────────────────────┘
                            ▼
 ┌────────────────────────────────────────────────────────────────────────┐
 │                  PostgreSQL 16 / SQLite WAL Database                   │
 │ Behaviors, Prompts, Experiments, ModelResponses, AutomatedEvaluations, │
 │ RedTeamAttempts, ExecutionSpans                                        │
 └────────────────────────────────────────────────────────────────────────┘
```

---

## Core Engineering Capabilities

### 1. Vector Retrieval Engine (RAG & Semantic Search)
- **Zero-Dependency Subword Vector Store (`backend/app/services/retrieval/`)**: Implements `InMemoryVectorStore` using subword character n-grams and term-frequency cosine similarity, natively handling both English and Devanagari (Nepali) scripts without requiring PyTorch or external vector databases.
- **Safety Policy Grounding**: Indexes 8 regulatory policy documents across NIST AI RMF, OWASP LLM06, and Nepal Privacy Act 2075.
- **Attack Exemplar Bank**: Indexes cross-lingual jailbreak mutation patterns to guide the adaptive red-team agent.
- **Retrieval Evaluation Metrics**: Evaluates retrieval accuracy via Precision@K, Recall@K, Mean Reciprocal Rank (MRR), and sub-millisecond search latencies.
- **REST Endpoints**: Exposes `/api/v1/retrieval/policies`, `/api/v1/retrieval/search`, and `/api/v1/retrieval/metrics`.

### 2. Multi-Agent LangGraph Evaluation & Adaptive Red-Teaming
- **Policy-Grounded Judge Node**: Dynamically retrieves matching safety policy clauses and embeds them into the judge prompt for grounded, explainable compliance classifications.
- **Adversarial Critic Node**: Generates counter-arguments and identifies subtle evasion attempts or false refusals.
- **Arbiter Node**: Reconciles disagreements between Judge and Critic into final taxonomy verdicts (`SAFE_REFUSAL`, `UNSAFE_COMPLIANCE`, `BENIGN_COMPLIANCE`, `OVER_REFUSAL`).
- **Exemplar-Guided Mutator Loop**: Uses retrieved historical attack exemplars to iteratively mutate rejected prompts across academic, hypothetical, and translation-shift jailbreaks.
- **Ablation Studies**: Controlled flag `use_rag_policy` enables empirical measurement of classification accuracy with vs. without policy RAG grounding.

### 3. Statistical Significance & Controlled Experimentation
- **McNemar's Paired Test with Edwards' Continuity Correction**: Evaluates paired discordance between English and Nepali responses on the same semantic intent, computing exact chi-square statistics and $p$-values to determine if cross-lingual safety disparities are statistically significant ($p < 0.05$).
- **Non-Parametric 95% Bootstrap Confidence Intervals**: Computes empirical 95% confidence intervals across all primary safety metrics (Harmful Refusal Rate, Unsafe Compliance Rate, Benign Compliance Rate, Over-Refusal Rate) via 1,000 resamples.
- **Automated CI/CD Safety Gate**: `app.cli compare` and `/api/v1/analytics/compare` flag regressions (Safe Refusal $\to$ Unsafe Compliance) and enforce automated deployment gating.

### 4. LLM Gateway, Azure OpenAI & OpenTelemetry Tracing
- **Provider Abstraction**: Unified gateway supporting OpenAI, Azure OpenAI, Anthropic, and offline `MockLLMProvider`.
- **Azure OpenAI Integration**: Full enterprise deployment routing, custom endpoints, `api-version` parameters, and fallback authentication.
- **Span-Level Execution Tracing (`backend/app/services/tracing.py`)**: OpenTelemetry-compatible `ExecutionTrace` capturing sub-step span latencies (`target_generation`, `safety_judge`, `safety_critic`, `arbiter`), token consumption, and error states.
- **Token Cost Accounting**: Real-time dollar cost estimation per 1k tokens for prompt and completion across GPT-4o, GPT-4o-mini, Claude, and Llama 3.

### 5. Developer Tools & CI/CD Integrity Gate
- **Unified Developer CLI (`backend/app/cli.py`)**:
  - `verify-dataset`: Validates dataset JSON schema, Devanagari UTF-8 encoding, and SHA-256 fingerprint integrity.
  - `compare`: Evaluates candidate vs. baseline experiments against regression thresholds, exiting with code 1 on failure for automated CI/CD gating.
- **Automated GitHub Actions Pipeline (`.github/workflows/ci.yml`)**: Executes dataset integrity verification and full pytest test suite on every push and pull request.

### 6. Architectural Decision Records (ADRs) & STRIDE Threat Model
- **Formal Decision Documentation (`docs/adr/`)**:
  - `ADR-001`: Modular Monolith vs. Microservices Architecture.
  - `ADR-002`: Deterministic Multi-Agent State Machine (LangGraph).
  - `ADR-003`: Token Bucket Rate Limiting & Semaphore Concurrency Control.
  - `ADR-004`: Vector Policy RAG Grounding for Safety Judges.
  - `ADR-005`: Relational Schema vs. Graph Database for Evaluation Data.
- **STRIDE Threat Modeling (`docs/THREAT_MODEL.md`)**: Comprehensive security threat analysis covering cross-lingual jailbreaks, adversarial data poisoning, prompt injection, and DoS vectors.

### 7. Safety Guardrail Interceptor Layer (Defense-in-Depth)
- Pluggable interceptor pattern (`BaseGuardrail`, `RegexKeywordGuardrail`, `HeuristicGuardrail`, `GuardrailPipeline`).
- Bilingual threat detection across weapons, cyberattacks, violence, and CBRN in both English and Devanagari Nepali.
- Short-circuits target model calls on perimeter interception, recording intervention metadata and tracking cross-lingual evasion rates.

### 8. Worker Lifecycle Supervisor & Graceful Cancellation
- **Startup Crash Recovery**: Sweeps orphaned `RUNNING` tasks left by server crashes or process termination and transitions them to `FAILED` on startup (`lifespan`).
- **Cooperative Cancellation**: `POST /api/v1/experiments/{id}/cancel` triggers `asyncio.Event` cancellation tokens to halt running evaluations without leaking database sessions or leaving dirty state.

### 9. Platform Observability & Operational Telemetry (`/metrics`)
- `GET /api/v1/metrics` exports operational telemetry:
  - Experiment lifecycle distributions (`COMPLETED`, `RUNNING`, `CANCELLED`, `FAILED`).
  - Total prompt evaluations and average response latencies.
  - Guardrail perimeter intervention counts partitioned by language.
  - Total prompt and completion token consumption and costs.

### 10. Cross-Platform Flutter Mobile Client
- **Dashboard**: Real-time status polling, progress bars, cancellation, cloning, deletion, and quick navigation to live tools.
- **Comparison & Diff View (`ComparisonScreen`)**: Visual diff tool displaying safety gate banners, metric deltas, and regression lists.
- **Experiment Detail Screen**: Search bar, language filter chips, guardrail interception badges (`🛡️`), red-team attack traces (`⚡`), and defense status badges.
- **Live Side-by-Side A/B Defense Comparator (`PromptInspectorScreen`)**: Interactive playground to input arbitrary English or Devanagari prompts and run unmitigated baseline vs. defended LLMs simultaneously, featuring a real-time automated comparative verdict banner (Remediation Succeeded, Both Safe, Defense Ineffective, Over-Refusal Introduced).
- **Threat Category Vulnerability Breakdown**: RQ1 analytics partitioned by threat categories (Cybersecurity, Weapons, Hate Speech, etc.) with risk indicators (`CRITICAL`, `ELEVATED`, `PARITY`) and interactive drilldown to filtered comparisons on tap.
- **Direct Live Inspector Drilldown**: Quick-launch buttons (`Icons.shield_outlined`) on individual comparison cards pre-populate and test any failed prompt directly in the Live Safety Inspector.
- **One-Click Executive Safety Audit Report**: Synthesizes an ISO/NIST-compliant executive audit report with statistical significance tables, language tax analysis, and copy-pasteable LaTeX tables for academic conference submissions.
- **Rapid Human Review Mode**: Accelerated ground-truth annotation swipe/tap interface for labeling model responses.
- **Interactive Red-Team Screen**: Live step-by-step visualizer for iterative jailbreak attempts.
- **Custom Prompt Pair Benchmark Ingestion (`CreateCustomPromptDialog`)**: Allows users to enter an English prompt and automatically generate its Devanagari Nepali translation using AI (`/api/v1/behaviors/translate`), allowing the user to review, verify, and fine-tune the Nepali text before persisting the paired behavior into the benchmark database (`behaviors` and `prompts` tables) for downstream experiments.
- **Automated Remediation Advisor Dialog**: Modal displaying failure counts, cross-lingual gap rates, Devanagari prompt patches, and DPO link export.

### 11. Mitigation Strategies, Inoculation & DPO Dataset Synthesis
- **Bilingual System Prompt Inoculation (`SYSTEM_PROMPT_INOCULATION`)**: Inoculates the target LLM with explicit Devanagari refusal constraints and cross-lingual policy directives, enforcing uniform safety boundaries across English and Nepali without model fine-tuning.
- **Cross-Lingual Translation-Pivot Guardrail (`TRANSLATION_PIVOT`)**: Dynamically normalizes Devanagari user prompts through a cross-lingual vocabulary pivot into English before applying high-coverage safety heuristic validators.
- **Hybrid Defense (`HYBRID`)**: Combines translation-pivot perimeter interception with bilingual prompt inoculation for defense-in-depth.
- **Automated Remediation Advisor & DPO Dataset Export (`/api/v1/analytics/remediation/{id}`)**: Synthesizes identified cross-lingual safety failures into Direct Preference Optimization (DPO) training pairs (`prompt`, `chosen` safe refusal, `rejected` unsafe output) and generates custom Devanagari system prompt patches ready for alignment tuning.
- **Executive Safety Audit & LaTeX Export Endpoint (`/api/v1/analytics/report/{id}/markdown`)**: Exposes Markdown/LaTeX safety audits combining RQ1 parity, RQ2 human-AI agreement, tokenization inflation, and category risk matrices.
- **Empirical Comparative Benchmarking**: Compares baseline vs. inoculated vs. translation-pivot runs via the `/api/v1/analytics/compare` statistical engine.

### 12. Legal, Governance & Regulatory Compliance Framework
- **Official Open-Source License (`LICENSE`)**: Permissive Apache License 2.0 with patent protection and academic attribution clauses.
- **Privacy Policy & Zero-PII Rule (`docs/PRIVACY_POLICY.md`)**: Strict prohibition of real personal data, complete alignment with the **Nepal Privacy Act, 2075 (वैयक्तिक गोपनीयता सम्बन्धी ऐन, २०७५)** and GDPR Articles 16, 17, and 89.
- **Terms of Service & AUP (`docs/TERMS_OF_SERVICE.md`)**: Acceptable Use Policy prohibiting weaponization and malicious cyberattacks, minimum 18+ age restriction, high-risk advice disclaimers, and BYOK third-party billing disclosures.
- **Cookie Statement**: Documented confirmation that Parallax-Eval uses zero persistent tracking, profiling, or third-party advertising cookies.
- **Data Subject Rights (Rectification & Erasure)**: Fully operational `PUT /api/v1/behaviors/{id}` (data correction) and `DELETE /api/v1/behaviors/{id}` (right to erasure cascading through all responses and evaluations).
- **Third-Party API Terms of Use Analysis (`docs/THIRD_PARTY_API_COMPLIANCE.md`)**: Audited compliance with OpenAI, Google Gemini, and Azure OpenAI terms, including rate pacing and key protection.
- **Software Bill of Materials & UI Asset Audit (`docs/LICENSES_AND_ATTRIBUTION.md`)**: 100% permissive dependencies (MIT, BSD-3, Apache-2.0), 0 copyleft GPL/AGPL contamination, and verified open-source Material/Cupertino icons.
- **Regulatory Audit Report (`docs/LEGAL_AUDIT.md`)**: Compliance matrices against EU AI Act (2024/1689), FTC AI Marketing Guidelines, and formal identification of dual-use export control items requiring review by qualified legal counsel.
- **Mobile Legal Hub (`LegalComplianceScreen` & `DataConsentDialog`)**: Interactive 5-tab compliance center and research ethics consent modal in the Flutter client.

### 13. Custom Model & Private / Local Endpoint Evaluation (Ollama & vLLM BYOM)
- **Bring-Your-Own-Model (BYOM)**: Benchmark any arbitrary model tag (e.g., `llama3.2:3b`, `qwen2.5:7b`, `mistral`, fine-tuned checkpoints `ft:...`, `gemini-2.5-pro`, `o3-mini`) directly from the mobile UI or REST API.
- **Local & Private Endpoints (Zero-Cloud Fees)**: Direct integration with locally hosted Ollama (`http://localhost:11434/v1`), vLLM (`http://localhost:8000/v1`), OpenRouter, or private enterprise gateways via standard OpenAI-compatible REST schemas.
- **Local Zero-Cost Awareness**: Automatically recognizes `localhost`, `127.0.0.1`, and local model tags to calculate inference cost at $0.00, keeping financial accounting clean.
- **Independent Target & Judge Routing**: Target models can run on local Ollama while Judge/Critic models run concurrently on Google Gemini Free Tier or OpenAI, providing flexible, cost-effective cross-validation.

---

## Skills-to-Evidence Matrix

| Targeted Role Capability | Project Feature Implemented | Code File / Artifact Link | Concrete Evidence |
| :--- | :--- | :--- | :--- |
| **LLM & Generative AI** | Multi-model provider gateway with token/cost tracking & Azure support | [`llm_gateway.py`](backend/app/services/llm_gateway.py) | Cost estimation per 1k tokens, `AzureOpenAIProvider`, `MockLLMProvider`, unit tests in `test_llm_gateway_and_tracing.py` |
| **Agentic AI Systems** | Multi-agent Judge–Critic–Arbiter state machine & adaptive red-teamer | [`langgraph_eval.py`](backend/app/services/langgraph_eval.py), [`red_team_engine.py`](backend/app/services/red_team_engine.py) | Cyclical LangGraph graph, state transition routing, arbiter reconciliation, unit tests in `test_langgraph_workflow.py` |
| **AI Safety & Mitigation** | Bilingual inoculation, translation-pivot guardrail & DPO synthesis | [`guardrails.py`](backend/app/services/guardrails.py), [`analytics_service.py`](backend/app/services/analytics_service.py) | Inoculated system prompts, `TranslationPivotGuardrail`, DPO pair generator, unit tests in `test_defenses_and_remediation.py` |
| **Vector DBs & RAG** | Cross-lingual policy retrieval & exemplar grounding | [`retrieval/`](backend/app/services/retrieval/) | Zero-dependency subword n-gram vector store, Precision@K, Recall@K, MRR evaluation, unit tests in `test_retrieval_and_rag.py` |
| **REST APIs** | Production FastAPI backend with OpenAPI specs & Pydantic validation | [`backend/app/api/v1/`](backend/app/api/v1/) | Async endpoints for `/experiments`, `/retrieval`, `/analytics/compare`, `/analytics/remediation`, `/metrics`, and `/health` |
| **Controlled Experimentation** | Paired McNemar hypothesis testing & 95% bootstrap confidence intervals | [`analytics_service.py`](backend/app/services/analytics_service.py) | Edwards' continuity-corrected chi-square, exact p-values, 1,000-resample bootstrap CIs, unit tests in `test_statistical_significance.py` |
| **Observability & Telemetry** | Distributed span tracing, request ID tracking, and operational metrics | [`tracing.py`](backend/app/services/tracing.py), [`metrics.py`](backend/app/api/v1/metrics.py) | OpenTelemetry-compatible `ExecutionTrace`, sub-step span timing, token counts, error tagging, and `/api/v1/metrics` |
| **Cloud-Native & Docker** | Multi-container production deployment | [`docker-compose.yml`](docker-compose.yml), [`Dockerfile`](backend/Dockerfile) | Healthcheck probes, non-root execution, environment separation, zero-cloud local testing |
| **Developer Tools & CI/CD** | Unified CLI for dataset verification and automated safety gate | [`cli.py`](backend/app/cli.py), [`.github/workflows/ci.yml`](.github/workflows/ci.yml) | `python -m app.cli verify-dataset`, `compare` command exiting with code 1 on regression in GitHub Actions |
| **Enterprise Architecture** | Architecture Decision Records & Threat Modeling | [`docs/adr/`](docs/adr/), [`docs/THREAT_MODEL.md`](docs/THREAT_MODEL.md) | ADR-001 through ADR-005, STRIDE threat analysis covering cross-lingual jailbreaks and prompt injection |

---

## Quickstart Guide

### 1. Backend Setup & Run

```bash
# Clone repository
git clone https://github.com/Sumitkc74/Parallax-Eval.git
cd Parallax-Eval

# Install backend dependencies
pip install -r backend/requirements.txt

# Run backend with Uvicorn (uses SQLite WAL by default in development)
uvicorn app.main:app --app-dir backend --reload --port 8000
```
Open **http://127.0.0.1:8000/docs** to explore the interactive Swagger/OpenAPI documentation.

### 2. Run with Docker Compose (FastAPI + PostgreSQL 16)

```bash
docker-compose up --build
```

### 3. Developer CLI Commands

```bash
# Verify dataset JSON schema, Devanagari script integrity, and SHA-256 fingerprint
python -m app.cli verify-dataset

# Run automated CI/CD safety gate comparison between baseline and candidate experiments
python -m app.cli compare --baseline-id 1 --candidate-id 2 --max-regression 0.05
```

### 4. Run Automated Tests

```bash
# Run full backend pytest suite (57 unit, integration, and RAG tests)
python -m pytest backend/tests/ -v

# Run Flutter mobile client tests and linter
cd mobile
flutter test
flutter analyze
```

### 5. Run Mobile Client (Flutter)

```bash
cd mobile
flutter pub get
flutter run
```

---

## Project Structure

```
Parallax-Eval/
├── backend/
│   ├── app/
│   │   ├── api/v1/          # REST endpoints (health, behaviors, experiments, retrieval, analytics, redteam, metrics)
│   │   ├── core/            # Config, database engine, logging, custom errors
│   │   ├── models/          # SQLAlchemy ORM models (behaviors, prompts, evaluations, red_team_attempts)
│   │   ├── schemas/         # Pydantic v2 DTO schemas (comparison, experiment, analytics, retrieval)
│   │   ├── services/        # Guardrails, worker supervisor, LangGraph engine, runner, analytics, tracing
│   │   │   └── retrieval/   # Vector store, policy documents, attack exemplars, retrieval service
│   │   ├── seed/            # Benchmark dataset and idempotent seed loader
│   │   ├── cli.py           # Unified developer CLI (verify-dataset, compare)
│   │   └── main.py          # FastAPI application entrypoint with lifespan recovery
│   ├── tests/               # 57 passing pytest unit, integration, and RAG tests
│   ├── Dockerfile
│   └── requirements.txt
├── mobile/                  # Flutter Mobile Client
│   ├── lib/
│   │   ├── models/          # Dart data models (Experiment, Analytics, Response)
│   │   ├── screens/         # Dashboard, detail, comparison, review, and red-team screens
│   │   ├── services/        # REST API HTTP client
│   │   └── main.dart
│   ├── pubspec.yaml
│   └── test/
├── docs/
│   ├── adr/                 # Architecture Decision Records (ADR-001 through ADR-005)
│   ├── THREAT_MODEL.md      # Formal STRIDE threat model
│   ├── ARCHITECTURE.md      # High-level architecture, component responsibilities & diagrams
│   ├── API.md               # Complete REST API reference, request/response models & tracing
│   ├── DATABASE.md          # PostgreSQL 16 schema, ER diagram, pair_id indexing & cascade rules
│   ├── EVALUATION.md        # Taxonomy rubrics, LangGraph workflow, agreement & confusion matrix
│   ├── DEPLOYMENT.md        # Docker Compose, environment configuration & production hardening
│   └── TESTING.md           # Testing strategy, MockLLMProvider, unit/integration suites & CI/CD
├── scripts/                 # LaTeX export, CLI runner, executive summary generator
├── .github/workflows/       # GitHub Actions CI/CD pipeline
├── docker-compose.yml       # Production container orchestration
├── pytest.ini
└── README.md
```

---

## Documentation Suite

- [Architecture & Design (`ARCHITECTURE.md`)](docs/ARCHITECTURE.md)
- [Architecture Decision Records (`docs/adr/`)](docs/adr/)
- [Threat Model (`docs/THREAT_MODEL.md`)](docs/THREAT_MODEL.md)
- [REST API Reference (`API.md`)](docs/API.md)
- [Database Schema & ERD (`DATABASE.md`)](docs/DATABASE.md)
- [Evaluation Taxonomy & Rubrics (`EVALUATION.md`)](docs/EVALUATION.md)
- [Deployment & Operations (`DEPLOYMENT.md`)](docs/DEPLOYMENT.md)
- [Testing & Quality Assurance (`TESTING.md`)](docs/TESTING.md)
