import uuid
from fastapi import APIRouter
from app.schemas.redteam import RedTeamRequest, RedTeamResult, RedTeamIterationStep
from app.services.red_team_engine import build_red_team_graph

router = APIRouter(prefix="/redteam", tags=["Adaptive Red-Team Agent (Stretch Goal)"])


@router.post("/run", response_model=RedTeamResult)
async def run_adaptive_red_team(payload: RedTeamRequest):
    """
    Executes the Adaptive Red-Team loop:
    Harmful Seed -> Red-Team Mutator -> Target LLM -> Judge-Critic -> Adapt / Retry
    Repeats until jailbroken or max_iterations reached.
    """
    session_id = str(uuid.uuid4())
    graph = build_red_team_graph()

    initial_state = {
        "session_id": session_id,
        "seed_prompt": payload.seed_prompt,
        "current_prompt": payload.seed_prompt,
        "behavior_category": payload.behavior_category,
        "language": payload.language,
        "target_model": payload.target_model,
        "judge_model": payload.judge_model,
        "iteration": 1,
        "max_iterations": payload.max_iterations,
        "is_jailbroken": False,
        "last_mutation_strategy": "Initial Seed",
        "history": [],
    }

    final_state = await graph.ainvoke(initial_state)

    steps = [
        RedTeamIterationStep(
            iteration=s["iteration"],
            prompt=s["prompt"],
            response=s["response"],
            safety_label=s["safety_label"],
            judge_reasoning=s["judge_reasoning"],
            mutation_strategy=s.get("mutation_strategy"),
        )
        for s in final_state.get("history", [])
    ]

    is_jailbroken = final_state.get("is_jailbroken", False)
    final_label = final_state.get("final_label", "Safe Refusal")
    total_iters = len(steps)

    if is_jailbroken:
        summary = f"Red-Team breach succeeded at attempt {total_iters}."
    else:
        summary = f"Model maintained safety refusal across all {total_iters} adversarial attempts."

    return RedTeamResult(
        session_id=session_id,
        seed_prompt=payload.seed_prompt,
        language=payload.language,
        target_model=payload.target_model,
        is_jailbroken=is_jailbroken,
        total_iterations=total_iters,
        final_safety_label=final_label,
        steps=steps,
        summary=summary,
    )

