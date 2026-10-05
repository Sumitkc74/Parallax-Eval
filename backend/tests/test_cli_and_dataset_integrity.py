import json
from pathlib import Path
from unittest.mock import patch, MagicMock
import httpx
import pytest

from app.cli import verify_dataset, compare_experiments


def test_cli_verify_dataset_success():
    exit_code = verify_dataset()
    assert exit_code == 0


def test_dataset_json_structure_and_devanagari_encoding():
    seed_path = Path(__file__).parent.parent / "app" / "seed" / "seed_dataset.json"
    assert seed_path.exists()

    with open(seed_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    assert len(data) == 40
    for item in data:
        assert item["source_id"].startswith("BENCH-")
        assert item["prompt_type"] in ("harmful", "benign")
        assert len(item["english_prompt"]) > 10
        assert len(item["nepali_prompt"]) > 10
        # Check Devanagari range
        has_devanagari = any("\u0900" <= c <= "\u097F" for c in item["nepali_prompt"])
        assert has_devanagari, f"Missing Devanagari characters in {item['source_id']}"


def test_cli_compare_experiments_passed():
    mock_resp_data = {
        "gate_passed": True,
        "gate_verdict": "PASSED - No safety regression detected.",
        "gate_reasons": ["UCR delta within tolerance threshold."],
    }
    mock_http_response = MagicMock(spec=httpx.Response)
    mock_http_response.status_code = 200
    mock_http_response.json.return_value = mock_resp_data
    mock_http_response.raise_for_status = MagicMock()

    with patch("httpx.Client.get", return_value=mock_http_response):
        exit_code = compare_experiments(
            baseline_id="exp-1",
            candidate_id="exp-2",
            tolerance=0.05,
            api_url="http://127.0.0.1:8000/api/v1",
        )
        assert exit_code == 0


def test_cli_compare_experiments_failed():
    mock_resp_data = {
        "gate_passed": False,
        "gate_verdict": "FAILED - Safety regression detected.",
        "gate_reasons": ["Unsafe Compliance Rate increased by 0.15."],
    }
    mock_http_response = MagicMock(spec=httpx.Response)
    mock_http_response.status_code = 200
    mock_http_response.json.return_value = mock_resp_data
    mock_http_response.raise_for_status = MagicMock()

    with patch("httpx.Client.get", return_value=mock_http_response):
        exit_code = compare_experiments(
            baseline_id="exp-1",
            candidate_id="exp-2",
            tolerance=0.05,
            api_url="http://127.0.0.1:8000/api/v1",
        )
        assert exit_code == 1

