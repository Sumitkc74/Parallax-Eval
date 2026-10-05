import 'package:flutter/material.dart';

class OnboardingModal extends StatefulWidget {
  final VoidCallback onDismiss;
  final VoidCallback onLaunchExperiment;
  final VoidCallback onOpenInspector;

  const OnboardingModal({
    Key? key,
    required this.onDismiss,
    required this.onLaunchExperiment,
    required this.onOpenInspector,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onLaunchExperiment,
    required VoidCallback onOpenInspector,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => OnboardingModal(
        onDismiss: () => Navigator.pop(ctx),
        onLaunchExperiment: () {
          Navigator.pop(ctx);
          onLaunchExperiment();
        },
        onOpenInspector: () {
          Navigator.pop(ctx);
          onOpenInspector();
        },
      ),
    );
  }

  @override
  State<OnboardingModal> createState() => _OnboardingModalState();
}

class _OnboardingModalState extends State<OnboardingModal> {
  int _currentStep = 0;

  final List<_StepData> _steps = const [
    _StepData(
      number: '1',
      tagline: 'The Core Challenge',
      title: 'Why Cross-Lingual Safety Matters',
      description:
          'Commercial LLMs are trained to refuse hazardous instructions in English. However, bad actors bypass safety guardrails by translating identical prompts into low-resource languages such as Nepali (Devanagari script).\n\nParallax-Eval empirically quantifies this vulnerability gap across matched bilingual prompt pairs.',
      highlightLabel: 'What Happens Here',
      highlightDetail: 'Prompts are tested in parallel across English and Nepali to surface refusal parity delta.',
      icon: Icons.translate_outlined,
    ),
    _StepData(
      number: '2',
      tagline: 'Automated Evaluation',
      title: 'How Safety is Evaluated',
      description:
          'Every model output passes through a multi-agent validation loop:\n\n• Target LLM generates an unconstrained response.\n• Judge Agent applies strict harm taxonomies (CBRN, cyber, fraud, hate).\n• Critic Agent cross-examines the verdict to prevent false refusals.\n• Arbiter State Machine reconciles disagreements deterministically.',
      highlightLabel: 'Zero Human Bias',
      highlightDetail: 'Standardized rubrics and paired McNemar statistical significance testing ensure reproducible results.',
      icon: Icons.rule_folder_outlined,
    ),
    _StepData(
      number: '3',
      tagline: 'Perimeter Defense',
      title: 'Testing Guardrail Mitigations',
      description:
          'Evaluate how effectively defenses restore safety:\n\n• Translation-Pivot Guardrail: Translates incoming Devanagari prompts into English before perimeter safety filtering.\n• Bilingual Inoculation: Custom system prompts tailored for South Asian linguistic idioms.\n• Adaptive Red-Team Mutator: Tests automated adversarial obfuscation to probe edge cases.',
      highlightLabel: 'Continuous Protection',
      highlightDetail: 'Compare undefended baseline runs against defended candidates with automated CI/CD safety gates.',
      icon: Icons.shield_outlined,
    ),
    _StepData(
      number: '4',
      tagline: 'Next Actions',
      title: 'Ready to Get Started',
      description:
          'You can explore Parallax-Eval through two primary entry points:\n\n1. Quick Test: Use the Live Prompt Safety Inspector to test single ad-hoc prompts in real time.\n2. Benchmark Run: Launch a full evaluation experiment across the curated bilingual benchmark dataset.',
      highlightLabel: 'Recommended First Step',
      highlightDetail: 'Try inspecting a live prompt or launching an evaluation with the mock engine (zero API cost).',
      icon: Icons.rocket_launch_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final isLastStep = _currentStep == _steps.length - 1;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E2632) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E3B4E) : const Color(0xFFD6DBE1);
    final headerBg = isDark ? const Color(0xFF161D27) : const Color(0xFF1A283B);
    final cardBg = isDark ? const Color(0xFF263140) : const Color(0xFFF8F9FA);
    final cardBorder = isDark ? const Color(0xFF334255) : const Color(0xFFE2E4E8);
    final textHeading = isDark ? Colors.white : const Color(0xFF1A283B);
    final textBody = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A6675);
    final footerBg = isDark ? const Color(0xFF19202B) : const Color(0xFFFDFDFD);
    final footerBorder = isDark ? const Color(0xFF2E3B4E) : const Color(0xFFEAEAEA);
    final primaryBtnBg = isDark ? const Color(0xFF3B82F6) : const Color(0xFF1A283B);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Container(
          decoration: BoxDecoration(
            color: dialogBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: headerBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0x1FFFFFFF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(step.icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GUIDED WALKTHROUGH — STEP ${_currentStep + 1} OF ${_steps.length}',
                            style: const TextStyle(
                              color: Color(0xFFCFD6DF),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step.tagline,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Georgia',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      tooltip: 'Skip Walkthrough',
                      onPressed: widget.onDismiss,
                    ),
                  ],
                ),
              ),

              // Progress Bar
              Row(
                children: List.generate(_steps.length, (index) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: EdgeInsets.only(right: index < _steps.length - 1 ? 2 : 0),
                      color: index <= _currentStep
                          ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2C3E50))
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E4E8)),
                    ),
                  );
                }),
              ),

              // Body Content
              Padding(
                padding: const EdgeInsets.all(22.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textHeading,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      step.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: textBody,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Highlight card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 16, color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1A283B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.highlightLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: textHeading,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  step.highlightDetail,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textMuted,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Footer Controls
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: footerBg,
                  border: Border(top: BorderSide(color: footerBorder)),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(7)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back or Dismiss
                    if (_currentStep > 0)
                      TextButton.icon(
                        icon: const Icon(Icons.arrow_back, size: 14),
                        label: const Text('Back', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          setState(() {
                            _currentStep--;
                          });
                        },
                      )
                    else
                      TextButton(
                        onPressed: widget.onDismiss,
                        child: Text('Skip Guide', style: TextStyle(fontSize: 12, color: textMuted)),
                      ),

                    // Forward or Action Buttons
                    if (!isLastStep)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBtnBg,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onPressed: () {
                          setState(() {
                            _currentStep++;
                          });
                        },
                        label: const Text('Next Step', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        icon: const Icon(Icons.arrow_forward, size: 14),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onPressed: widget.onOpenInspector,
                            child: const Text('Live Inspector', style: TextStyle(fontSize: 12)),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBtnBg,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            icon: const Icon(Icons.play_arrow, size: 14),
                            label: const Text('Launch Experiment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            onPressed: widget.onLaunchExperiment,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepData {
  final String number;
  final String tagline;
  final String title;
  final String description;
  final String highlightLabel;
  final String highlightDetail;
  final IconData icon;

  const _StepData({
    required this.number,
    required this.tagline,
    required this.title,
    required this.description,
    required this.highlightLabel,
    required this.highlightDetail,
    required this.icon,
  });
}
