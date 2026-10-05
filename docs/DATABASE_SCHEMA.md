# Database Schema & Relational Modeling

Parallax-Eval utilizes PostgreSQL (with SQLite compatibility for fast offline unit tests) orchestrated through **SQLAlchemy 2.0** and **Alembic**.

---

## Entity-Relationship Overview

```
 [behaviors] 1 ──── ∞ [prompts] 1 ──── ∞ [model_responses]
                                                  │
                            ┌─────────────────────┴─────────────────────┐
                            │ 1:1                                       │ 1:N
                            ▼                                           ▼
                 [automated_evaluations]                       [human_annotations]
```

---

## Table Definitions

### 1. `behaviors`
Stores the abstract behavior definitions (sourced from safety benchmarks such as JailbreakBench).
- `id` (VARCHAR(36), PK): UUID.
- `source_id` (VARCHAR(50), Unique, Indexed): e.g. `BENCH-01`.
- `category` (VARCHAR(100), Indexed): e.g. `linguistics_syntax`, `cultural_heritage`.
- `prompt_type` (VARCHAR(20), Indexed): `"harmful"` or `"benign"`.
- `english_description` (TEXT): High-level description of behavior intent.
- `created_at` / `updated_at`: UTC timestamps.

### 2. `prompts`
Concrete prompts instantiated for a behavior in a specific natural language.
- `id` (VARCHAR(36), PK): UUID.
- `behavior_id` (VARCHAR(36), FK -> `behaviors.id` ON DELETE CASCADE).
- `language` (VARCHAR(10), Indexed): `"en"` or `"ne"`.
- `prompt_text` (TEXT): Prompt string presented to the model.
- `translation_notes` (TEXT, Nullable): Linguist/reviewer notes.
- `is_validated` (BOOLEAN): Validation flag.

### 3. `experiments`
Evaluation run lifecycle and configuration.
- `id` (VARCHAR(36), PK): UUID.
- `name` (VARCHAR(255)): Human-readable run name.
- `target_model` (VARCHAR(100)): Target LLM (e.g. `gpt-4o-mini`).
- `judge_model` (VARCHAR(100)): Multi-agent evaluator model.
- `status` (VARCHAR(50), Indexed): `PENDING` -> `RUNNING` -> `COMPLETED` / `FAILED`.
- `config` (JSON): Filters, temperature, max tokens.
- `total_prompts` (INTEGER): Total prompt count in run.
- `completed_prompts` (INTEGER): Atomic progress counter.
- `started_at` / `completed_at`: Timestamps.

### 4. `model_responses`
Direct generations captured from the target LLM.
- `id` (VARCHAR(36), PK): UUID.
- `experiment_id` (VARCHAR(36), FK -> `experiments.id` ON DELETE CASCADE).
- `prompt_id` (VARCHAR(36), FK -> `prompts.id` ON DELETE CASCADE).
- `response_text` (TEXT): Model raw output.
- `prompt_tokens`, `completion_tokens`, `latency_ms` (INTEGER).

### 5. `automated_evaluations`
Multi-agent safety classification produced by the LangGraph Judge–Critic workflow.
- `id` (VARCHAR(36), PK): UUID.
- `response_id` (VARCHAR(36), Unique, FK -> `model_responses.id` ON DELETE CASCADE).
- `final_label` (VARCHAR(50), Indexed): Reconciled safety label.
- `confidence_score` (FLOAT): Reconciled confidence.
- `judge_label`, `judge_reasoning` (VARCHAR/TEXT): Judge Agent decision.
- `critic_recommendation` (VARCHAR(50)): `"CONFIRM"` or `"REVISE"`.
- `critic_critique` (TEXT): Critic Agent critique.
- `full_trace` (JSON): Full prompt and response logs from each agent node.

### 6. `human_annotations`
Ground-truth annotations submitted by human reviewers.
- `id` (VARCHAR(36), PK): UUID.
- `response_id` (VARCHAR(36), FK -> `model_responses.id` ON DELETE CASCADE).
- `annotator_id` (VARCHAR(100)): Reviewer identifier.
- `human_label` (VARCHAR(50)): Assigned safety label.
- `notes` (TEXT, Nullable): Human reviewer commentary.

