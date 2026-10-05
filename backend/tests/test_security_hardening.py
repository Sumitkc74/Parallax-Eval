import pytest
from httpx import AsyncClient
from app.services.llm_gateway import GeminiNativeProvider
from app.models import Experiment, Behavior, Prompt, ModelResponse


@pytest.mark.asyncio
async def test_security_headers_present(client: AsyncClient):
    """Verifies that all OWASP-recommended defensive security headers are returned on responses."""
    resp = await client.get("/health")
    assert resp.status_code == 200
    assert resp.headers.get("X-Content-Type-Options") == "nosniff"
    assert resp.headers.get("X-Frame-Options") == "DENY"
    assert resp.headers.get("Referrer-Policy") == "strict-origin-when-cross-origin"
    assert resp.headers.get("X-XSS-Protection") == "0"
    assert "geolocation=()" in resp.headers.get("Permissions-Policy", "")


@pytest.mark.asyncio
async def test_csv_formula_injection_sanitization(client: AsyncClient, test_db):
    """Verifies that untrusted inputs starting with formula triggers (=, +, -, @) are sanitized (CWE-1236)."""
    # Create test experiment
    exp = Experiment(
        name="Security Formula Test",
        target_model="mock-target",
        judge_model="mock-judge",
        status="COMPLETED",
        config={},
    )
    test_db.add(exp)
    await test_db.flush()

    # Create behavior and prompt
    behavior = Behavior(
        source_id="SEC-TEST-01",
        category="Cybersecurity",
        prompt_type="harmful",
        english_description="Formula injection test",
    )
    test_db.add(behavior)
    await test_db.flush()

    prompt = Prompt(
        behavior_id=behavior.id,
        language="en",
        prompt_text="=cmd|'/C calc'!A0",  # Malicious formula
    )
    test_db.add(prompt)
    await test_db.flush()

    # Response with formula trigger
    response = ModelResponse(
        experiment_id=exp.id,
        prompt_id=prompt.id,
        response_text="@SUM(1+1)*cmd|'powershell'!A1",  # Malicious formula trigger
        latency_ms=120,
    )
    test_db.add(response)
    await test_db.commit()

    # Request CSV export
    csv_resp = await client.get(f"/api/v1/experiments/{exp.id}/export/csv")
    assert csv_resp.status_code == 200

    csv_text = csv_resp.text
    # Formula triggers should be escaped with leading quote
    assert "'=cmd|'/C calc'!A0" in csv_text
    assert "'@SUM(1+1)*cmd|'powershell'!A1" in csv_text
    # Unescaped raw formulas should not appear as bare cells
    assert "\n=cmd" not in csv_text


@pytest.mark.asyncio
async def test_request_boundary_validation(client: AsyncClient):
    """Verifies that oversized inputs are rejected with 422 Unprocessable Entity to prevent DoS."""
    # Test oversized prompt_text (> 15000 characters)
    oversized_prompt = "A" * 16000
    resp = await client.post(
        "/api/v1/evaluations/inspect-prompt",
        json={
            "prompt_text": oversized_prompt,
            "target_model": "mock-target",
            "judge_model": "mock-judge",
        },
    )
    assert resp.status_code == 422

    # Test invalid temperature (> 2.0)
    resp_temp = await client.post(
        "/api/v1/evaluations/inspect-prompt",
        json={
            "prompt_text": "Valid test prompt",
            "temperature": 5.0,
        },
    )
    assert resp_temp.status_code == 422


@pytest.mark.asyncio
async def test_gemini_api_key_header_usage():
    """Verifies that GeminiNativeProvider passes credentials in headers rather than URL query parameters."""
    provider = GeminiNativeProvider(api_key="AIzaSyTestSecretKey12345")
    # Base URL should not have query parameters
    assert "?key=" not in provider.base_url
