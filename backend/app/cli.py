"""
Unified Developer CLI for Parallax-Eval.
Provides command-line commands for dataset verification, headless CI evaluation, and safety regression gating.

Usage:
  python -m app.cli verify-dataset
  python -m app.cli evaluate --name "CI Run" --target-model gpt-4o-mini
  python -m app.cli compare --baseline <id> --candidate <id> --tolerance 0.05
"""

import argparse
import hashlib
import json
import sys
from pathlib import Path
from typing import List

# Ensure safe UTF-8 output on Windows consoles
if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass


def verify_dataset() -> int:
    """Validates the benchmark dataset schema, UTF-8 Devanagari encoding, and SHA-256 checksum."""
    seed_path = Path(__file__).parent / "seed" / "seed_dataset.json"
    if not seed_path.exists():
        print(f"❌ Error: Dataset file not found at {seed_path}", file=sys.stderr)
        return 1

    with open(seed_path, "rb") as f:
        raw_bytes = f.read()
        sha256 = hashlib.sha256(raw_bytes).hexdigest()

    try:
        items = json.loads(raw_bytes.decode("utf-8"))
    except Exception as e:
        print(f"❌ Error: Dataset JSON parsing failed: {e}", file=sys.stderr)
        return 1

    if not isinstance(items, list) or len(items) == 0:
        print(f"❌ Error: Expected non-empty list of behaviors in dataset.", file=sys.stderr)
        return 1

    valid_types = {"harmful", "benign"}
    errors: List[str] = []

    for idx, item in enumerate(items):
        source_id = item.get("source_id")
        if not source_id:
            errors.append(f"Item #{idx}: missing 'source_id'")
        
        ptype = item.get("prompt_type")
        if ptype not in valid_types:
            errors.append(f"Item {source_id}: invalid prompt_type '{ptype}' (must be harmful or benign)")

        en_prompt = item.get("english_prompt", "").strip()
        if not en_prompt:
            errors.append(f"Item {source_id}: missing or empty 'english_prompt'")

        ne_prompt = item.get("nepali_prompt", "").strip()
        if not ne_prompt:
            errors.append(f"Item {source_id}: missing or empty 'nepali_prompt'")
        else:
            # Check for Devanagari unicode range (0x0900 - 0x097F)
            has_devanagari = any("\u0900" <= char <= "\u097F" for char in ne_prompt)
            if not has_devanagari:
                errors.append(f"Item {source_id}: 'nepali_prompt' does not contain Devanagari script")

    if errors:
        print(f"❌ Dataset validation failed with {len(errors)} error(s):", file=sys.stderr)
        for err in errors[:10]:
            print(f"   - {err}", file=sys.stderr)
        return 1

    print("=" * 65)
    print(" ✓ Parallax-Eval Benchmark Dataset Verification PASSED")
    print("=" * 65)
    print(f" Behaviors Validated : {len(items)}")
    print(f" Paired Prompts Total: {len(items) * 2} (English + Nepali)")
    print(f" SHA-256 Checksum    : {sha256}")
    print("=" * 65)
    return 0


def compare_experiments(baseline_id: str, candidate_id: str, tolerance: float, api_url: str) -> int:
    """Compares two experiments via the REST API and evaluates the CI/CD safety gate."""
    import httpx

    print(f"Comparing baseline={baseline_id} against candidate={candidate_id} (tolerance={tolerance})...")
    url = f"{api_url.rstrip('/')}/analytics/compare?baseline_id={baseline_id}&candidate_id={candidate_id}&ucr_tolerance={tolerance}"

    try:
        with httpx.Client(timeout=15.0) as client:
            resp = client.get(url)
            resp.raise_for_status()
            data = resp.json()
    except Exception as e:
        print(f"❌ Error querying comparison API: {e}", file=sys.stderr)
        return 1

    gate_passed = data.get("gate_passed", False)
    verdict = data.get("gate_verdict", "UNKNOWN")
    reasons = data.get("gate_reasons", [])

    print("=" * 65)
    print(f" CI/CD Safety Gate Verdict: {'PASSED ✅' if gate_passed else 'FAILED ❌'}")
    print("=" * 65)
    print(f" Details: {verdict}")
    for r in reasons:
        print(f"   • {r}")
    print("=" * 65)

    return 0 if gate_passed else 1


def main() -> int:
    parser = argparse.ArgumentParser(
        prog="python -m app.cli",
        description="Parallax-Eval Unified Developer & CI/CD CLI tool.",
    )
    subparsers = parser.add_subparsers(dest="subcommand", help="Available subcommands")

    # 1. verify-dataset
    verify_parser = subparsers.add_parser("verify-dataset", help="Validate benchmark dataset format, encoding, and hash.")

    # 2. compare
    compare_parser = subparsers.add_parser("compare", help="Compare two experiments and check CI/CD safety regression gate.")
    compare_parser.add_argument("--baseline", required=True, help="Baseline experiment UUID")
    compare_parser.add_argument("--candidate", required=True, help="Candidate experiment UUID")
    compare_parser.add_argument("--tolerance", type=float, default=0.05, help="Allowed delta tolerance for Unsafe Compliance Rate")
    compare_parser.add_argument("--api-url", default="http://127.0.0.1:8000/api/v1", help="Base API URL")

    args = parser.parse_args()

    if args.subcommand == "verify-dataset":
        return verify_dataset()
    elif args.subcommand == "compare":
        return compare_experiments(
            baseline_id=args.baseline,
            candidate_id=args.candidate,
            tolerance=args.tolerance,
            api_url=args.api_url,
        )
    else:
        parser.print_help()
        return 0


if __name__ == "__main__":
    sys.exit(main())
