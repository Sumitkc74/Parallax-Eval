import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/draft_service.dart';
import '../theme/app_theme.dart';
import '../utils/error_handler.dart';
import 'data_consent_dialog.dart';

class CreateCustomPromptDialog extends StatefulWidget {
  final VoidCallback? onCreated;

  const CreateCustomPromptDialog({Key? key, this.onCreated}) : super(key: key);

  @override
  State<CreateCustomPromptDialog> createState() => _CreateCustomPromptDialogState();
}

class _CreateCustomPromptDialogState extends State<CreateCustomPromptDialog> {
  late final TextEditingController _enPromptController;
  late final TextEditingController _nePromptController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  final _enFocusNode = FocusNode();

  String _promptType = 'harmful';
  bool _isSubmitting = false;
  bool _isTranslating = false;
  bool _wasAutoTranslated = false;
  bool _consentAgreed = true;
  String? _error;

  final List<String> _suggestedCategories = [
    'Cybersecurity',
    'Weapons & Explosives',
    'Financial Fraud',
    'PII & Privacy',
    'Hate Speech',
    'Disinformation',
    'Consumer Scams',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    // Problem 5: Restore draft if previously stored
    final draft = DraftService.instance.customPromptDraft;
    _enPromptController = TextEditingController(text: draft?['en'] ?? '');
    _nePromptController = TextEditingController(text: draft?['ne'] ?? '');
    _descriptionController = TextEditingController(text: draft?['desc'] ?? '');
    _categoryController = TextEditingController(text: draft?['category'] ?? 'Cybersecurity');
    _promptType = draft?['type'] ?? 'harmful';

    _enPromptController.addListener(_syncDraft);
    _nePromptController.addListener(_syncDraft);
    _descriptionController.addListener(_syncDraft);
    _categoryController.addListener(_syncDraft);

    // Auto-translate to Nepali when user finishes typing English if Nepali is empty
    _enFocusNode.addListener(() {
      if (!_enFocusNode.hasFocus &&
          _enPromptController.text.trim().isNotEmpty &&
          _nePromptController.text.trim().isEmpty &&
          !_isTranslating &&
          !_isSubmitting) {
        _autoTranslate();
      }
    });
  }

  void _syncDraft() {
    DraftService.instance.saveCustomPromptDraft({
      'en': _enPromptController.text,
      'ne': _nePromptController.text,
      'desc': _descriptionController.text,
      'category': _categoryController.text,
      'type': _promptType,
    });
  }

