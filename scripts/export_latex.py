#!/usr/bin/env python3
"""
Research Paper LaTeX Table Exporter for Parallax-Eval.
Generates publication-ready LaTeX tables for RQ1 and RQ2 metrics from an evaluation experiment.

Usage:
  python scripts/export_latex.py --experiment-id <ID> [--api-url http://127.0.0.1:8000/api/v1] [--output-dir reports]
"""

import argparse
import os
import sys
from pathlib import Path
import httpx


def generate_rq1_latex_table(rq1_data: dict) -> str:
    target_model = rq1_data.get("target_model", "Unknown")
    en = rq1_data.get("en_metrics", {})
    ne = rq1_data.get("ne_metrics", {})
    delta = rq1_data.get("cross_lingual_delta", {})

    en_hrr = f"{en.get('harmful_refusal_rate', 0.0) * 100:.1f}\\%"
    ne_hrr = f"{ne.get('harmful_refusal_rate', 0.0) * 100:.1f}\\%"
    d_hrr = f"{delta.get('delta_hrr', 0.0) * 100:+.1f}\\%"

    en_ucr = f"{en.get('unsafe_compliance_rate', 0.0) * 100:.1f}\\%"
    ne_ucr = f"{ne.get('unsafe_compliance_rate', 0.0) * 100:.1f}\\%"
    d_ucr = f"{delta.get('delta_ucr', 0.0) * 100:+.1f}\\%"

    en_bcr = f"{en.get('benign_compliance_rate', 0.0) * 100:.1f}\\%"
    ne_bcr = f"{ne.get('benign_compliance_rate', 0.0) * 100:.1f}\\%"
    d_bcr = f"{delta.get('delta_bcr', 0.0) * 100:+.1f}\\%"

    en_orr = f"{en.get('over_refusal_rate', 0.0) * 100:.1f}\\%"
    ne_orr = f"{ne.get('over_refusal_rate', 0.0) * 100:.1f}\\%"
    d_orr = f"{delta.get('delta_orr', 0.0) * 100:+.1f}\\%"

    return f"""% Table 1: Cross-Lingual Safety Parity (RQ1) - Target: {target_model}
\\begin{{table}}[ht]
\\centering
\\caption{{Cross-Lingual LLM Safety Comparison between English (EN) and Nepali (NE) on {target_model}.}}
\\label{{tab:rq1_cross_lingual_safety}}
\\begin{{tabular}}{{lcccc}}
\\hline
\\textbf{{Safety Metric}} & \\textbf{{English (EN)}} & \\textbf{{Nepali (NE)}} & \\textbf{{Delta ($\\Delta_{\\text{{EN-NE}}}$)}} \\\\
\\hline
Harmful Refusal Rate (HRR) $\\uparrow$       & {en_hrr} & {ne_hrr} & {d_hrr} \\\\
Unsafe Compliance Rate (UCR) $\\downarrow$   & {en_ucr} & {ne_ucr} & {d_ucr} \\\\
Benign Compliance Rate (BCR) $\\uparrow$     & {en_bcr} & {ne_bcr} & {d_bcr} \\\\
Over-Refusal Rate (ORR) $\\downarrow$        & {en_orr} & {ne_orr} & {d_orr} \\\\
\\hline
\\multicolumn{{4}}{{l}}{{\\footnotesize Divergent Behaviors: {rq1_data.get('divergent_behavior_count', 0)} out of {len(rq1_data.get('comparisons', []))}}} \\\\
\\hline
\\end{{tabular}}
\\end{{table}}
"""


def generate_rq2_latex_table(rq2_data: dict) -> str:
    total_evals = rq2_data.get("total_automated_evaluations", 0)
    rev_count = rq2_data.get("critic_revised_count", 0)
    rev_rate = f"{rq2_data.get('critic_revision_rate', 0.0) * 100:.1f}\\%"
    human_ann = rq2_data.get("total_human_annotated", 0)
    raw_agree = f"{rq2_data.get('raw_agreement_rate', 0.0) * 100:.1f}\\%"
    
    kappa_val = rq2_data.get("cohens_kappa")
    kappa_str = f"{kappa_val:.3f}" if kappa_val is not None else "N/A"

    return f"""% Table 2: Multi-Agent Evaluation & Human Agreement (RQ2)
\\begin{{table}}[ht]
\\centering
\\caption{{Multi-Agent Judge--Critic Reliability and Agreement with Human Ground Truth.}}
\\label{{tab:rq2_multi_agent_reliability}}
\\begin{{tabular}}{{lc}}
\\hline
\\textbf{{Evaluation Metric}} & \\textbf{{Value}} \\\\
\\hline
Total Automated Evaluations                & {total_evals} \\\\
Critic Revisions                           & {rev_count} ({rev_rate}) \\\\
Human-Annotated Subsample                  & {human_ann} \\\\
Raw Multi-Agent vs. Human Agreement Rate   & {raw_agree} \\\\
Cohen's Kappa ($\\kappa$) Inter-Rater Score & {kappa_str} \\\\
\\hline
\\end{{tabular}}
\\end{{table}}
"""


def main():
    parser = argparse.ArgumentParser(description="Export Parallax-Eval experiment metrics to LaTeX tables.")
    parser.add_argument("--experiment-id", required=True, help="Target experiment UUID")
    parser.add_argument("--api-url", default="http://127.0.0.1:8000/api/v1", help="Base REST API URL")
    parser.add_argument("--output-dir", default="reports", help="Directory to save generated .tex files")
    args = parser.parse_args()

    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    print(f"Fetching analytics for experiment {args.experiment_id} from {args.api_url}...")
    with httpx.Client(timeout=15.0) as client:
        rq1_resp = client.get(f"{args.api_url}/analytics/rq1/{args.experiment_id}")
        if rq1_resp.status_code != 200:
            print(f"Error fetching RQ1 analytics: {rq1_resp.status_code} - {rq1_resp.text}")
            sys.exit(1)
        rq1_data = rq1_resp.json()

        rq2_resp = client.get(f"{args.api_url}/analytics/rq2/{args.experiment_id}")
        if rq2_resp.status_code != 200:
            print(f"Error fetching RQ2 analytics: {rq2_resp.status_code} - {rq2_resp.text}")
            sys.exit(1)
        rq2_data = rq2_resp.json()

    rq1_tex = generate_rq1_latex_table(rq1_data)
    rq2_tex = generate_rq2_latex_table(rq2_data)

    rq1_file = out_dir / "rq1_cross_lingual_table.tex"
    rq2_file = out_dir / "rq2_judge_critic_table.tex"

    with open(rq1_file, "w", encoding="utf-8") as f:
        f.write(rq1_tex)
    with open(rq2_file, "w", encoding="utf-8") as f:
        f.write(rq2_tex)

    print(f"Successfully generated:")
    print(f"  - {rq1_file}")
    print(f"  - {rq2_file}")


if __name__ == "__main__":
    main()

