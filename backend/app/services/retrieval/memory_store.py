"""
In-Memory Semantic Vector Store with Subword N-Gram and Term Frequency Embeddings.
Provides zero-external-dependency, deterministic cosine similarity search across English and Devanagari scripts.
"""

import math
import re
from collections import Counter
from typing import Dict, List, Optional, Set
from app.services.retrieval.base import BaseVectorStore, Document, SearchResult


def _tokenize_and_ngram(text: str) -> Counter:
    """
    Extracts unified word and character 3-gram/4-gram frequency features.
    Provides robust cross-lingual semantic matching for English and Devanagari.
    """
    cleaned = re.sub(r"[^\w\s]", " ", text.lower())
    words = cleaned.split()
    features = Counter(words)

    # Subword character n-grams to catch morphological variations and Devanagari affixes
    for word in words:
        if len(word) >= 3:
            for i in range(len(word) - 2):
                features[f"char3:{word[i:i+3]}"] += 1
        if len(word) >= 4:
            for i in range(len(word) - 3):
                features[f"char4:{word[i:i+4]}"] += 1

    return features


def _cosine_similarity(vec1: Counter, vec2: Counter) -> float:
    """Computes standard cosine similarity between two feature counters."""
    intersection = set(vec1.keys()) & set(vec2.keys())
    if not intersection:
        return 0.0

    numerator = sum(vec1[k] * vec2[k] for k in intersection)
    sum1 = sum(v ** 2 for v in vec1.values())
    sum2 = sum(v ** 2 for v in vec2.values())

    if sum1 == 0 or sum2 == 0:
        return 0.0

    denominator = math.sqrt(sum1) * math.sqrt(sum2)
    return round(numerator / denominator, 4)


class InMemoryVectorStore(BaseVectorStore):
    """
    In-memory vector store for policy grounding and attack pattern retrieval.
    Zero infrastructure requirements; suitable for offline testing, CI/CD, and local execution.
    """

    def __init__(self):
        self._documents: Dict[str, Document] = {}
        self._vectors: Dict[str, Counter] = {}

    def add_documents(self, documents: List[Document]) -> int:
        count = 0
        for doc in documents:
            self._documents[doc.id] = doc
            self._vectors[doc.id] = _tokenize_and_ngram(doc.content + " " + doc.category)
            count += 1
        return count

    def similarity_search(
        self,
        query: str,
        top_k: int = 3,
        filter_category: Optional[str] = None,
        filter_doc_type: Optional[str] = None,
    ) -> List[SearchResult]:
        if not self._documents or not query.strip():
            return []

        query_vec = _tokenize_and_ngram(query)
        scores: List[SearchResult] = []

        for doc_id, doc in self._documents.items():
            if filter_category and doc.category != filter_category:
                continue
            if filter_doc_type and doc.doc_type != filter_doc_type:
                continue

            doc_vec = self._vectors[doc_id]
            sim = _cosine_similarity(query_vec, doc_vec)
            if sim > 0.0:
                scores.append(SearchResult(document=doc, score=sim))

        # Sort descending by cosine similarity score
        scores.sort(key=lambda x: x.score, reverse=True)
        return scores[:top_k]

    def count(self) -> int:
        return len(self._documents)

