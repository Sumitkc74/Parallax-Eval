#!/usr/bin/env python3
"""
Executive Research Report Generator for Parallax-Eval.
Generates an academic, publication-ready Markdown report analyzing Cross-Lingual Safety Parity (RQ1),
Multi-Agent Judge-Critic Reliability (RQ2), and Language Tax / Performance Economics.

Usage:
  python scripts/generate_report.py --experiment-id <ID> [--output-file reports/summary.md]
"""

import argparse
import sys
from datetime import datetime, timezone
from pathlib import Path
import httpx


def interpret_cohens_kappa(kappa: float | None) -> str:
    if kappa is None:
        return "Insufficient human annotations to calculate reliability."
    if kappa < 0:
        return f"Poor agreement (κ = {kappa:.3f}) - chance agreement exceeds observed."
    elif kappa <= 0.20:
        return f"Slight agreement (κ = {kappa:.3f}) based on Landis & Koch (1977)."
    elif kappa <= 0.40:
        return f"Fair agreement (κ = {kappa:.3f}) based on Landis & Koch (1977)."
    elif kappa <= 0.60:
        return f"Moderate agreement (κ = {kappa:.3f}) based on Landis & Koch (1977)."
    elif kappa <= 0.80:
        return f"Substantial agreement (κ = {kappa:.3f}) demonstrating robust multi-agent reliability."
    else:
        return f"Near-perfect agreement (κ = {kappa:.3f}) between multi-agent pipeline and human ground truth."


def build_markdown_report(exp: dict, rq1: dict, rq2: dict) -> str:
    now_str = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    exp_id = exp.get("id", "Unknown")
    exp_name = exp.get("name", "Evaluation Run")
    target_model = exp.get("target_model", "Unknown")
    judge_model = exp.get("judge_model", "Unknown")
    completed = exp.get("completed_prompts", 0)
    total = exp.get("total_prompts", 0)

    en = rq1.get("en_metrics", {})
    ne = rq1.get("ne_metrics", {})
    delta = rq1.get("cross_lingual_delta", {})
    perf = rq1.get("performance_metrics", {})
    comparisons = rq1.get("comparisons", [])
    divergent_items = [c for c in comparisons if c.get("is_safety_divergent")]

    en_hrr = f"{en.get('harmful_refusal_rate', 0.0) * 100:.1f}%"
    ne_hrr = f"{ne.get('harmful_refusal_rate', 0.0) * 100:.1f}%"
    d_hrr = f"{delta.get('delta_hrr', 0.0) * 100:+.1f}%"

    en_ucr = f"{en.get('unsafe_compliance_rate', 0.0) * 100:.1f}%"
    ne_ucr = f"{ne.get('unsafe_compliance_rate', 0.0) * 100:.1f}%"
    d_ucr = f"{delta.get('delta_ucr', 0.0) * 100:+.1f}%"

    en_bcr = f"{en.get('benign_compliance_rate', 0.0) * 100:.1f}%"
    ne_bcr = f"{ne.get('benign_compliance_rate', 0.0) * 100:.1f}%"
    d_bcr = f"{delta.get('delta_bcr', 0.0) * 100:+.1f}%"

    en_orr = f"{en.get('over_refusal_rate', 0.0) * 100:.1f}%"
    ne_orr = f"{ne.get('over_refusal_rate', 0.0) * 100:.1f}%"
    d_orr = f"{delta.get('delta_orr', 0.0) * 100:+.1f}%"

    cohen_val = rq2.get("cohens_kappa")
    kappa_interpretation = interpret_cohens_kappa(cohen_val)

    report = f"""# Parallax-Eval Research Report: Cross-Lingual LLM Safety
**Experiment:** {exp_name}  
**Date Generated:** {now_str}  
**Experiment ID:** `{exp_id}`  

---

## 1. Executive Overview

This evaluation report investigates whether **{target_model}** exhibits disparate safety alignment behaviors when identical semantic intents are presented in **English (High-Resource)** versus **Nepali (Low-Resource Devanagari script)**.

The system utilizes an automated **LangGraph Multi-Agent Safety Engine** (Safety Judge Agent $\\to$ Critic Agent $\\to$ Deterministic Arbiter Node) grounded against human expert annotations.

### Key Highlights:
- **Evaluated Prompts:** {completed} of {total} completed.
- **Harmful Refusal Disparity ($\\Delta_{{HRR}}$):** {d_hrr} (EN: {en_hrr} vs. NE: {ne_hrr}).
- **Unsafe Compliance Disparity ($\\Delta_{{UCR}}$):** {d_ucr} (EN: {en_ucr} vs. NE: {ne_ucr}).
- **Identified Safety Divergent Behaviors:** {len(divergent_items)} behavior(s) exhibited significant safety divergence between languages.
- **Language / Tokenization Tax:** Nepali prompts incurred **{perf.get('token_inflation_ratio', 1.0):.2f}×** more sub-word tokens than English.

---

## 2. Research Question 1: Cross-Lingual Safety Parity

| Safety Metric | English (EN) | Nepali (NE) | Delta ($\\Delta_{{\\text{{EN-NE}}}}$) |
| :--- | :---: | :---: | :---: |
| **Harmful Refusal Rate (HRR)** $\\uparrow$ | {en_hrr} | {ne_hrr} | **{d_hrr}** |
| **Unsafe Compliance Rate (UCR)** $\\downarrow$ | {en_ucr} | {ne_ucr} | **{d_ucr}** |
| **Benign Compliance Rate (BCR)** $\\uparrow$ | {en_bcr} | {ne_bcr} | **{d_bcr}** |
| **Over-Refusal Rate (ORR)** $\\downarrow$ | {en_orr} | {ne_orr} | **{d_orr}** |

> **Interpretation:** A positive $\\Delta_{{HRR}}$ indicates that English enjoys higher refusal rates on harmful prompts than Nepali. Conversely, a negative $\\Delta_{{UCR}}$ highlights that the target model complies with hazardous requests more often when queried in Nepali.

---

## 3. Case Studies: Safety Divergent Behaviors
"""

    if not divergent_items:
        report += "\n*No divergent behaviors detected in this experiment run.*\n"
    else:
        for idx, item in enumerate(divergent_items, 1):
            report += f"""
### Case {idx}: {item.get('source_id')} — {item.get('category')} ({item.get('prompt_type').upper()})
- **English Prompt:** *"{item.get('en_prompt')}"*
  - **Verdict:** `{item.get('en_label')}`
- **Nepali Prompt:** *"{item.get('ne_prompt')}"*
  - **Verdict:** `{item.get('ne_label')}`
- **Analysis:** The model demonstrated asymmetric safety guardrails for this query across languages.
"""

    report += f"""
---

## 4. Systems Engineering & "Language Tax" Analytics

In non-Latin scripts such as Devanagari, byte-pair encoding (BPE) tokenizers split complex graphemes into granular bytes, inducing both higher API costs and increased generation latency:

| Metric | English (EN) | Nepali (NE) | Ratio / Total |
| :--- | :---: | :---: | :---: |
| **Total Tokens Consumed** | {perf.get('en_total_tokens', 0):,} | {perf.get('ne_total_tokens', 0):,} | **{perf.get('token_inflation_ratio', 1.0):.2f}× Inflation** |
| **Average Latency (ms)** | {perf.get('en_avg_latency_ms', 0):.0f} ms | {perf.get('ne_avg_latency_ms', 0):.0f} ms | **{perf.get('latency_inflation_ratio', 1.0):.2f}× Latency** |
| **Aggregate Tokens** | — | — | **{perf.get('total_tokens_consumed', 0):,} tokens** |

---

## 5. Research Question 2: Multi-Agent Reliability & Human Agreement

- **Automated Evaluations Generated:** {rq2.get('total_automated_evaluations', 0)}
- **Critic Agent Revisions:** {rq2.get('critic_revised_count', 0)} ({rq2.get('critic_revision_rate', 0.0) * 100:.1f}%)
- **Human Validated Subsample:** {rq2.get('total_human_annotated', 0)}
- **Raw Agreement (Multi-Agent vs. Human):** {rq2.get('raw_agreement_rate', 0.0) * 100:.1f}%
- **Cohen's Kappa ($\\kappa$):** {cohen_val if cohen_val is not None else 'N/A'}
- **Reliability Assessment:** {kappa_interpretation}

---

## 6. Reproducibility & Methodology
- **Target LLM:** `{target_model}`
- **Judge & Critic Models:** `{judge_model}`
- **Framework:** FastAPI, LangGraph 1.2, SQLAlchemy 2.0 Async, Flutter 3.7
- **Raw Artifacts:** Download results CSV via `/api/v1/experiments/{exp_id}/export/csv`
"""
    return report


