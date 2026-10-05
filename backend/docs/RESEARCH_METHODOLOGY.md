# Research Methodology & Experimental Protocol

Parallax-Eval investigates cross-lingual safety alignment in Large Language Models, focusing on English versus a lower-resource language (Nepali).

---

## 1. Research Questions

### **RQ1: Cross-Lingual Safety Parity**
> *Do selected LLMs demonstrate different safety behavior when semantically equivalent harmful and benign prompts are presented in English and Nepali?*

#### Metrics:
- **Harmful Refusal Rate (HRR)**:
  $$\text{HRR} = \frac{|\{r \in \mathcal{R}_{\text{harmful}} \mid \text{label}(r) = \text{Safe Refusal}\}|}{|\mathcal{R}_{\text{harmful}}|}$$
- **Unsafe Compliance Rate (UCR)**:
  $$\text{UCR} = \frac{|\{r \in \mathcal{R}_{\text{harmful}} \mid \text{label}(r) = \text{Unsafe Compliance}\}|}{|\mathcal{R}_{\text{harmful}}|}$$
- **Benign Compliance Rate (BCR)**:
  $$\text{BCR} = \frac{|\{r \in \mathcal{R}_{\text{benign}} \mid \text{label}(r) = \text{Appropriate Compliance}\}|}{|\mathcal{R}_{\text{benign}}|}$$
- **Over-Refusal Rate (ORR)**:
  $$\text{ORR} = \frac{|\{r \in \mathcal{R}_{\text{benign}} \mid \text{label}(r) = \text{Over-Refusal}\}|}{|\mathcal{R}_{\text{benign}}|}$$
- **Cross-Lingual Deltas**:
  $$\Delta_{\text{HRR}} = \text{HRR}_{\text{EN}} - \text{HRR}_{\text{NE}}, \quad \Delta_{\text{UCR}} = \text{UCR}_{\text{EN}} - \text{UCR}_{\text{NE}}$$

---

## 2. Research Questions (RQ2)

### **RQ2: Multi-Agent Evaluation Reliability**
> *How reliably does a Safety Judge–Critic multi-agent workflow classify English and Nepali LLM responses compared with human evaluation?*

#### Metrics:
- **Critic Revision Frequency**:
  $$\text{Revision Rate} = \frac{\text{Count}(\text{Critic Recommendation} = \text{REVISE})}{\text{Total Automated Evaluations}}$$
- **Raw Inter-Rater Agreement Rate**:
  $$\text{Agreement Rate} = \frac{\sum_{i=1}^N \mathbb{I}(\text{label}_{\text{auto}}^{(i)} = \text{label}_{\text{human}}^{(i)})}{N}$$
- **Cohen's Kappa ($\kappa$)**:
  $$\kappa = \frac{p_o - p_e}{1 - p_e}$$
  where $p_o$ is observed proportionate agreement and $p_e$ is the expected probability of chance agreement based on marginal label distributions.

---

## 3. Multi-Agent LangGraph Evaluation Topology

```
                  ┌──────────────────────┐
                  │ Target LLM Response  │
                  └──────────┬───────────┘
                             │
                             ▼
                  ┌──────────────────────┐
                  │  Safety Judge Agent  │
                  └──────────┬───────────┘
                             │ (judge_label, reasoning, confidence)
                             ▼
                  ┌──────────────────────┐
                  │     Critic Agent     │
                  └──────────┬───────────┘
                             │ (CONFIRM / REVISE, critique)
                             ▼
                  ┌──────────────────────┐
                  │    Arbiter Node      │
                  └──────────┬───────────┘
                             │ (final_label, confidence, trace)
                             ▼
                  ┌──────────────────────┐
                  │ PostgreSQL Storage   │
                  └──────────────────────┘
```

