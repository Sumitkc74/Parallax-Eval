# Testing Strategy & Quality Assurance — ParallaxLM

## 1. Core Testing Philosophy

Reliability and determinism are paramount in production SDE projects. ParallaxLM enforces the following core testing principles:
1. **100% Offline Testability**: Zero live or paid API calls in CI/CD or local test suites. All LLM calls route through `MockLLMProvider` which returns deterministic outputs.
2. **Hermetic Test Isolation**: Tests run against in-memory SQLite instances (`sqlite+aiosqlite:///:memory:`) with complete schema teardown and fresh seed fixtures per test function.
3. **Dual-Stack Continuous Verification**: Every commit is verified on both backend (Python 3.11 + Pytest) and frontend (Flutter SDK + analyzer + widget tests).

---

## 2. Test Suite Architecture

| Test Module | Coverage Scope | Key Assertions Verified |
|---|---|---|
| `test_api_health.py` | Liveness, readiness, metrics, request tracing | `GET /health`, `GET /ready` (DB ping), `X-Request-ID` injection and echo |
| `test_taxonomy_and_stats.py` | Taxonomy rubrics, confusion matrix, semantic pairs | `GET /behaviors/taxonomy`, rubric validation, accuracy/precision/recall/F1, `pair_id` |
| `test_guardrails.py` | Pre- and post-generation safety interceptors | Keyword blocking, heuristic analysis, pipeline chaining, latency capture |
| `test_langgraph_workflow.py` | Multi-agent evaluation graph | Judge classification, Critic review, Arbiter consensus revision logic |
| `test_worker_supervisor.py` | Lifecycle state machine & cancellation | Zombie task startup recovery, cooperative cancellation via API |
| `test_red_team_engine.py` | Iterative jailbreak evaluation loop | Attack generation, target compliance, multi-turn adaptation |
| `test_comparative_analytics.py`| Regression detection & cross-lingual deltas | Baseline vs. candidate diffs, UCR tolerance safety gates |
| `test_api_experiments.py` | Experiment creation & execution flow | Experiment creation, status polling, result retrieval |

---

## 3. Running Tests Locally

### 3.1 Backend Pytest Execution
```bash
# Run the complete test suite with verbose output
python -m pytest backend/tests/ -v

# Run with test coverage report
python -m pytest backend/tests/ --cov=backend/app --cov-report=term-missing
```

### 3.2 Frontend Flutter Verification
```bash
cd mobile

# Static code analysis (zero warnings allowed)
flutter analyze

# Widget and unit tests
flutter test
```

---

## 4. GitHub Actions CI/CD Pipeline

The automated CI workflow (`.github/workflows/ci.yml`) runs on every push and pull request to `main`:
- **Job 1: backend-tests**: Installs dependencies, sets `USE_MOCK_LLM=true`, runs 36+ Pytest unit and integration tests.
- **Job 2: frontend-tests**: Sets up Flutter, verifies static analysis (`flutter analyze`), and executes Flutter tests.
- **Merge Gate**: Both jobs must pass before code can be merged into production.

