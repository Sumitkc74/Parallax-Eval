"""
OpenTelemetry-compatible Structured Tracing for Multi-Agent LLM Evaluation.
Captures per-prompt span traces, token accounting, model latencies, and estimated USD costs.
"""

import time
import uuid
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class SpanRecord(BaseModel):
    name: str
    duration_ms: int
    prompt_tokens: int = 0
    completion_tokens: int = 0
    total_tokens: int = 0
    cost_usd: float = 0.0
    model: str = ""
    status: str = "ok"  # "ok" or "error"
    attributes: Dict[str, Any] = Field(default_factory=dict)


class ExecutionTrace(BaseModel):
    trace_id: str = Field(default_factory=lambda: f"tr-{uuid.uuid4().hex[:12]}")
    experiment_id: Optional[str] = None
    prompt_id: Optional[str] = None
    language: str = "en"
    total_latency_ms: int = 0
    total_tokens: int = 0
    total_cost_usd: float = 0.0
    spans: List[SpanRecord] = Field(default_factory=list)

    def add_span(
        self,
        name: str,
        duration_ms: int,
        prompt_tokens: int = 0,
        completion_tokens: int = 0,
        cost_usd: float = 0.0,
        model: str = "",
        status: str = "ok",
        attributes: Optional[Dict[str, Any]] = None,
    ) -> SpanRecord:
        span = SpanRecord(
            name=name,
            duration_ms=duration_ms,
            prompt_tokens=prompt_tokens,
            completion_tokens=completion_tokens,
            total_tokens=prompt_tokens + completion_tokens,
            cost_usd=round(cost_usd, 6),
            model=model,
            status=status,
            attributes=attributes or {},
        )
        self.spans.append(span)
        self.total_latency_ms += duration_ms
        self.total_tokens += span.total_tokens
        self.total_cost_usd = round(self.total_cost_usd + cost_usd, 6)
        return span


class SpanTimer:
    """Context manager for timing and recording individual agent/retrieval spans."""

    def __init__(self, trace: ExecutionTrace, span_name: str, model: str = ""):
        self.trace = trace
        self.span_name = span_name
        self.model = model
        self.start_time: float = 0.0

    def __enter__(self):
        self.start_time = time.perf_counter()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        duration_ms = int((time.perf_counter() - self.start_time) * 1000)
        status = "error" if exc_type else "ok"
        attributes = {"error": str(exc_val)} if exc_val else {}
        self.trace.add_span(
            name=self.span_name,
            duration_ms=duration_ms,
            model=self.model,
            status=status,
            attributes=attributes,
        )
        return False

