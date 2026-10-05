# API Reference — ParallaxLM REST API

## 1. Overview & Conventions

The ParallaxLM REST API exposes endpoints for experiment orchestration, multi-agent evaluation, taxonomy inspection, human annotations, and research analytics.

- **Base URL**: `http://localhost:8000/api/v1`
- **Request Tracing**: All incoming requests may supply an `X-Request-ID` header. If absent, the API generates a unique UUID. Every response returns `X-Request-ID` in its HTTP response headers.
- **Content Type**: `application/json`

---

## 2. Health & Readiness Probes

### `GET /health` / `GET /api/v1/health`
**Description**: Liveness probe. Verifies that the API server process is alive.
```json
{
  "status": "ok",
  "project": "Parallax-Eval",
  "version": "0.1.0",
  "environment": "development",
  "mock_llm": true
}
```

### `GET /ready` / `GET /api/v1/ready`
**Description**: Readiness probe. Verifies active connection to the database (`SELECT 1`).
- **200 OK**:
  ```json
  {
    "status": "ready",
    "database": "connected",
    "project": "Parallax-Eval",
    "version": "0.1.0",
    "environment": "development"
  }
  ```
- **503 Service Unavailable** (if DB is unreachable):
  ```json
  {
    "status": "unready",
    "database": "disconnected",
    "error": "connection refused"
  }
  ```

---

## 3. Behaviors, Prompts & Taxonomy

### `GET /api/v1/behaviors/taxonomy`
**Description**: Returns the centralized safety classification taxonomy, rubrics, criteria, and boundary conditions.
- **Response**: Map of safety labels (`Safe Refusal`, `Partial Compliance`, `Unsafe Compliance`, `Over-Refusal`, `Appropriate Compliance`, `Ambiguous`) to their definitions.

### `GET /api/v1/behaviors`
**Query Parameters**:
- `prompt_type` (optional): `harmful` | `benign`
- `category` (optional): Filter by benchmark category

### `GET /api/v1/behaviors/{behavior_id}`
**Description**: Returns a behavior and its paired English/Nepali prompts (including `pair_id`).

### `POST /api/v1/behaviors/seed`
**Description**: Idempotent trigger to seed the database from `seed_dataset.json`.

---

## 4. Experiments & Worker Lifecycle

### `POST /api/v1/experiments`
**Request Body**:
```json
{
  "name": "GPT-4o-Mini Cross-Lingual Evaluation",
  "description": "Baseline safety audit comparing EN vs NE",
  "target_model": "gpt-4o-mini",
  "judge_model": "gpt-4o-mini",
  "critic_model": "gpt-4o-mini",
  "temperature": 0.0,
  "max_tokens": 1000,
  "enable_guardrails": false,
  "guardrail_config": {
    "block_keywords": ["exploit", "hack"]
  },
  "prompt_ids": ["uuid-1", "uuid-2"]
}
```
**Response (201 Created)**: Experiment object with status `PENDING`.

### `GET /api/v1/experiments`
**Description**: Lists all historical experiments with current execution status and timestamps.

### `GET /api/v1/experiments/{id}`
**Description**: Returns detailed experiment metadata, progress counters (`total_prompts`, `completed_prompts`), and status.

### `POST /api/v1/experiments/{id}/cancel`
**Description**: Initiates cooperative cancellation for an actively running experiment.
- **Response**: `{"message": "Cancellation requested for experiment <id>."}`

---

## 5. Research Analytics & Regression Testing

### `GET /api/v1/analytics/rq1/{experiment_id}`
**Description**: Computes cross-lingual safety divergence metrics (RQ1):
- `en_metrics`: HRR, UCR, BCR, ORR for English.
- `ne_metrics`: HRR, UCR, BCR, ORR for Nepali.
- `cross_lingual_delta`: $\Delta \text{HRR}$, $\Delta \text{UCR}$, $\Delta \text{ORR}$, $\Delta \text{BCR}$.
- `divergent_behavior_count`: Count of prompts safe in EN but violated in NE.
- `performance_metrics`: Latency inflation ratio and tokenization tax ratio.

### `GET /api/v1/analytics/rq2/{experiment_id}`
**Description**: Multi-agent reliability and agreement metrics (RQ2):
- `critic_revision_rate`: Rate at which the Critic revised the Judge's initial verdict.
- `raw_agreement_rate` & `cohens_kappa`: Automated vs human inter-rater reliability.
- `confusion_matrix`: Overall accuracy, precision, recall, macro-F1, and weighted-F1.

### `GET /api/v1/analytics/compare`
**Query Parameters**:
- `baseline_id` (required): UUID of the baseline experiment.
- `candidate_id` (required): UUID of the candidate experiment.
- `ucr_tolerance` (optional, default `0.0`): Maximum permissible increase in Unsafe Compliance Rate.
**Description**: Side-by-side comparative analysis with prompt-level regression detection.

---

## 6. Adaptive Red-Teaming

### `POST /api/v1/redteam/run`
**Request Body**:
```json
{
  "target_model": "gpt-4o-mini",
  "attacker_model": "gpt-4o-mini",
  "judge_model": "gpt-4o-mini",
  "language": "ne",
  "max_iterations": 3,
  "behavior_id": "uuid-behavior"
}
```

### `GET /api/v1/redteam/history/{session_id}`
**Description**: Retrieves step-by-step red-team attack strategies, target responses, and evaluation verdicts.

---

## 7. Observability & Telemetry

### `GET /api/v1/metrics` / `GET /metrics`
**Description**: Returns in-memory operational metrics:
```json
{
  "status": "healthy",
  "experiments": {
    "total_created": 12,
    "active_running": 0,
    "completed": 11,
    "failed": 1,
    "cancelled": 0
  },
  "evaluations": {
    "total_evaluated": 240,
    "judge_critic_revisions": 14
  },
  "guardrails": {
    "total_intercepted": 8
  }
}
```

