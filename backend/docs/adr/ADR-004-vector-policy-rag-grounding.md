# ADR-004: Vector Policy Grounding (RAG) vs. Static Few-Shot Prompting

## Status
**Accepted**

## Context
Safety evaluation of low-resource languages (e.g., Nepali) poses unique challenges: safety guidelines often vary significantly across legal jurisdictions (e.g., Nepal's Privacy Act 2075 vs GDPR, localized banking terminology like चिठ्ठा scams vs. Western lottery scams). Hardcoding all guidelines into a single prompt blows up context window size, increases token costs, and induces prompt confusion. Conversely, omitting specific guidelines causes the LLM Judge to hallucinate or misjudge localized content.

## Decision
We implemented a **Decoupled Vector Policy Retrieval Service** ([`backend/app/services/retrieval/`](file:///e:/Class/GitHub/Parallax-Eval/backend/app/services/retrieval/)):
1. Grounding documents (canonical policies and cross-lingual attack exemplars) are indexed in a pluggable `BaseVectorStore` (with an in-memory subword n-gram cosine similarity backend for zero-dependency execution).
2. The Safety Judge dynamically retrieves the single most relevant authoritative policy chunk for the specific behavior category and injects it into the prompt.
3. The Adaptive Red-Team mutator retrieves proven attack patterns (academic framing, Devanagari transliteration disguises).
4. The retrieval pipeline is evaluated using standard IR metrics: **Precision@K**, **Recall@K**, and **Mean Reciprocal Rank (MRR)**.

## Consequences
### Positive:
- **Accuracy & Grounding**: The Safety Judge cites specific policy rules (e.g., `POL-FIN-01`, `POL-CYBER-01`) and regulatory authorities in its reasoning.
- **Ablation Support**: Researchers can benchmark `use_rag_policy=True` vs `use_rag_policy=False` to scientifically measure the impact of RAG on Judge accuracy and agreement against human annotators.
- **Zero Overhead**: In-memory vector search adds under 15ms latency and requires no external vector database servers.

### Negative / Trade-offs:
- Slightly increases prompt token length by ~100 tokens per evaluation when enabled.

