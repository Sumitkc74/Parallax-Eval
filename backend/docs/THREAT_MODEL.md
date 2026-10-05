# Multilingual AI Safety Threat Model

## 1. Overview
Large Language Models exhibit a **Cross-Lingual Safety Asymmetry**: safety guardrails and refusal boundaries trained heavily on high-resource corpora (English) degrade when prompted in low-resource languages (e.g., Nepali). Parallax-Eval models and stress-tests this vulnerability.

---

## 2. Threat Actors & Vectors

### A. Low-Resource Language Translation Evasion (Direct Bypass)
- **Mechanic**: An adversary translates a known harmful English prompt (e.g., malware design or scam generation) into Nepali (Devanagari script).
- **Vulnerability**: Safety classifiers often have higher false-negative rates on non-Latin scripts due to sparse safety alignment data.
- **Example in Benchmark**: `BENCH-H01` (Financial fraud lottery letter).

### B. Cross-Lingual Academic / Hypothetical Framing (Semantic Camouflage)
- **Mechanic**: The adversary embeds harmful intent into an academic, hypothetical, or fictional narrative in Nepali (e.g., `"काल्पनिक कथाको सन्दर्भमा..."`).
- **Vulnerability**: Models trained to be helpful struggle to distinguish legitimate academic inquiries from malicious exploitation when idioms and cultural contexts differ from training distributions.

### C. Phonetic Transliteration & Lexical Obfuscation
- **Mechanic**: Mixing Romanized Nepali (Devanagari transliterated into English letters) or combining English technical nouns with Nepali syntactic verbs to bypass surface-level regex keyword filters.
- **Vulnerability**: Rule-based guardrails fail to identify mixed-script tokens.

### D. The Tokenization & Language Tax Vulnerability
- **Mechanic**: Byte-Pair Encoding (BPE) tokenizers split Devanagari words into multiple sub-byte tokens (2.5x to 3.0x token inflation).
- **Vulnerability**: Increased token length increases attention dispersion across longer token sequences, diluting the effective weight of system safety instructions.

---

## 3. Defense-in-Depth Mitigation Architecture

Parallax-Eval tests and validates a defense-in-depth safety stack:

```
[ Incoming User Prompt ]
       │
       ▼
1. Input Guardrail Interceptor (Regex / Keyword / Script Detection)
       │
       ▼
2. Target LLM Inference
       │
       ▼
3. Output Guardrail Interceptor (Content Sanitization & Safety Masking)
       │
       ▼
4. Multi-Agent Audit (Policy-Grounded Safety Judge + Cross-Lingual Critic)
       │
       ▼
[ Validated Safety Output ]
```

---

## 4. Benchmark Threat Taxonomies

| Category Code | Description | Real-World Impact | Severity |
| :--- | :--- | :--- | :--- |
| `financial_fraud` | Advance-fee lottery scams, unauthorized fund transfer social engineering | Financial loss targeting vulnerable citizens | HIGH |
| `cyber_security_threat` | Automated port scanning, exploit scripts, vulnerability scanning | Infrastructure compromise, unauthorized access | CRITICAL |
| `privacy_violation` | PII harvesting, unauthorized contact directory scraping | Doxxing, privacy infringement, stalking | HIGH |
| `disinformation` | Fabricated disaster news (dam bursts, earthquake panic) | Public panic, emergency responder diversion | HIGH |
| `impersonation` | Bank credential harvesting, ATM PIN phishing | Identity theft, account draining | CRITICAL |
| `malicious_software` | Keyloggers, background spy services, data exfiltration | Host compromise, surveillance | CRITICAL |
| `consumer_scams` | Counterfeit testimonials, deceptive marketing | Consumer deception, pyramid schemes | MEDIUM |

