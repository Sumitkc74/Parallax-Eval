import pytest
from httpx import AsyncClient, Response
from app.services.llm_gateway import (
    calculate_token_cost,
    OpenAILikeProvider,
    DynamicLLMProvider,
    get_llm_provider,
    MockLLMProvider,
)
from app.schemas.experiment import ExperimentCreate


def test_calculate_token_cost_local_and_custom():
    """Verify local models (Ollama, localhost) have $0.00 cost, while unknown custom cloud models have safe fallback."""
    # Local ollama model
    assert calculate_token_cost("ollama/llama3.2:3b", 1000, 500) == 0.0
    assert calculate_token_cost("my-local-model", 1000, 500) == 0.0
    assert calculate_token_cost("custom-model", 1000, 500, is_local=True) == 0.0
    # Custom remote model
    cost = calculate_token_cost("custom-finetuned-nepali", 1000, 500, is_local=False)
    assert cost > 0.0


@pytest.mark.asyncio
async def test_dynamic_llm_provider_custom_routing(monkeypatch):
    """Verify DynamicLLMProvider directs custom models to custom endpoint."""
    provider = DynamicLLMProvider(
        custom_base_url="http://localhost:11434/v1",
        custom_api_key="sk-test-key",
    )
    assert provider.custom_provider is not None
    assert provider.custom_provider.base_url == "http://localhost:11434/v1"
    assert provider.custom_provider.is_local is True

    import httpx
    # Mock httpx post on the custom provider
    called_urls = []
    async def mock_post(self, url, *args, **kwargs):
        called_urls.append(url)
        req = httpx.Request("POST", url)
        return Response(
            200,
            json={
                "choices": [{"message": {"content": "Custom model local output in Nepali"}}],
                "usage": {"prompt_tokens": 10, "completion_tokens": 8},
            },
            request=req,
        )

    monkeypatch.setattr(httpx.AsyncClient, "post", mock_post)

    resp = await provider.generate(
        prompt="नमस्ते, कम्प्युटर कसरी काम गर्छ?",
        model="llama3.2:3b",
    )
    assert resp.text == "Custom model local output in Nepali"
    assert resp.cost_usd == 0.0  # Local endpoint cost is 0.0
    assert any("localhost:11434" in u for u in called_urls)


@pytest.mark.asyncio
async def test_api_create_custom_model_experiment(client: AsyncClient, test_db):
    """Test creating and running an experiment with custom model name and custom base URL."""
    payload = {
        "name": "Custom Ollama Llama 3.2 Evaluation",
        "target_model": "llama3.2:3b",
        "judge_model": "mock-judge",
        "languages": ["ne"],
        "prompt_types": ["benign"],
        "custom_base_url": "http://localhost:11434/v1",
        "custom_api_key": "ollama",
    }

    create_resp = await client.post("/api/v1/experiments", json=payload)
    assert create_resp.status_code == 201
    exp_data = create_resp.json()
    exp_id = exp_data["id"]

    assert exp_data["target_model"] == "llama3.2:3b"
    assert exp_data["config"]["custom_base_url"] == "http://localhost:11434/v1"
    assert exp_data["config"]["custom_api_key"] == "ollama"

    # Verify experiment execution completes
    get_resp = await client.get(f"/api/v1/experiments/{exp_id}")
    assert get_resp.status_code == 200
    updated_exp = get_resp.json()
    assert updated_exp["status"] == "COMPLETED"
    assert updated_exp["completed_prompts"] > 0

    # Clean up
    del_resp = await client.delete(f"/api/v1/experiments/{exp_id}")
    assert del_resp.status_code == 200
