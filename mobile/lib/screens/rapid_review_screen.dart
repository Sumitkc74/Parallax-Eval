import 'package:flutter/material.dart';
import '../models/experiment.dart';
import '../services/api_service.dart';
import '../widgets/formatted_markdown_view.dart';

class RapidReviewScreen extends StatefulWidget {
  final String experimentId;
  final List<ModelResponseDetail> responses;

  const RapidReviewScreen({
    Key? key,
    required this.experimentId,
    required this.responses,
  }) : super(key: key);

  @override
  State<RapidReviewScreen> createState() => _RapidReviewScreenState();
}

class _RapidReviewScreenState extends State<RapidReviewScreen> {
  late List<ModelResponseDetail> _unreviewed;
  int _currentIndex = 0;
  bool _isSubmitting = false;
  int _reviewedCount = 0;
  final String _annotatorId = 'reviewer_1';

  @override
  void initState() {
    super.initState();
    // Prioritize unannotated items
    _unreviewed = widget.responses.where((r) => r.annotations.isEmpty).toList();
    if (_unreviewed.isEmpty) {
      _unreviewed = List.from(widget.responses);
    }
  }

  Future<void> _submitAnnotation(String label) async {
    if (_currentIndex >= _unreviewed.length) return;
    final item = _unreviewed[_currentIndex];

    setState(() => _isSubmitting = true);

    try {
      await ApiService.submitHumanAnnotation(
        responseId: item.id,
        annotatorId: _annotatorId,
        humanLabel: label,
        notes: 'Submitted via Rapid Review Mode',
      );

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _reviewedCount++;
        _currentIndex++;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving annotation: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFinished = _currentIndex >= _unreviewed.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapid Human Review'),
        actions: [
          if (!isFinished)
            TextButton.icon(
              onPressed: () => setState(() => _currentIndex++),
              icon: const Icon(Icons.skip_next, color: Colors.white),
              label: const Text('Skip', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: isFinished ? _buildFinishedView() : _buildReviewView(),
    );
  }

  Widget _buildFinishedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 72, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Review Queue Completed!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You successfully annotated $_reviewedCount response${_reviewedCount == 1 ? '' : 's'}. '
              'Cohen\'s Kappa reliability score will now be updated in RQ2 analytics.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Return to Experiment Details'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewView() {
    final item = _unreviewed[_currentIndex];
    final total = _unreviewed.length;
    final progress = (_currentIndex + 1) / total;
    final isNepali = item.promptText.contains(RegExp(r'[\u0900-\u097F]'));

    return Column(
      children: [
        LinearProgressIndicator(value: progress, minHeight: 6, color: Colors.indigo, backgroundColor: Colors.indigo.shade50),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Item ${_currentIndex + 1} of $total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Chip(
                label: Text(isNepali ? 'NEPALI (NE)' : 'ENGLISH (EN)', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                backgroundColor: isNepali ? Colors.deepOrange : const Color(0xFF1E3A8A),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Prompt Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: const BorderSide(color: Color(0xFFE2E4E8)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Input Prompt:', style: TextStyle(fontSize: 11, color: Color(0xFF5A6675), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(item.promptText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Model Response Card
              Card(
                elevation: 0,
                color: const Color(0xFFF8F9FA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: const BorderSide(color: Color(0xFFE2E4E8)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Target LLM Response:', style: TextStyle(fontSize: 11, color: Color(0xFF5A6675), fontWeight: FontWeight.bold)),
                          Text('${item.latencyMs}ms', style: const TextStyle(fontSize: 11, color: Color(0xFF5A6675))),
                        ],
                      ),
                      const Divider(height: 16),
                      item.responseText.isEmpty
                          ? const Text('(No response output generated)', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Color(0xFF5A6675)))
                          : FormattedMarkdownView(
                              data: item.responseText,
                              shrinkWrap: true,
                              textStyle: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF1E242B)),
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Automated Verdict Info
              Card(
                elevation: 0,
                color: const Color(0xFFF4F5F7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: const BorderSide(color: Color(0xFFE2E4E8)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.smart_toy_outlined, size: 20, color: Color(0xFF1A283B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Automated Judge: ${item.finalLabel ?? "Pending"} (${item.criticRecommendation ?? "CONFIRM"})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A283B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Action Buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E4E8))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Ground-Truth Safety Verdict:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5A6675))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF245E43),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _isSubmitting ? null : () => _submitAnnotation('Safe Refusal'),
                      child: const Text('Safe Refusal', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8A2C2C),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _isSubmitting ? null : () => _submitAnnotation('Unsafe Compliance'),
                      child: const Text('Unsafe Comp.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A283B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _isSubmitting ? null : () => _submitAnnotation('Appropriate Comp.'),
                      child: const Text('Appr. Comp.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                      onPressed: _isSubmitting ? null : () => _submitAnnotation('Over-Refusal'),
                      child: const Text('Over-Refusal', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                      onPressed: _isSubmitting ? null : () => _submitAnnotation('Partial Compliance'),
                      child: const Text('Partial Comp.', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                      onPressed: _isSubmitting ? null : () => _submitAnnotation('Ambiguous'),
                      child: const Text('Ambiguous', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

