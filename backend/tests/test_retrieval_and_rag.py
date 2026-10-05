import pytest
from httpx import AsyncClient, ASGITransport

from app.main import app
from app.services.retrieval import (
    Document,
    InMemoryVectorStore,
    RetrievalService,
    get_retrieval_service,
)


def test_in_memory_vector_store_indexing_and_similarity():
    store = InMemoryVectorStore()
    docs = [
        Document(
            id="DOC-1",
            content="Advance-fee lottery scams asking for processing fees.",
            category="financial_fraud",
            doc_type="policy",
        ),
        Document(
            id="DOC-2",
            content="Port scanning scripts used for automated network vulnerability probes.",
            category="cyber_security_threat",
            doc_type="policy",
        ),
        Document(
            id="DOC-3",
            content="चिठ्ठा परेको बहानामा अग्रिम शुल्क माग्ने ठगी कार्य।",
            category="financial_fraud",
            doc_type="policy",
            language="ne",
        ),
    ]

    added = store.add_documents(docs)
    assert added == 3
    assert store.count() == 3

    # English query matching DOC-1
    results_en = store.similarity_search("lottery processing fee prize", top_k=1)
    assert len(results_en) > 0
    assert results_en[0].document.id == "DOC-1"
    assert results_en[0].score > 0.0

    # Nepali query matching DOC-3
    results_ne = store.similarity_search("चिठ्ठा ठगी अग्रिम शुल्क", top_k=1)
    assert len(results_ne) > 0
    assert results_ne[0].document.id == "DOC-3"
    assert results_ne[0].score > 0.0


def test_category_and_doc_type_filtering():
    service = get_retrieval_service()
    
    # Query with specific category filter
    fin_results = service.search_policies(query="unauthorized exploit", category="financial_fraud", top_k=5)
    for r in fin_results:
        assert r.document.category == "financial_fraud"
        assert r.document.doc_type == "policy"

    # Query for attack exemplars specifically
    atk_results = service.search_attack_exemplars(query="academic simulation research", top_k=2)
    assert len(atk_results) > 0
    for r in atk_results:
        assert r.document.doc_type == "attack_exemplar"


def test_retrieval_service_evaluation_metrics():
    service = get_retrieval_service()
    metrics = service.evaluate_retrieval(k=3)

    assert metrics["k"] == 3
    assert metrics["queries_evaluated"] > 0
    assert metrics["precision_at_k"] > 0.0
    assert metrics["mrr"] > 0.0
    assert metrics["avg_latency_ms"] >= 0.0
    assert metrics["total_indexed_documents"] >= 10


@pytest.mark.asyncio
async def test_retrieval_api_endpoints():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # 1. Policies endpoint
        resp_pol = await client.get("/api/v1/retrieval/policies")
        assert resp_pol.status_code == 200
        policies = resp_pol.json()
        assert len(policies) >= 8
        assert any(p["category"] == "financial_fraud" for p in policies)

        # 2. Search endpoint
        search_payload = {
            "query": "malware keyboard keystroke logger",
            "category": "malicious_software",
            "top_k": 2,
        }
        resp_search = await client.post("/api/v1/retrieval/search", json=search_payload)
        assert resp_search.status_code == 200
        results = resp_search.json()
        assert len(results) > 0
        assert results[0]["document"]["category"] == "malicious_software"

        # 3. Metrics endpoint
        resp_metrics = await client.get("/api/v1/retrieval/metrics?k=3")
        assert resp_metrics.status_code == 200
        m_data = resp_metrics.json()
        assert m_data["precision_at_k"] > 0.0
        assert m_data["mrr"] > 0.0
        assert m_data["queries_evaluated"] > 0

