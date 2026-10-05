from typing import Any, Dict, Optional
import time
from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.errors import ResourceNotFoundException
from app.models import AutomatedEvaluation
from app.schemas.evaluation import EvaluationRead
from app.services.langgraph_eval import build_evaluation_graph
from app.services.guardrails import get_guardrail_pipeline, BILINGUAL_INOCULATION_SYSTEM_PROMPT
from app.services.llm_gateway import get_llm_provider

router = APIRouter(prefix="/evaluations", tags=["Evaluations"])


class SingleEvaluationRequest(BaseModel):
    prompt_text: str = Field(..., min_length=1, max_length=15000, description="Input user prompt text")
    target_response: str = Field(..., min_length=1, max_length=30000, description="Target LLM completion to evaluate")
    language: str = Field(default="en", max_length=10)
    prompt_type: str = Field(default="harmful", max_length=20)
    behavior_category: str = Field(default="General", max_length=100)
    judge_model: str = Field(default="gpt-4o-mini", max_length=100)


class PromptInspectionRequest(BaseModel):
    prompt_text: str = Field(..., min_length=1, max_length=15000, description="Prompt text to inspect and evaluate")
    language: Optional[str] = Field(default=None, max_length=10)
    target_model: str = Field(default="gemini-1.5-flash", max_length=100)
    judge_model: str = Field(default="gemini-1.5-flash", max_length=100)
    prompt_type: str = Field(default="harmful", max_length=20)
    behavior_category: str = Field(default="General", max_length=100)
    guardrail_enabled: bool = True
    defense_strategy: str = Field(default="NONE", max_length=50)
    temperature: float = Field(default=0.0, ge=0.0, le=2.0)
    max_tokens: int = Field(default=1024, ge=1, le=4096)


@router.get("/response/{response_id}", response_model=EvaluationRead)
async def get_evaluation_by_response(response_id: str, db: AsyncSession = Depends(get_db)):
    stmt = select(AutomatedEvaluation).where(AutomatedEvaluation.response_id == response_id)
    result = await db.execute(stmt)
    evaluation = result.scalar_one_or_none()
    if not evaluation:
        raise ResourceNotFoundException("Evaluation for response", response_id)
    return evaluation


@router.post("/evaluate-single")
async def evaluate_single_interaction(payload: SingleEvaluationRequest):
    """Directly invokes the LangGraph Judge–Critic workflow on arbitrary prompt and response text."""
    graph = build_evaluation_graph()
    initial_state = {
        "prompt_text": payload.prompt_text,
        "language": payload.language,
        "prompt_type": payload.prompt_type,
        "behavior_category": payload.behavior_category,
        "target_response": payload.target_response,
        "judge_model": payload.judge_model,
    }
    result = await graph.ainvoke(initial_state)
    return {
        "final_label": result.get("final_label"),
        "confidence_score": result.get("final_confidence"),
        "judge_label": result.get("judge_label"),
        "judge_reasoning": result.get("judge_reasoning"),
        "critic_recommendation": result.get("critic_recommendation"),
        "critic_critique": result.get("critic_critique"),
        "reconciliation_notes": result.get("reconciliation_notes"),
        "trace": result.get("trace"),
    }


@router.post("/inspect-prompt")
async def inspect_client_prompt(payload: PromptInspectionRequest):
    """
    Takes an arbitrary prompt submitted by the client, tests guardrails and defenses,
    invokes the target LLM, and evaluates safety using the multi-agent Judge–Critic workflow.
    """
    detected_lang = payload.language
    if not detected_lang:
        has_devanagari = any("\u0900" <= ch <= "\u097F" for ch in payload.prompt_text)
        detected_lang = "ne" if has_devanagari else "en"

    guardrail_intervened = False
    guardrail_details: Optional[Dict[str, Any]] = None
    target_response_text = ""
    latency_ms = 0
    tokens_used = 0

    # 1. Guardrail inspection stage
    if payload.guardrail_enabled:
        pipeline = get_guardrail_pipeline(
            guardrail_type="regex_heuristic",
            defense_strategy=payload.defense_strategy,
        )
        guard_res = await pipeline.check_input(payload.prompt_text, language=detected_lang)
        if guard_res.intervened:
            guardrail_intervened = True
            guardrail_details = {
                "guardrail_name": guard_res.guardrail_name,
                "stage": guard_res.stage,
                "reason": guard_res.reason,
                "metadata": guard_res.metadata,
            }
            target_response_text = guard_res.sanitized_text or (
                "माफ गर्नुहोस्, यो अनुरोध सुरक्षा नीतिको उल्लङ्घन गर्ने भएकाले पूरा गर्न सकिँदैन।"
                if detected_lang == "ne"
                else "I cannot fulfill this request as it violates safety policies."
            )

    # 2. Target LLM Generation stage (if not intercepted at perimeter)
    if not guardrail_intervened:
        system_prompt = None
        if payload.defense_strategy in ["SYSTEM_PROMPT_INOCULATION", "HYBRID"]:
            system_prompt = BILINGUAL_INOCULATION_SYSTEM_PROMPT

        provider = get_llm_provider()
        t0 = time.time()
        llm_res = await provider.generate(
            prompt=payload.prompt_text,
            model=payload.target_model,
            temperature=payload.temperature,
            max_tokens=payload.max_tokens,
            system_prompt=system_prompt,
        )
        target_response_text = llm_res.text
        latency_ms = llm_res.latency_ms or int((time.time() - t0) * 1000)
        tokens_used = llm_res.prompt_tokens + llm_res.completion_tokens

    # 3. LangGraph Multi-Agent Evaluation
    graph = build_evaluation_graph()
    initial_state = {
        "prompt_text": payload.prompt_text,
        "language": detected_lang,
        "prompt_type": payload.prompt_type,
        "behavior_category": payload.behavior_category,
        "target_response": target_response_text,
        "judge_model": payload.judge_model,
    }
    eval_res = await graph.ainvoke(initial_state)

    final_label = eval_res.get("final_label", "Safe Refusal")
    norm_label = final_label.upper().replace(" ", "_")
    is_safe = norm_label in ["SAFE_REFUSAL", "APPROPRIATE_COMPLIANCE", "BENIGN_COMPLIANCE"]

    return {
        "prompt_text": payload.prompt_text,
        "detected_language": detected_lang,
        "target_model": payload.target_model,
        "judge_model": payload.judge_model,
        "defense_strategy": payload.defense_strategy,
        "guardrail_enabled": payload.guardrail_enabled,
        "guardrail_intervened": guardrail_intervened,
        "guardrail_details": guardrail_details,
        "target_response": target_response_text,
        "latency_ms": latency_ms,
        "tokens_used": tokens_used,
        "final_label": final_label,
        "is_safe": is_safe,
        "confidence_score": eval_res.get("final_confidence"),
        "judge_label": eval_res.get("judge_label"),
        "judge_reasoning": eval_res.get("judge_reasoning"),
        "critic_recommendation": eval_res.get("critic_recommendation"),
        "critic_critique": eval_res.get("critic_critique"),
        "reconciliation_notes": eval_res.get("reconciliation_notes"),
    }

