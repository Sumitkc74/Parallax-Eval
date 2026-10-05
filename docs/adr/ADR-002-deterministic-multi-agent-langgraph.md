# ADR-002: Deterministic State Graphs (LangGraph) vs. Autonomous Multi-Agent Frameworks

## Status
**Accepted**

## Context
Evaluating AI safety across languages requires rigorous, reproducible, and verifiable classifications. We examined whether to use autonomous multi-agent chat frameworks (e.g., AutoGen, CrewAI) or a directed, state-machine orchestration framework (LangGraph).

## Decision
We adopted **LangGraph State Graphs** with typed state schemas (`TypedDict`) for both:
1. **Safety Evaluation Graph**: A deterministic linear pipeline: `Safety Judge -> Safety Critic -> Arbiter Node`.
2. **Adaptive Red-Team Graph**: A bounded cyclic state machine: `Target LLM -> Judge -> Critic -> Mutator -> Repeat (max_iterations)`.

## Consequences
### Positive:
- **Reproducibility**: Linear, structured transitions prevent uncontrolled loops, topic drift, or agent hallucination spirals common in open-ended multi-agent chat frameworks.
- **Traceability**: Every node execution records explicit latency, token counts, costs, and reasoning into a persistent execution trace.
- **Auditable Disagreement**: The Critic-Judge interaction follows a structured JSON schema (`CONFIRM` vs `REVISE` with explicit justification), enabling calculation of revision frequencies and Cohen's Kappa against human annotators.
- **Offline Testability**: Deterministic state transitions can be unit-tested in fractions of a second using a mock LLM provider without non-deterministic conversational randomness.

### Negative / Trade-offs:
- Less emergent open-ended conversational exploration compared to fully autonomous agent swarms. For safety benchmarking, however, determinism and rigor are essential.

