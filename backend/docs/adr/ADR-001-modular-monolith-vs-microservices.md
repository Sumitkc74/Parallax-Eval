# ADR-001: Modular Monolith vs. Microservices Architecture

## Status
**Accepted**

## Context
Parallax-Eval is an AI evaluation and benchmark platform designed to assess cross-lingual safety divergence between English and Nepali language models across 80 paired prompts and multi-turn red teaming. We evaluated whether to decompose the application into microservices (e.g., separate LLM Gateway Service, Evaluation Service, Storage Service, and Analytics Service) or structure it as a unified modular monolith.

## Decision
We chose a **FastAPI Modular Monolith** with clean domain separation (`app/api/`, `app/services/`, `app/models/`, `app/schemas/`), utilizing Python `asyncio` concurrency, bounded semaphores, and an async database connection pool (SQLite WAL mode for zero-config local development, PostgreSQL with `asyncpg` for Docker/production).

## Consequences
### Positive:
- **Low Operational Overhead**: No distributed networking complexity, service discovery, or RPC serialization overhead.
- **Transactional Consistency**: Relational database transactions allow atomic commits across prompts, responses, evaluations, and telemetry traces.
- **Fast Local Execution & CI/CD**: The entire test suite executes in seconds in memory or locally without launching multiple service containers.
- **Clear Migration Path**: Modules communicate through strict asynchronous interfaces and Pydantic schemas, making it straightforward to extract high-throughput workers if traffic scale dictates.

### Negative / Trade-offs:
- Single deployment unit: Deploying updates requires restarting the API process (mitigated by zero-downtime container rolling restarts in production).

