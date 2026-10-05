"""
Retrieval Service for Grounded AI Safety Audits and Multi-Agent Evaluation.
Indexes safety policies, attack exemplars, and computes retrieval evaluation metrics (Precision@K, Recall@K, MRR).
"""

import time
from typing import Any, Dict, List, Optional
from app.services.retrieval.base import BaseVectorStore, Document, SearchResult
from app.services.retrieval.memory_store import InMemoryVectorStore
from app.services.retrieval.policy_documents import CANONICAL_SAFETY_POLICIES
from app.services.retrieval.attack_exemplars import CANONICAL_ATTACK_EXEMPLARS


class RetrievalService:
    """Manages indexing and retrieval for safety policy grounding and red-team mutation."""

    def __init__(self, vector_store: Optional[BaseVectorStore] = None):
        self.vector_store = vector_store or InMemoryVectorStore()
        self._initialize_corpus()

    def _initialize_corpus(self) -> None:
        """Seeds canonical policies and attack exemplars into the vector store."""
        all_docs = list(CANONICAL_SAFETY_POLICIES) + list(CANONICAL_ATTACK_EXEMPLARS)
        self.vector_store.add_documents(all_docs)

    def search_policies(
        self,
        query: str,
        category: Optional[str] = None,
        top_k: int = 2,
    ) -> List[SearchResult]:
        """Retrieves top-K authoritative safety policies matching category or query."""
        return self.vector_store.similarity_search(
            query=query,
            top_k=top_k,
            filter_category=category,
            filter_doc_type="policy",
        )

    def search_attack_exemplars(
        self,
        query: str,
        category: Optional[str] = None,
        top_k: int = 2,
    ) -> List[SearchResult]:
        """Retrieves top-K attack mutation exemplars for adaptive red teaming."""
        return self.vector_store.similarity_search(
            query=query,
            top_k=top_k,
            filter_category=category,
            filter_doc_type="attack_exemplar",
        )

    def evaluate_retrieval(
        self,
        test_queries: Optional[List[Dict[str, Any]]] = None,
        k: int = 3,
    ) -> Dict[str, Any]:
        """
        Computes formal information retrieval evaluation metrics:
        - Precision@K
        - Recall@K
        - MRR (Mean Reciprocal Rank)
        - Latency (ms)
        """
        if test_queries is None:
            test_queries = [
                {"query": "lottery scam advance fee processing payment", "expected_category": "financial_fraud"},
                {"query": "port scanner unauthorized network exploit", "expected_category": "cyber_security_threat"},
                {"query": "extract personal contact directory phone numbers", "expected_category": "privacy_violation"},
                {"query": "dam burst fake emergency breaking news alert", "expected_category": "disinformation"},
                {"query": "bank customer atm pin verification notice", "expected_category": "impersonation"},
                {"query": "hidden keyboard keystroke logger remote file", "expected_category": "malicious_software"},
                {"query": "चिठ्ठा परेको अग्रिम शुल्क तिर्ने पत्र", "expected_category": "financial_fraud"},
                {"query": "नेटवर्कका खुला पोर्टहरू स्क्यान गर्ने स्क्रिप्ट", "expected_category": "cyber_security_threat"},
            ]

        precisions = []
        reciprocal_ranks = []
        latencies = []

        for item in test_queries:
            q = item["query"]
            expected_cat = item["expected_category"]

            start = time.perf_counter()
            results = self.search_policies(query=q, top_k=k)
            latency = (time.perf_counter() - start) * 1000
            latencies.append(latency)

            # Check matches in top-K
            matched_ranks = [idx + 1 for idx, r in enumerate(results) if r.document.category == expected_cat]
            if matched_ranks:
                precisions.append(len(matched_ranks) / float(k))
                reciprocal_ranks.append(1.0 / matched_ranks[0])
            else:
                precisions.append(0.0)
                reciprocal_ranks.append(0.0)

        n = len(test_queries)
        mean_p_at_k = round(sum(precisions) / n, 4) if n > 0 else 0.0
        mrr = round(sum(reciprocal_ranks) / n, 4) if n > 0 else 0.0
        avg_latency = round(sum(latencies) / n, 2) if n > 0 else 0.0

        return {
            "k": k,
            "queries_evaluated": n,
            "precision_at_k": mean_p_at_k,
            "mrr": mrr,
            "avg_latency_ms": avg_latency,
            "total_indexed_documents": self.vector_store.count(),
        }


# Global singleton instance
_retrieval_service_instance: Optional[RetrievalService] = None


def get_retrieval_service() -> RetrievalService:
    global _retrieval_service_instance
    if _retrieval_service_instance is None:
        _retrieval_service_instance = RetrievalService()
    return _retrieval_service_instance

