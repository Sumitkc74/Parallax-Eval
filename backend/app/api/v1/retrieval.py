"""
Retrieval & Semantic Search REST API Endpoints.
Exposes safety policies, semantic search over benchmark documents, and retrieval evaluation metrics.
"""

from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Query
from pydantic import BaseModel

from app.services.retrieval import get_retrieval_service, Document, SearchResult


router = APIRouter(prefix="/retrieval", tags=["Vector Search & RAG Evaluation"])


class SearchRequest(BaseModel):
    query: str
    category: Optional[str] = None
    doc_type: Optional[str] = None
    top_k: int = 3


class RetrievalMetricsResponse(BaseModel):
    k: int
    queries_evaluated: int
    precision_at_k: float
    mrr: float
    avg_latency_ms: float
    total_indexed_documents: int


@router.get("/policies", response_model=List[Document])
async def list_safety_policies(category: Optional[str] = Query(None, description="Optional category filter")):
    """Retrieves all indexed safety policy documents used for grounding the Multi-Agent Safety Judge."""
    service = get_retrieval_service()
    results = service.search_policies(query="", category=category, top_k=20)
    # If empty query returned empty, return all policies directly
    from app.services.retrieval.policy_documents import CANONICAL_SAFETY_POLICIES
    if category:
        return [p for p in CANONICAL_SAFETY_POLICIES if p.category == category]
    return CANONICAL_SAFETY_POLICIES


@router.post("/search", response_model=List[SearchResult])
async def search_documents(request: SearchRequest):
    """
    Performs semantic vector similarity search over indexed safety policies and attack exemplars.
    Returns ranked documents with cosine similarity scores.
    """
    service = get_retrieval_service()
    if request.doc_type == "attack_exemplar":
        return service.search_attack_exemplars(
            query=request.query,
            category=request.category,
            top_k=request.top_k,
        )
    return service.search_policies(
        query=request.query,
        category=request.category,
        top_k=request.top_k,
    )


@router.get("/metrics", response_model=RetrievalMetricsResponse)
async def evaluate_retrieval_quality(k: int = Query(3, ge=1, le=10, description="Top-K cutoff for evaluation")):
    """
    Evaluates the retrieval pipeline against a ground-truth benchmark suite.
    Computes Precision@K, Mean Reciprocal Rank (MRR), and average retrieval latency in milliseconds.
    """
    service = get_retrieval_service()
    metrics = service.evaluate_retrieval(k=k)
    return RetrievalMetricsResponse(**metrics)

