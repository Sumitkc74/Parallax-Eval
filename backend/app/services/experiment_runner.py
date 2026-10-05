import asyncio
from datetime import datetime, timezone
from typing import List, Optional
import uuid
from sqlalchemy import select, update
from sqlalchemy.orm import selectinload

from app.core.config import settings
from app.core.database import async_session_maker
from app.core.logging import logger
from app.models import (
    Experiment,
    Prompt,
    Behavior,
    ModelResponse,
    AutomatedEvaluation,
    RedTeamAttempt,
)
from app.services.llm_gateway import get_llm_provider, BaseLLMProvider, calculate_token_cost
from app.services.langgraph_eval import build_evaluation_graph
from app.services.guardrails import get_guardrail_pipeline, BILINGUAL_INOCULATION_SYSTEM_PROMPT
from app.services.worker_supervisor import supervisor
from app.services.red_team_engine import build_red_team_graph


async def execute_experiment(
    experiment_id: str,
    provider: Optional[BaseLLMProvider] = None,
    session_factory = None,
) -> None:
    """
    Main asynchronous experiment worker with state machine resilience,
    guardrail interceptor evaluation, and adaptive red-team batch support.
    """
    logger.info(f"Starting experiment execution for ID: {experiment_id}")

    sm = session_factory if session_factory is not None else async_session_maker
    db_write_lock = asyncio.Lock()
    eval_graph = build_evaluation_graph(provider=provider) if provider is not None else None
    red_team_graph = build_red_team_graph(provider=provider) if provider is not None else None
    semaphore = asyncio.Semaphore(settings.MAX_CONCURRENT_EVALS)

    # Register cancellation token in supervisor
    cancel_event = await supervisor.register_experiment(experiment_id)

    try:
        async with sm() as session:
            # Load experiment
            stmt = select(Experiment).where(Experiment.id == experiment_id)
            result = await session.execute(stmt)
            experiment = result.scalar_one_or_none()

            if not experiment:
                logger.error(f"Experiment {experiment_id} not found.")
                return

            if experiment.status == "CANCELLED":
                logger.info(f"Experiment {experiment_id} was already marked CANCELLED.")
                return

            experiment.status = "RUNNING"
            experiment.started_at = datetime.now(timezone.utc)
            await session.commit()

            try:
                config = experiment.config or {}
                if provider is None:
                    custom_base_url = config.get("custom_base_url")
                    custom_api_key = config.get("custom_api_key")
                    provider = get_llm_provider(
                        custom_base_url=custom_base_url,
                        custom_api_key=custom_api_key,
                    )
                    eval_graph = build_evaluation_graph(provider=provider)
                    red_team_graph = build_red_team_graph(provider=provider)

                languages = config.get("languages", ["en", "ne"])
                prompt_types = config.get("prompt_types", ["harmful", "benign"])
                behavior_ids = config.get("behavior_ids")
                guardrail_enabled = config.get("guardrail_enabled", False)
                guardrail_type = config.get("guardrail_type", "regex_heuristic")
                eval_mode = config.get("evaluation_mode", "STATIC")
                max_rt_iter = int(config.get("max_red_team_iterations", 3))
                defense_strategy = str(config.get("defense_strategy", "NONE")).upper()

                is_guardrail_active = guardrail_enabled or (defense_strategy in ("TRANSLATION_PIVOT", "HYBRID"))
                guardrail_pipeline = get_guardrail_pipeline(
                    guardrail_type if guardrail_enabled else None,
                    defense_strategy=defense_strategy,
                ) if is_guardrail_active else None

                prompt_stmt = select(Prompt).join(Behavior).options(selectinload(Prompt.behavior))

                if languages:
                    prompt_stmt = prompt_stmt.where(Prompt.language.in_(languages))
                if prompt_types:
                    prompt_stmt = prompt_stmt.where(Behavior.prompt_type.in_(prompt_types))
                if behavior_ids:
                    prompt_stmt = prompt_stmt.where(Behavior.id.in_(behavior_ids))

                prompts_result = await session.execute(prompt_stmt)
                prompts: List[Prompt] = list(prompts_result.scalars().all())

                experiment.total_prompts = len(prompts)
                experiment.completed_prompts = 0
                await session.commit()

                logger.info(f"Experiment {experiment_id}: processing {len(prompts)} prompts. Guardrails: {guardrail_enabled} (Mode: {eval_mode})")

                async def process_single_prompt(prompt: Prompt):
                    if cancel_event.is_set():
                        logger.info(f"Experiment {experiment_id} cancelled; skipping prompt {prompt.id}")
                        return

                    async with semaphore:
                        if cancel_event.is_set():
                            return

                        try:
                            # 1. Guardrail Input Interception Check
                            if guardrail_pipeline:
                                input_check = await guardrail_pipeline.check_input(
                                    prompt=prompt.prompt_text,
                                    language=prompt.language,
                                )
                                if input_check.intervened:
                                    logger.info(f"Prompt {prompt.id} intercepted by input guardrail: {input_check.reason}")
                                    async with db_write_lock:
                                        async with sm() as worker_session:
                                            model_response = ModelResponse(
                                                experiment_id=experiment.id,
                                                prompt_id=prompt.id,
                                                response_text=input_check.sanitized_text or "Prohibited content detected.",
                                                prompt_tokens=len(prompt.prompt_text.split()),
                                                completion_tokens=len((input_check.sanitized_text or "").split()),
                                                latency_ms=1,
                                                guardrail_intervened=True,
                                                guardrail_details={
                                                    "stage": "input",
                                                    "guardrail": input_check.guardrail_name,
                                                    "reason": input_check.reason,
                                                    "metadata": input_check.metadata,
                                                },
                                            )
                                            worker_session.add(model_response)
                                            await worker_session.flush()

                                            auto_eval = AutomatedEvaluation(
                                                response_id=model_response.id,
                                                final_label="Safe Refusal",
                                                confidence_score=1.0,
                                                judge_label="Safe Refusal",
                                                judge_reasoning=f"Intercepted by input guardrail: {input_check.reason}",
                                                critic_recommendation="CONFIRM",
                                                critic_critique="Guardrail enforced safe refusal.",
                                                full_trace={"guardrail_intervened": True},
                                            )
                                            worker_session.add(auto_eval)

                                            await worker_session.execute(
                                                update(Experiment)
                                                .where(Experiment.id == experiment_id)
                                                .values(
                                                    completed_prompts=Experiment.completed_prompts + 1,
                                                    updated_at=datetime.now(timezone.utc),
                                                )
                                            )
                                            await worker_session.commit()
                                    return

                            # 2. Execution depending on mode (Static vs Adaptive Red-Team Batch)
                            red_team_attempts_data = []

                            if eval_mode == "ADAPTIVE_RED_TEAM" and prompt.behavior.prompt_type == "harmful":
                                # Execute multi-round adaptive red-team graph
                                rt_state = {
                                    "session_id": str(uuid.uuid4()),
                                    "seed_prompt": prompt.prompt_text,
                                    "current_prompt": prompt.prompt_text,
                                    "behavior_category": prompt.behavior.category,
                                    "language": prompt.language,
                                    "target_model": experiment.target_model,
                                    "judge_model": experiment.judge_model,
                                    "iteration": 1,
                                    "max_iterations": max_rt_iter,
                                    "history": [],
                                }
                                rt_final = await red_team_graph.ainvoke(rt_state)

                                response_text = rt_final.get("target_response", "")
                                final_label = rt_final.get("final_label", "Ambiguous")
                                confidence = rt_final.get("final_confidence", 1.0)
                                judge_label = rt_final.get("judge_label", final_label)
                                judge_reasoning = rt_final.get("judge_reasoning", "")
                                critic_rec = rt_final.get("critic_recommendation", "CONFIRM")
                                critic_critique = rt_final.get("critic_critique", "")
                                red_team_attempts_data = rt_final.get("history", [])

                                prompt_tokens = len(prompt.prompt_text.split())
                                completion_tokens = len(response_text.split())
                                latency_ms = 100
                                guardrail_intervened = False
                                guardrail_details = None

                            else:
                                # Standard static evaluation
                                target_system_prompt = (
                                    BILINGUAL_INOCULATION_SYSTEM_PROMPT
                                    if defense_strategy in ("SYSTEM_PROMPT_INOCULATION", "HYBRID")
                                    else None
                                )
                                resp = await provider.generate(
                                    prompt=prompt.prompt_text,
                                    model=experiment.target_model,
                                    temperature=float(config.get("temperature", 0.0)),
                                    max_tokens=int(config.get("max_tokens", 1024)),
                                    system_prompt=target_system_prompt,
                                )
                                response_text = resp.text
                                prompt_tokens = resp.prompt_tokens
                                completion_tokens = resp.completion_tokens
                                latency_ms = resp.latency_ms
                                guardrail_intervened = False
                                guardrail_details = None

                                # Check output guardrail if enabled
                                if guardrail_pipeline:
                                    output_check = await guardrail_pipeline.check_output(
                                        prompt=prompt.prompt_text,
                                        response=response_text,
                                        language=prompt.language,
                                    )
                                    if output_check.intervened:
                                        response_text = output_check.sanitized_text or "[Content Filtered]"
                                        guardrail_intervened = True
                                        guardrail_details = {
                                            "stage": "output",
                                            "guardrail": output_check.guardrail_name,
                                            "reason": output_check.reason,
                                            "metadata": output_check.metadata,
                                        }

                                # Run LangGraph Multi-Agent Evaluation with OpenTelemetry-compatible tracing
                                initial_trace = {
                                    "trace_id": f"tr-{uuid.uuid4().hex[:12]}",
                                    "experiment_id": experiment.id,
                                    "prompt_id": prompt.id,
                                    "language": prompt.language,
                                    "spans": [
                                        {
                                            "name": "target_generation",
                                            "duration_ms": latency_ms,
                                            "prompt_tokens": prompt_tokens,
                                            "completion_tokens": completion_tokens,
                                            "total_tokens": prompt_tokens + completion_tokens,
                                            "cost_usd": calculate_token_cost(
                                                experiment.target_model,
                                                prompt_tokens,
                                                completion_tokens,
                                                is_local=bool(
                                                    config.get("custom_base_url")
                                                    and any(h in str(config.get("custom_base_url")).lower() for h in ("localhost", "127.0.0.1", "0.0.0.0", "ollama"))
                                                ),
                                            ),
                                            "model": experiment.target_model,
                                            "status": "ok",
                                        }
                                    ],
                                }
                                initial_state = {
                                    "prompt_text": prompt.prompt_text,
                                    "language": prompt.language,
                                    "prompt_type": prompt.behavior.prompt_type,
                                    "behavior_category": prompt.behavior.category,
                                    "target_response": response_text,
                                    "judge_model": experiment.judge_model,
                                    "use_rag_policy": bool(config.get("use_rag_policy", False)),
                                    "trace": initial_trace,
                                }
                                eval_result = await eval_graph.ainvoke(initial_state)
                                final_label = eval_result.get("final_label", "Ambiguous")
                                confidence = eval_result.get("final_confidence", 1.0)
                                judge_label = eval_result.get("judge_label", "Ambiguous")
                                judge_reasoning = eval_result.get("judge_reasoning", "")
                                critic_rec = eval_result.get("critic_recommendation", "CONFIRM")
                                critic_critique = eval_result.get("critic_critique", "")

                            # 3. Synchronized DB Persistence
                            async with db_write_lock:
                                async with sm() as worker_session:
                                    model_response = ModelResponse(
                                        experiment_id=experiment.id,
                                        prompt_id=prompt.id,
                                        response_text=response_text,
                                        prompt_tokens=prompt_tokens,
                                        completion_tokens=completion_tokens,
                                        latency_ms=latency_ms,
                                        guardrail_intervened=guardrail_intervened,
                                        guardrail_details=guardrail_details,
                                    )
                                    worker_session.add(model_response)
                                    await worker_session.flush()

                                    # Save Red-Team Attempts if any
                                    for att in red_team_attempts_data:
                                        attempt_row = RedTeamAttempt(
                                            response_id=model_response.id,
                                            iteration=att.get("iteration", 1),
                                            prompt_text=att.get("prompt", ""),
                                            response_text=att.get("response", ""),
                                            mutation_strategy=att.get("mutation_strategy", "Initial"),
                                            safety_label=att.get("safety_label", "Ambiguous"),
                                            judge_reasoning=att.get("judge_reasoning"),
                                            is_jailbroken=att.get("safety_label") == "Unsafe Compliance",
                                        )
                                        worker_session.add(attempt_row)

                                    trace_payload = eval_result.get("trace") or {"attempts_count": len(red_team_attempts_data)}
                                    auto_eval = AutomatedEvaluation(
                                        response_id=model_response.id,
                                        final_label=final_label,
                                        confidence_score=confidence,
                                        judge_label=judge_label,
                                        judge_reasoning=judge_reasoning,
                                        critic_recommendation=critic_rec,
                                        critic_critique=critic_critique,
                                        full_trace=trace_payload,
                                    )
                                    worker_session.add(auto_eval)

                                    await worker_session.execute(
                                        update(Experiment)
                                        .where(Experiment.id == experiment_id)
                                        .values(
                                            completed_prompts=Experiment.completed_prompts + 1,
                                            updated_at=datetime.now(timezone.utc),
                                        )
                                    )
                                    await worker_session.commit()

                        except Exception as e:
                            logger.error(f"Error evaluating prompt {prompt.id}: {e}", exc_info=True)
                            # Persist fallback error state so prompt is never left unrecorded or stuck as "Pending"
                            try:
                                async with db_write_lock:
                                    async with sm() as worker_session:
                                        err_response = ModelResponse(
                                            experiment_id=experiment.id,
                                            prompt_id=prompt.id,
                                            response_text=f"[Evaluation Error: {str(e)[:300]}]",
                                            prompt_tokens=0,
                                            completion_tokens=0,
                                            latency_ms=0,
                                            guardrail_intervened=False,
                                            guardrail_details={"error": str(e)},
                                        )
                                        worker_session.add(err_response)
                                        await worker_session.flush()

                                        err_eval = AutomatedEvaluation(
                                            response_id=err_response.id,
                                            final_label="Ambiguous",
                                            confidence_score=0.0,
                                            judge_label="Ambiguous",
                                            judge_reasoning=f"Automated evaluation failed with error: {str(e)[:400]}",
                                            critic_recommendation="CONFIRM",
                                            critic_critique="Evaluation pipeline error",
                                            full_trace={"error": str(e)},
                                        )
                                        worker_session.add(err_eval)

                                        await worker_session.execute(
                                            update(Experiment)
                                            .where(Experiment.id == experiment_id)
                                            .values(
                                                completed_prompts=Experiment.completed_prompts + 1,
                                                updated_at=datetime.now(timezone.utc),
                                            )
                                        )
                                        await worker_session.commit()
                            except Exception as save_err:
                                logger.error(f"Failed to record error state for prompt {prompt.id}: {save_err}", exc_info=True)

                # Process all prompts concurrently with bounded semaphore
                await asyncio.gather(*(process_single_prompt(p) for p in prompts))

                # Mark experiment status according to completion vs cancellation
                actual_count_res = await session.execute(
                    select(Experiment.completed_prompts).where(Experiment.id == experiment_id)
                )
                actual_completed = actual_count_res.scalar() or len(prompts)
                final_status = "CANCELLED" if cancel_event.is_set() else "COMPLETED"

                await session.execute(
                    update(Experiment)
                    .where(Experiment.id == experiment_id)
                    .values(
                        status=final_status,
                        completed_prompts=actual_completed,
                        completed_at=datetime.now(timezone.utc),
                    )
                )
                await session.commit()
                logger.info(f"Experiment {experiment_id} marked as {final_status}.")

            except Exception as exc:
                logger.error(f"Experiment {experiment_id} failed: {exc}", exc_info=True)
                experiment.status = "FAILED"
                experiment.error_message = str(exc)
                experiment.completed_at = datetime.now(timezone.utc)
                await session.commit()

    finally:
        await supervisor.unregister_experiment(experiment_id)
