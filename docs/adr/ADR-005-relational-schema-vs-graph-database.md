# ADR-005: Relational Schema vs. Graph Database for Benchmark Lineage

## Status
**Accepted**

## Context
We evaluated whether to introduce a dedicated Graph Database (such as Neo4j) to represent the lineage between Behaviors, Prompts, Languages, Model Responses, Evaluations, Red-Team Attempts, and Human Annotations.

## Decision
We decided **against** introducing a Graph Database and maintained an indexed **Relational Schema** in SQLAlchemy 2.0 (PostgreSQL / SQLite WAL):
```
Behavior (1) ───< Prompt (N) ───< ModelResponse (N) ───< AutomatedEvaluation (1)
                                        │
                                        ├───< RedTeamAttempt (N)
                                        └───< HumanAnnotation (N)
```

## Consequences
### Positive:
- **No Extra Infrastructure**: Graph databases require dedicated runtime containers, JVM resources, and specialized query languages (Cypher).
- **Sub-Millisecond Joins**: For the benchmark scale (80 prompts per experiment), standard B-tree indexed foreign keys in PostgreSQL and SQLite execute complete joins in less than 5ms.
- **Relational Integrity**: Foreign key constraints enforce strict referential integrity (e.g., cascade deletions when an experiment is removed).
- **Statistical Analytics**: Calculating cross-lingual aggregations, confusion matrices, and contingency tables is substantially more efficient in SQL and NumPy/Python than graph traversals.

### Negative / Trade-offs:
- Graph visualization requires frontend conversion (which our Flutter UI handles directly in the RQ1 comparison and regression gate screens).

