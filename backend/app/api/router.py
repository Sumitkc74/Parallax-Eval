from fastapi import APIRouter
from app.api.v1 import (
    health,
    behaviors,
    experiments,
    evaluations,
    annotations,
    analytics,
    redteam,
    metrics,
    retrieval,
    legal,
)

api_v1_router = APIRouter()

api_v1_router.include_router(health.router)
api_v1_router.include_router(behaviors.router)
api_v1_router.include_router(experiments.router)
api_v1_router.include_router(evaluations.router)
api_v1_router.include_router(annotations.router)
api_v1_router.include_router(analytics.router)
api_v1_router.include_router(redteam.router)
api_v1_router.include_router(metrics.router)
api_v1_router.include_router(retrieval.router)
api_v1_router.include_router(legal.router)


