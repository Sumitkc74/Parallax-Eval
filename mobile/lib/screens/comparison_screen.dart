import 'package:flutter/material.dart';
import '../models/experiment.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/error_handler.dart';
import '../widgets/formatted_markdown_view.dart';
import '../widgets/skeleton_loader.dart';

class ComparisonScreen extends StatefulWidget {
  final List<Experiment> completedExperiments;

  const ComparisonScreen({Key? key, required this.completedExperiments}) : super(key: key);

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  String? _baselineId;
  String? _candidateId;
  bool _isLoading = false;
  Map<String, dynamic>? _comparisonData;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.completedExperiments.isNotEmpty) {
      _baselineId = widget.completedExperiments.first.id;
      if (widget.completedExperiments.length > 1) {
        _candidateId = widget.completedExperiments[1].id;
      } else {
        _candidateId = widget.completedExperiments.first.id;
      }
    }
  }

  Future<void> _runComparison() async {
    if (_baselineId == null || _candidateId == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ApiService.compareExperiments(_baselineId!, _candidateId!);
      setState(() {
        _comparisonData = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = AppErrorHandler.toHumanReadable(e, actionContext: 'generating comparative safety diff');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = widget.completedExperiments;

    return Title(
      title: 'Parallax-Eval | Experiment Comparison & Gates',
      color: const Color(0xFF1A283B),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Experiment Comparison & Diff'),
        ),
        body: completed.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 440),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E4E8)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F5),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE2E4E8)),
                          ),
                          child: const Icon(Icons.compare_arrows_outlined, size: 28, color: Color(0xFF5A6675)),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No Completed Experiments Found',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A283B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Comparative analysis requires at least one completed evaluation run to inspect regression diffs and safety parity benchmarks.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Color(0xFF5A6675), height: 1.4),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('Return to Safety Dashboard', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Experiment Selection Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: const BorderSide(color: Color(0xFFE2E4E8)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Experiments to Compare',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _baselineId,
                              decoration: const InputDecoration(
                                labelText: 'Baseline Run (Reference)',
                                border: OutlineInputBorder(),
                              ),
                              items: completed.map((e) {
                                return DropdownMenuItem(
                                  value: e.id,
                                  child: Text('${e.name} (${e.targetModel})', overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _baselineId = val),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _candidateId,
                              decoration: const InputDecoration(
                                labelText: 'Candidate Run (New Model / Mitigation)',
                                border: OutlineInputBorder(),
                              ),
                              items: completed.map((e) {
                                return DropdownMenuItem(
                                  value: e.id,
                                  child: Text('${e.name} (${e.targetModel})', overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _candidateId = val),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A283B),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                                icon: const Icon(Icons.compare_arrows),
                                label: const Text('Run Comparative Safety Diff'),
                                onPressed: _isLoading ? null : _runComparison,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: SkeletonCard(),
                      ),

                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(14.0),
                          decoration: BoxDecoration(
                            color: AppThemeColors.errorBg(context),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppThemeColors.errorBorder(context)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.error_outline, size: 18, color: AppThemeColors.errorText(context)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(color: AppThemeColors.errorText(context), fontSize: 12, height: 1.35),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (_comparisonData != null && !_isLoading) ...[
                      const SizedBox(height: 16),
                      _buildSafetyGateBanner(),
                      const SizedBox(height: 16),
                      _buildMetricsTable(),
                      const SizedBox(height: 16),
                      _buildRegressionsList(),
                      const SizedBox(height: 16),
                      _buildImprovementsList(),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSafetyGateBanner() {
    final passed = _comparisonData!['safety_gate_passed'] as bool? ?? false;
    final summary = _comparisonData!['summary'] as String? ?? '';
    final regressions = _comparisonData!['total_regressions'] ?? 0;
    final improvements = _comparisonData!['total_improvements'] ?? 0;

    return Card(
      color: passed ? Colors.green.shade50 : Colors.red.shade50,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: passed ? Colors.green : Colors.red, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(passed ? Icons.check_circle : Icons.warning, color: passed ? Colors.green : Colors.red, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    passed ? 'SAFETY GATE PASSED' : 'SAFETY REGRESSION DETECTED',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: passed ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FormattedInlineText(text: summary, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(
                  label: Text('Regressions: $regressions'),
                  backgroundColor: regressions > 0 ? Colors.red.shade100 : Colors.grey.shade200,
                ),
                Chip(
                  label: Text('Improvements: $improvements'),
                  backgroundColor: improvements > 0 ? Colors.green.shade100 : Colors.grey.shade200,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsTable() {
    final metricsByLang = _comparisonData!['metrics_by_language'] as Map<String, dynamic>? ?? {};
    final enMetrics = metricsByLang['en'] as Map<String, dynamic>? ?? {};
    final neMetrics = metricsByLang['ne'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Metric Comparison & Deltas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildMetricRow('English Harmful Refusal (HRR)', enMetrics['harmful_refusal_rate']),
            _buildMetricRow('English Unsafe Compliance (UCR)', enMetrics['unsafe_compliance_rate']),
            const Divider(),
            _buildMetricRow('Nepali Harmful Refusal (HRR)', neMetrics['harmful_refusal_rate']),
            _buildMetricRow('Nepali Unsafe Compliance (UCR)', neMetrics['unsafe_compliance_rate']),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, dynamic metricData) {
    if (metricData == null) return const SizedBox.shrink();
    final base = (metricData['baseline_value'] as num?)?.toDouble() ?? 0.0;
    final cand = (metricData['candidate_value'] as num?)?.toDouble() ?? 0.0;
    final delta = (metricData['delta'] as num?)?.toDouble() ?? 0.0;

    final isUcr = label.contains('UCR');
    final isGood = isUcr ? delta <= 0 : delta >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 360;
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${(base * 100).toStringAsFixed(1)}% -> ${(cand * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isGood ? const Color(0xFFEAF5EA) : const Color(0xFFFBF1F1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: isGood ? const Color(0xFFA7D7A9) : const Color(0xFFE8C8C8)),
                      ),
                      child: Text(
                        '${delta >= 0 ? '+' : ''}${(delta * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: isGood ? const Color(0xFF245E43) : const Color(0xFF8A2C2C),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
              Text('${(base * 100).toStringAsFixed(1)}% -> ${(cand * 100).toStringAsFixed(1)}%'),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isGood ? const Color(0xFFEAF5EA) : const Color(0xFFFBF1F1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: isGood ? const Color(0xFFA7D7A9) : const Color(0xFFE8C8C8)),
                ),
                child: Text(
                  '${delta >= 0 ? '+' : ''}${(delta * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isGood ? const Color(0xFF245E43) : const Color(0xFF8A2C2C),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRegressionsList() {
    final regressions = (_comparisonData!['regressions'] as List?) ?? [];
    if (regressions.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      color: const Color(0xFFFBF1F1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Color(0xFFE8C8C8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.arrow_downward, color: Color(0xFF8A2C2C)),
                const SizedBox(width: 8),
                Text('Detected Regressions (${regressions.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF8A2C2C))),
              ],
            ),
            const SizedBox(height: 8),
            ...regressions.map((r) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(r['prompt_text'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: FormattedInlineText(
                  text: '${r['details']} [${r['language'].toUpperCase()}]',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text('${r['baseline_label']} -> ${r['candidate_label']}', style: const TextStyle(color: Color(0xFF8A2C2C), fontWeight: FontWeight.bold)),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildImprovementsList() {
    final improvements = (_comparisonData!['improvements'] as List?) ?? [];
    if (improvements.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      color: const Color(0xFFEAF5EA),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Color(0xFFA7D7A9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.arrow_upward, color: Color(0xFF245E43)),
                const SizedBox(width: 8),
                Text('Detected Improvements (${improvements.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF245E43))),
              ],
            ),
            const SizedBox(height: 8),
            ...improvements.map((i) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(i['prompt_text'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: FormattedInlineText(
                  text: '${i['details']} [${i['language'].toUpperCase()}]',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text('${i['baseline_label']} -> ${i['candidate_label']}', style: const TextStyle(color: Color(0xFF245E43), fontWeight: FontWeight.bold)),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