  bool _hasUnsavedChanges() {
    return _enPromptController.text.trim().isNotEmpty ||
        _nePromptController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _enFocusNode.dispose();
    _enPromptController.dispose();
    _nePromptController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _autoTranslate() async {
    final enText = _enPromptController.text.trim();
    if (enText.isEmpty) {
      setState(() {
        _error = 'Please enter an English prompt variant first before translating.';
      });
      return;
    }

    setState(() {
      _isTranslating = true;
      _error = null;
    });

    try {
      final neTranslated = await ApiService.translatePrompt(enText);
      if (!mounted) return;
      setState(() {
        _nePromptController.text = neTranslated;
        _wasAutoTranslated = true;
        _isTranslating = false;
      });
      _syncDraft();
    } catch (e) {
      if (!mounted) return;
      // Problem 2: Humanize error without raw exception strings
      setState(() {
        _error = AppErrorHandler.toHumanReadable(e, actionContext: 'translating prompt to Nepali');
        _isTranslating = false;
      });
    }
  }

  Future<void> _submit() async {
    // Problem 1: Double submission guard
    if (_isSubmitting || _isTranslating) return;

    final en = _enPromptController.text.trim();
    final ne = _nePromptController.text.trim();
    final cat = _categoryController.text.trim();

    if (en.isEmpty || ne.isEmpty || cat.isEmpty) {
      setState(() {
        _error = 'Please fill out Category, English prompt, and Nepali prompt.';
      });
      return;
    }

    if (!_consentAgreed) {
      setState(() {
        _error = 'Please confirm that the prompt contains no real personal data (Zero-PII) and complies with research policies.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final idempotencyKey = '${DateTime.now().millisecondsSinceEpoch}-${en.hashCode}-${ne.hashCode}';

    try {
      await ApiService.createCustomPromptPair(
        category: cat,
        promptType: _promptType,
        englishPrompt: en,
        nepaliPrompt: ne,
        englishDescription: _descriptionController.text.trim(),
        idempotencyKey: idempotencyKey,
      );

      // Clear draft on success
      DraftService.instance.clearCustomPromptDraft();

      if (!mounted) return;
      Navigator.pop(context);
      widget.onCreated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Custom prompt pair successfully added to benchmark dataset!'),
          backgroundColor: AppThemeColors.successBorder(context),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Problem 1 & 2: Re-enable on failure and humanize error message
      setState(() {
        _error = AppErrorHandler.toHumanReadable(e, actionContext: 'saving custom prompt pair');
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = AppThemeColors.border(context);
    final textPrimary = AppThemeColors.textPrimary(context);
    final textMuted = AppThemeColors.textMuted(context);
    final primary = AppThemeColors.primarySlate(context);
    final subCardBg = AppThemeColors.subCardBg(context);

    // Problem 5: Intercept back button to confirm discarding draft
    return PopScope(
      canPop: !_isSubmitting && !_isTranslating && !_hasUnsavedChanges(),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _isSubmitting) return;
        final shouldPop = await DraftService.confirmDiscard(context, formName: 'prompt pair');
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: AlertDialog(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: border),
        ),
        title: Row(
          children: [
            Icon(Icons.playlist_add, color: primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Add Custom Prompt Pair',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Material(
            color: Colors.transparent,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: subCardBg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: border),
                  ),
                  child: Text(
                    'Add a semantically equivalent English and Nepali prompt pair to the benchmark database. '
                    'It will be automatically included in future statistical parity evaluations (RQ1 and RQ2).',
                    style: TextStyle(fontSize: 12, color: textPrimary),
                  ),
                ),
                const SizedBox(height: 14),

                // Threat Category
                Text('Category:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                const SizedBox(height: 4),
                TextField(
                  controller: _categoryController,
                  enabled: !_isSubmitting,
                  textInputAction: TextInputAction.next,
                  scrollPadding: const EdgeInsets.all(80),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Cybersecurity, Hate Speech, General',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  children: _suggestedCategories.map((c) {
                    return ActionChip(
                      label: Text(c, style: const TextStyle(fontSize: 10)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              setState(() => _categoryController.text = c);
                              _syncDraft();
                            },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Benchmark Intent (Harmful vs Benign)
                Text('Benchmark Intent Type:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'harmful',
                        icon: Icon(Icons.warning_amber_rounded, size: 16),
                        label: Text('Harmful (Refusal Test)', style: TextStyle(fontSize: 12)),
                      ),
                      ButtonSegment(
                        value: 'benign',
                        icon: Icon(Icons.check_circle_outline, size: 16),
                        label: Text('Benign (Helpfulness Test)', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    selected: {_promptType},
                    onSelectionChanged: _isSubmitting
                        ? null
                        : (Set<String> newSelection) {
                            setState(() {
                              _promptType = newSelection.first;
                            });
                            _syncDraft();
                          },
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),

                // English Prompt
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('English Prompt Variant:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: (_isTranslating || _isSubmitting) ? null : _autoTranslate,
                      icon: _isTranslating
                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.translate, size: 14, color: primary),
                      label: Text(
                        _isTranslating ? 'Translating...' : 'Translate to Nepali',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _enPromptController,
                  focusNode: _enFocusNode,
                  enabled: !_isSubmitting,
                  maxLines: 2,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  scrollPadding: const EdgeInsets.all(80),
                  decoration: InputDecoration(
                    hintText: 'Enter English prompt text...',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: _isTranslating
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.translate, size: 16, color: primary),
                      tooltip: 'Translate English to Nepali',
                      onPressed: (_isTranslating || _isSubmitting) ? null : _autoTranslate,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Nepali Prompt
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Nepali Prompt Variant (Devanagari):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                    if (_wasAutoTranslated)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppThemeColors.successBg(context),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppThemeColors.successBorder(context)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 12, color: AppThemeColors.successText(context)),
                            const SizedBox(width: 4),
                            Text(
                              'Machine Translated',
                              style: TextStyle(fontSize: 10, color: AppThemeColors.successText(context), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _nePromptController,
                  enabled: !_isSubmitting,
                  maxLines: 2,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  scrollPadding: const EdgeInsets.all(80),
                  decoration: const InputDecoration(
                    hintText: 'नेपालीमा प्रम्प्ट प्रविष्ट गर्नुहोस् वा माथिको Translate प्रयोग गर्नुहोस्...',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_wasAutoTranslated) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Note: Review the Devanagari translation above for dialect nuance before saving.',
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                ],
                const SizedBox(height: 12),

                // Optional Description
                Text('Behavior Description (Optional):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                const SizedBox(height: 4),
                TextField(
                  controller: _descriptionController,
                  enabled: !_isSubmitting,
                  maxLines: 1,
                  textInputAction: TextInputAction.done,
                  scrollPadding: const EdgeInsets.all(80),
                  decoration: const InputDecoration(
                    hintText: 'Brief summary of what this behavior evaluates...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),

                // Zero-PII Policy & Consent
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppThemeColors.warningBg(context),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppThemeColors.warningBorder(context)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.privacy_tip_outlined, size: 16, color: AppThemeColors.warningText(context)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Zero-PII & Ethics Policy',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppThemeColors.warningText(context)),
                                ),
                                InkWell(
                                  onTap: () => showDialog(
                                    context: context,
                                    builder: (_) => const DataConsentDialog(),
                                  ),
                                  child: Text(
                                    'Review Consent',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Never submit real personal data, IDs, passwords, or credentials.',
                              style: TextStyle(fontSize: 10, color: AppThemeColors.warningText(context)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: _consentAgreed,
                  activeColor: primary,
                  title: const Text(
                    'I confirm this prompt contains no real personal data and complies with research safety policies.',
                    style: TextStyle(fontSize: 11),
                  ),
                  onChanged: _isSubmitting ? null : (val) => setState(() => _consentAgreed = val ?? false),
                ),

                // Error Display (Problem 2)
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppThemeColors.errorBg(context),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppThemeColors.errorBorder(context)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline, size: 16, color: AppThemeColors.errorText(context)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: AppThemeColors.errorText(context), fontSize: 11, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting
                ? null
                : () async {
                    if (_hasUnsavedChanges()) {
                      final discard = await DraftService.confirmDiscard(context, formName: 'prompt pair');
                      if (!discard || !context.mounted) return;
                    }
                    Navigator.pop(context);
                  },
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            icon: _isSubmitting
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check, size: 16),
            label: Text(_isSubmitting ? 'Saving...' : 'Save Prompt Pair'),
            onPressed: (_isSubmitting || _isTranslating) ? null : _submit,
          ),
        ],
      ),
    );
  }
}
