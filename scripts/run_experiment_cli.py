#!/usr/bin/env python3
"""
CLI Experiment Runner for Parallax-Eval.
Launches an automated evaluation experiment, tracks background progress in real-time,
displays summary metrics, and optionally exports results to CSV and LaTeX tables.

Usage:
  python scripts/run_experiment_cli.py \
    --name "CLI Baseline Run" \
    --target-model gpt-4o-mini \
    --judge-model gpt-4o-mini \
    --languages en ne \
    --prompt-types harmful benign \
    --export-latex \
    --export-csv
"""

import argparse
import sys
import time
from pathlib import Path
import httpx


def main():
    parser = argparse.ArgumentParser(description="Launch and monitor a Parallax-Eval experiment from the CLI.")
    parser.add_argument("--name", default="CLI Automated Evaluation", help="Experiment name")
    parser.add_argument("--target-model", default="gpt-4o-mini", help="Target LLM under test")
    parser.add_argument("--judge-model", default="gpt-4o-mini", help="Judge/Critic LLM model")
    parser.add_argument("--languages", nargs="+", default=["en", "ne"], help="Languages to evaluate (e.g. en ne)")
    parser.add_argument("--prompt-types", nargs="+", default=["harmful", "benign"], help="Prompt types (harmful benign)")
    parser.add_argument("--api-url", default="http://127.0.0.1:8000/api/v1", help="Base REST API URL")
    parser.add_argument("--export-latex", action="store_true", help="Generate publication-ready LaTeX tables upon completion")
    parser.add_argument("--export-csv", action="store_true", help="Download results CSV file upon completion")
    parser.add_argument("--output-dir", default="reports", help="Directory for exported CSV/LaTeX files")

    args = parser.parse_args()
    api_url = args.api_url.rstrip("/")

    # 1. Health check
    print("=" * 70)
    print(" Parallax-Eval: Automated Cross-Lingual Evaluation Runner")
    print("=" * 70)
    print(f"Connecting to backend API at {api_url}...")

    try:
        with httpx.Client(timeout=10.0) as client:
            h_resp = client.get(f"{api_url}/health")
            h_resp.raise_for_status()
            h_data = h_resp.json()
            print(f"✓ Backend connected: v{h_data.get('version')} (Mock LLM: {h_data.get('mock_llm')})")
    except Exception as e:
        print(f"Error connecting to backend at {api_url}: {e}")
        print("Please ensure the backend server is running:")
        print("  uvicorn app.main:app --app-dir backend --port 8000")
        sys.exit(1)

    # 2. Launch experiment
    payload = {
        "name": args.name,
        "target_model": args.target_model,
        "judge_model": args.judge_model,
        "languages": args.languages,
        "prompt_types": args.prompt_types,
    }

    print(f"\nLaunching experiment '{args.name}'...")
    print(f"  Target Model : {args.target_model}")
    print(f"  Judge Model  : {args.judge_model}")
    print(f"  Languages    : {', '.join(args.languages).upper()}")
    print(f"  Prompt Types : {', '.join(args.prompt_types)}")

    with httpx.Client(timeout=30.0) as client:
        create_resp = client.post(f"{api_url}/experiments", json=payload)
        if create_resp.status_code != 201:
            print(f"Failed to create experiment: {create_resp.status_code} - {create_resp.text}")
            sys.exit(1)

        exp = create_resp.json()
        exp_id = exp["id"]
        print(f"\n✓ Experiment initiated with ID: {exp_id}")
        print("Tracking background progress...\n")

        # 3. Poll progress until completion
        while True:
            status_resp = client.get(f"{api_url}/experiments/{exp_id}")
            if status_resp.status_code != 200:
                print(f"Error fetching experiment status: {status_resp.text}")
                break

            status_data = status_resp.json()
            st = status_data["status"]
            comp = status_data.get("completed_prompts", 0)
            total = status_data.get("total_prompts", 0)

            pct = (comp / total * 100) if total > 0 else 0
            bar_len = 30
            filled = int(bar_len * (pct / 100))
            bar = "█" * filled + "░" * (bar_len - filled)

            sys.stdout.write(f"\r  [{bar}] {comp}/{total} prompts ({pct:.0f}%) | Status: {st}   ")
            sys.stdout.flush()

            if st in ("COMPLETED", "FAILED"):
                print()
                break

            time.sleep(1.0)

        if st == "FAILED":
            print(f"\nExperiment failed: {status_data.get('error_message')}")
            sys.exit(1)

        print("\n" + "=" * 70)
        print(" Experiment Completed Successfully!")
        print("=" * 70)

        # 4. Fetch and display RQ1 metrics
        rq1_resp = client.get(f"{api_url}/analytics/rq1/{exp_id}")
        if rq1_resp.status_code == 200:
            rq1 = rq1_resp.json()
            en = rq1.get("en_metrics", {})
            ne = rq1.get("ne_metrics", {})
            delta = rq1.get("cross_lingual_delta", {})

            print("\n[RQ1: Cross-Lingual Safety Parity Summary]")
            print(f"{'Metric':<30} | {'English (EN)':<14} | {'Nepali (NE)':<14} | {'Delta':<10}")
            print("-" * 75)
            print(f"{'Harmful Refusal Rate (HRR)':<30} | {en.get('harmful_refusal_rate',0)*100:>11.1f}% | {ne.get('harmful_refusal_rate',0)*100:>11.1f}% | {delta.get('delta_hrr',0)*100:>+8.1f}%")
            print(f"{'Unsafe Compliance Rate (UCR)':<30} | {en.get('unsafe_compliance_rate',0)*100:>11.1f}% | {ne.get('unsafe_compliance_rate',0)*100:>11.1f}% | {delta.get('delta_ucr',0)*100:>+8.1f}%")
            print(f"{'Benign Compliance Rate (BCR)':<30} | {en.get('benign_compliance_rate',0)*100:>11.1f}% | {ne.get('benign_compliance_rate',0)*100:>11.1f}% | {delta.get('delta_bcr',0)*100:>+8.1f}%")
            print(f"{'Over-Refusal Rate (ORR)':<30} | {en.get('over_refusal_rate',0)*100:>11.1f}% | {ne.get('over_refusal_rate',0)*100:>11.1f}% | {delta.get('delta_orr',0)*100:>+8.1f}%")
            print(f"\nSafety Discrepancies Detected: {rq1.get('divergent_behavior_count', 0)} behaviors exhibit divergent English/Nepali safety profiles.")

        # 5. Fetch and display RQ2 metrics
        rq2_resp = client.get(f"{api_url}/analytics/rq2/{exp_id}")
        if rq2_resp.status_code == 200:
            rq2 = rq2_resp.json()
            print("\n[RQ2: Multi-Agent Reliability Summary]")
            print(f"  Total Automated Evaluations : {rq2.get('total_automated_evaluations')}")
            print(f"  Critic Revisions             : {rq2.get('critic_revised_count')} ({rq2.get('critic_revision_rate', 0)*100:.1f}%)")
            print(f"  Human Annotations            : {rq2.get('total_human_annotated')}")
            if rq2.get("total_human_annotated", 0) > 0:
                print(f"  Raw Agreement Rate           : {rq2.get('raw_agreement_rate', 0)*100:.1f}%")
                print(f"  Cohen's Kappa (κ)            : {rq2.get('cohens_kappa', 'N/A')}")
            else:
                print("  (Annotate responses via Flutter mobile app or /annotations API to calculate Cohen's Kappa)")

        # 6. Optional CSV export
        out_path = Path(args.output_dir)
        out_path.mkdir(parents=True, exist_ok=True)

        if args.export_csv:
            csv_url = f"{api_url}/experiments/{exp_id}/export/csv"
            csv_resp = client.get(csv_url)
            if csv_resp.status_code == 200:
                csv_file = out_path / f"experiment_{exp_id[:8]}_results.csv"
                csv_file.write_text(csv_resp.text, encoding="utf-8")
                print(f"\n✓ Exported results CSV: {csv_file}")

        # 7. Optional LaTeX export
        if args.export_latex:
            from scripts.export_latex import generate_rq1_latex_table, generate_rq2_latex_table
            if rq1_resp.status_code == 200 and rq2_resp.status_code == 200:
                rq1_file = out_path / "rq1_cross_lingual_table.tex"
                rq2_file = out_path / "rq2_judge_critic_table.tex"
                rq1_file.write_text(generate_rq1_latex_table(rq1_resp.json()), encoding="utf-8")
                rq2_file.write_text(generate_rq2_latex_table(rq2_resp.json()), encoding="utf-8")
                print(f"✓ Exported publication-ready LaTeX tables to {out_path}/")

        print("\nEvaluation pipeline complete.")


if __name__ == "__main__":
    main()

