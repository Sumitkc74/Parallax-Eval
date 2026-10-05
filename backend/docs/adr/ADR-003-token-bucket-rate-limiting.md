# ADR-003: Rate Limiting & Quota Backoff Strategy for Tiered LLM Providers

## Status
**Accepted**

## Context
When running full 80-prompt evaluation runs, each prompt requires up to 3 LLM calls (Target Model, Safety Judge, Safety Critic), yielding up to 240 requests per experiment. Free and tiered cloud LLM endpoints (such as Google AI Studio's Gemini free tier) impose hard rate limits of 15 Requests Per Minute (RPM) with 60-second quota reset windows. Uncontrolled concurrent bursts lead to immediate HTTP `429 Too Many Requests` failures, resulting in dropped evaluations and incomplete benchmark runs.

## Decision
We implemented a **two-tiered pacing and backoff architecture** directly in [`backend/app/services/llm_gateway.py`](file:///e:/Class/GitHub/Parallax-Eval/backend/app/services/llm_gateway.py):
1. **Asynchronous Mutex Pacing (`_wait_for_rate_limit`)**: Outgoing requests acquire an `asyncio.Lock` and enforce a minimum inter-request spacing of $4.1\text{s}$ ($\approx 14.6\text{ RPM}$), guaranteeing steady-state traffic remains strictly beneath Google's 15 RPM ceiling.
2. **Quota Window Replenishment Backoff**: If a 429 response is encountered, the client applies an expanded linear backoff of $12\text{s} \times \text{attempt}$ ($12\text{s}, 24\text{s}, 36\text{s}, 48\text{s}$) over 5 attempts, allowing the provider's 60-second sliding quota window to recover.
3. **Database Error Fallback**: If all retries are exhausted, the runner records an error evaluation with `final_label="Ambiguous"`, recording the exact error message rather than silently dropping the record.

## Consequences
### Positive:
- Benchmark runs complete with 100% prompt coverage without encountering dropped prompts or stuck "Pending" states.
- Compatible with zero-cost free-tier keys for researchers and developers.
- Pacing is automatically bypassed for mock providers, paid enterprise OpenAI/Azure tiers, or local vLLM/Ollama deployments.

### Negative / Trade-offs:
- Full evaluation of 80 prompts on the free Gemini tier takes approximately 10 to 12 minutes due to the 4.1s inter-call delay. This is an unavoidable mathematical constraint of a 15 RPM quota.

