import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_legal_summary(client: AsyncClient):
    """Verifies that the legal summary endpoint returns compliance metadata, cookie disclosure, and disclaimers."""
    resp = await client.get("/api/v1/legal/summary")
    assert resp.status_code == 200, resp.text
    data = resp.json()

    assert data["cookie_consent_required"] is False
    assert "tracking" in data["cookie_policy_statement"].lower()
    assert "18" in data["age_restriction"]
    assert "Apache" in data["license"]
    assert len(data["disclaimers"]) >= 4
    assert any("Nepal Privacy Act" in s for s in data["compliance_standards"])
    assert any("GDPR" in s for s in data["compliance_standards"])


@pytest.mark.asyncio
async def test_consent_info(client: AsyncClient):
    """Verifies that the consent info endpoint details what, why, and where data is collected and user rights."""
    resp = await client.get("/api/v1/legal/consent-info")
    assert resp.status_code == 200, resp.text
    data = resp.json()

    assert len(data["what_data_is_collected"]) >= 4
    assert len(data["why_data_is_collected"]) >= 3
    assert len(data["data_subject_rights"]) >= 4
    assert data["age_limit_years"] == 18
    assert "PII" in data["zero_pii_warning"]


@pytest.mark.asyncio
async def test_legal_documents_endpoints(client: AsyncClient):
    """Verifies that the full legal policy and audit markdown documents are served correctly."""
    endpoints = [
        "/api/v1/legal/privacy-policy",
        "/api/v1/legal/terms-of-service",
        "/api/v1/legal/licenses",
        "/api/v1/legal/third-party-api-compliance",
        "/api/v1/legal/audit-report",
    ]
    for ep in endpoints:
        resp = await client.get(ep)
        assert resp.status_code == 200, f"Endpoint {ep} failed: {resp.text}"
        content = resp.json().get("content", "")
        assert len(content) > 100, f"Expected content in {ep}, got: {content}"


@pytest.mark.asyncio
async def test_right_to_rectification_and_erasure(client: AsyncClient):
    """
    Verifies GDPR/Nepal Privacy Act compliance:
    1. User creates custom prompt pair.
    2. User updates/corrects prompt text (Right to Rectification - PUT).
    3. User permanently deletes behavior and child prompts (Right to Erasure - DELETE).
    """
    # 1. Create custom prompt
    create_payload = {
        "category": "Consumer Protection",
        "prompt_type": "harmful",
        "english_prompt": "Original English prompt for safety evaluation",
        "nepali_prompt": "मूल नेपाली प्रम्प्ट सुरक्षा मूल्याङ्कनको लागि",
        "english_description": "Initial description",
        "source_id": "RECTIFY-ERASE-TEST-01",
    }
    create_resp = await client.post("/api/v1/behaviors/custom", json=create_payload)
    assert create_resp.status_code == 201, create_resp.text
    behavior_id = create_resp.json()["id"]

    # 2. Right to Rectification (PUT)
    update_payload = {
        "category": "Consumer Protection - Corrected",
        "english_prompt": "Corrected English prompt variant",
        "nepali_prompt": "सुधारिएको नेपाली प्रम्प्ट रूपान्तरण",
        "english_description": "Corrected description under user request",
    }
    put_resp = await client.put(f"/api/v1/behaviors/{behavior_id}", json=update_payload)
    assert put_resp.status_code == 200, put_resp.text
    updated_data = put_resp.json()

    assert updated_data["category"] == "Consumer Protection - Corrected"
    assert updated_data["english_description"] == "Corrected description under user request"
    en_p = next(p for p in updated_data["prompts"] if p["language"] == "en")
    ne_p = next(p for p in updated_data["prompts"] if p["language"] == "ne")
    assert en_p["prompt_text"] == "Corrected English prompt variant"
    assert ne_p["prompt_text"] == "सुधारिएको नेपाली प्रम्प्ट रूपान्तरण"

    # 3. Right to Erasure (DELETE)
    del_resp = await client.delete(f"/api/v1/behaviors/{behavior_id}")
    assert del_resp.status_code == 200, del_resp.text
    assert "successfully deleted" in del_resp.json()["message"]

    # 4. Verify permanent deletion (404 Not Found)
    get_resp = await client.get(f"/api/v1/behaviors/{behavior_id}")
    assert get_resp.status_code == 404

