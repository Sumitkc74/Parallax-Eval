"""
Abstract Vector Store and Retrieval Interfaces for Grounded AI Safety Audits.
"""

from abc import ABC, abstractmethod
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class Document(BaseModel):
    id: str
    content: str
    category: str
    doc_type: str = "policy"  # "policy", "attack_exemplar", "guideline"
    language: str = "all"     # "en", "ne", "all"
    metadata: Dict[str, Any] = Field(default_factory=dict)


class SearchResult(BaseModel):
    document: Document
    score: float  # Cosine similarity score between 0.0 and 1.0


class BaseVectorStore(ABC):
    """Abstract vector store interface supporting dense or semantic sparse retrieval."""

    @abstractmethod
    def add_documents(self, documents: List[Document]) -> int:
        """Adds documents to the index. Returns count of added documents."""
        pass

    @abstractmethod
    def similarity_search(
        self,
        query: str,
        top_k: int = 3,
        filter_category: Optional[str] = None,
        filter_doc_type: Optional[str] = None,
    ) -> List[SearchResult]:
        """Searches for top-K most semantically similar documents."""
        pass

    @abstractmethod
    def count(self) -> int:
        """Returns total documents in index."""
        pass

