import 'package:flutter/material.dart';

class DataConsentDialog extends StatefulWidget {
  final VoidCallback? onConsentGiven;

  const DataConsentDialog({Key? key, this.onConsentGiven}) : super(key: key);

  @override
  State<DataConsentDialog> createState() => _DataConsentDialogState();
}

class _DataConsentDialogState extends State<DataConsentDialog> {
  bool _ageConfirmed = false;
  bool _noPiiAgreed = false;
  bool _researchPurposeUnderstood = false;

  bool get _canProceed => _ageConfirmed && _noPiiAgreed && _researchPurposeUnderstood;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.verified_user_outlined, color: Color(0xFF1E3A8A)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Research Ethics & Data Consent',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Text(
                  'Parallax-Eval is an open-source research platform evaluating cross-lingual AI safety (English vs. Nepali). '
                  'Please review the data governance conditions below before submitting prompts.',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Data Processing & Storage Disclosures:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              _buildBullet('Prompts are stored locally in the evaluation database for scientific benchmarking.'),
              _buildBullet('Target models receive prompts via TLS 1.3 to customer-configured API endpoints.'),
              _buildBullet('No tracking, profiling, or third-party advertising cookies are used.'),
              _buildBullet('You have the statutory right to correct (PUT) or permanently delete (DELETE) your custom data at any time (GDPR / Nepal Privacy Act 2075).'),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // Checkbox 1: Age
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: _ageConfirmed,
                activeColor: const Color(0xFF1E3A8A),
                title: const Text(
                  'I confirm that I am at least 18 years of age (or legal age of majority).',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Minors are not permitted due to adversarial and hazardous content testing.',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                onChanged: (val) => setState(() => _ageConfirmed = val ?? false),
              ),

              // Checkbox 2: Zero PII
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: _noPiiAgreed,
                activeColor: const Color(0xFF1E3A8A),
                title: const Text(
                  'I agree NOT to submit Personally Identifiable Information (PII) or confidential secrets.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Do not input real names, citizenship/national ID, passwords, or medical records.',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                onChanged: (val) => setState(() => _noPiiAgreed = val ?? false),
              ),

              // Checkbox 3: Research & Disclaimers
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: _researchPurposeUnderstood,
                activeColor: const Color(0xFF1E3A8A),
                title: const Text(
                  'I understand this is an evaluation tool and does NOT provide high-risk or professional advice.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Model outputs must never be used for real-world weapons, attacks, or medical/legal guidance.',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                onChanged: (val) => setState(() => _researchPurposeUnderstood = val ?? false),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Decline'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _canProceed ? const Color(0xFF1E3A8A) : Colors.grey,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.check, size: 16),
          label: const Text('Agree & Continue'),
          onPressed: _canProceed
              ? () {
                  Navigator.pop(context);
                  widget.onConsentGiven?.call();
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 11, color: Colors.black87))),
        ],
      ),
    );
  }
}