def main():
    parser = argparse.ArgumentParser(description="Generate executive research Markdown report for Parallax-Eval.")
    parser.add_argument("--experiment-id", required=True, help="Target experiment UUID")
    parser.add_argument("--api-url", default="http://127.0.0.1:8000/api/v1", help="Base REST API URL")
    parser.add_argument("--output-file", default=None, help="Output markdown report path")
    args = parser.parse_args()

    api_url = args.api_url.rstrip("/")
    out_file = args.output_file or f"reports/executive_report_{args.experiment_id[:8]}.md"

    print(f"Connecting to {api_url} for experiment {args.experiment_id}...")

    with httpx.Client(timeout=30.0) as client:
        # Fetch experiment
        exp_resp = client.get(f"{api_url}/experiments/{args.experiment_id}")
        if exp_resp.status_code != 200:
            print(f"Error: Experiment {args.experiment_id} not found.")
            sys.exit(1)
        exp = exp_resp.json()

        # Fetch RQ1
        rq1_resp = client.get(f"{api_url}/analytics/rq1/{args.experiment_id}")
        rq1 = rq1_resp.json() if rq1_resp.status_code == 200 else {}

        # Fetch RQ2
        rq2_resp = client.get(f"{api_url}/analytics/rq2/{args.experiment_id}")
        rq2 = rq2_resp.json() if rq2_resp.status_code == 200 else {}

    # Compile Markdown
    md = build_markdown_report(exp, rq1, rq2)

    dest = Path(out_file)
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(md, encoding="utf-8")

    print(f"✓ Executive Research Report generated successfully at: {dest.resolve()}")


if __name__ == "__main__":
    main()

