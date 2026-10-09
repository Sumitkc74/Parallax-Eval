import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/draft_service.dart';
import '../theme/app_theme.dart';
import '../utils/error_handler.dart';
import 'create_custom_prompt_dialog.dart';

class CreateExperimentDialog extends StatefulWidget {
  final VoidCallback onCreated;

  const CreateExperimentDialog({Key? key, required this.onCreated}) : super(key: key);

  @override
  State<CreateExperimentDialog> createState() => _CreateExperimentDialogState();
}

class _CreateExperimentDialogState extends State<CreateExperimentDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _customTargetModelController;
  late final TextEditingController _customJudgeModelController;
  late final TextEditingController _customEndpointController;
  late final TextEditingController _customApiKeyController;

  String _targetModel = 'gemini-1.5-flash';
  String _judgeModel = 'gemini-1.5-flash';
  bool _useCustomEndpoint = false;
  bool _includeEn = true;
  bool _includeNe = true;
  bool _includeHarmful = true;
  bool _includeBenign = true;
  bool _enableGuardrails = false;
  String _defenseStrategy = 'NONE';
  String _evaluationMode = 'STATIC';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Problem 5: Restore draft if previously entered
    final draft = DraftService.instance.experimentDraft;
    _nameController = TextEditingController(text: draft?['name'] ?? 'Gemini Safety Audit');
    _customTargetModelController = TextEditingController(text: draft?['custom_target'] ?? 'llama3.2:3b');
    _customJudgeModelController = TextEditingController(text: draft?['custom_judge'] ?? 'gpt-4o');
    _customEndpointController = TextEditingController(text: draft?['endpoint'] ?? 'http://localhost:11434/v1');
    _customApiKeyController = TextEditingController(text: draft?['api_key'] ?? '');

    if (draft != null) {
      _targetModel = (draft['target_model'] as String?) ?? _targetModel;
      _judgeModel = (draft['judge_model'] as String?) ?? _judgeModel;
      _useCustomEndpoint = (draft['use_custom_endpoint'] as bool?) ?? _useCustomEndpoint;
      _includeEn = (draft['include_en'] as bool?) ?? _includeEn;
      _includeNe = (draft['include_ne'] as bool?) ?? _includeNe;
      _includeHarmful = (draft['include_harmful'] as bool?) ?? _includeHarmful;
      _includeBenign = (draft['include_benign'] as bool?) ?? _includeBenign;
      _enableGuardrails = (draft['enable_guardrails'] as bool?) ?? _enableGuardrails;
      _defenseStrategy = (draft['defense_strategy'] as String?) ?? _defenseStrategy;
      _evaluationMode = (draft['evaluation_mode'] as String?) ?? _evaluationMode;
    }

    // Autosave progress as user types
    _nameController.addListener(_syncDraft);
    _customTargetModelController.addListener(_syncDraft);
    _customJudgeModelController.addListener(_syncDraft);
    _customEndpointController.addListener(_syncDraft);
    _customApiKeyController.addListener(_syncDraft);
  }

  void _syncDraft() {
    DraftService.instance.saveExperimentDraft({
      'name': _nameController.text,
      'custom_target': _customTargetModelController.text,
      'custom_judge': _customJudgeModelController.text,
      'endpoint': _customEndpointController.text,
      'api_key': _customApiKeyController.text,
      'target_model': _targetModel,
      'judge_model': _judgeModel,
      'use_custom_endpoint': _useCustomEndpoint,
      'include_en': _includeEn,
      'include_ne': _includeNe,
      'include_harmful': _includeHarmful,
      'include_benign': _includeBenign,
      'enable_guardrails': _enableGuardrails,
      'defense_strategy': _defenseStrategy,
      'evaluation_mode': _evaluationMode,
    });
  }

  bool _hasUnsavedChanges() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty && name != 'Gemini Safety Audit') return true;
    if (_targetModel != 'gemini-1.5-flash') return true;
    if (_customTargetModelController.text != 'llama3.2:3b') return true;
    if (_customApiKeyController.text.isNotEmpty) return true;
    if (_enableGuardrails) return true;
    if (_defenseStrategy != 'NONE') return true;
    return false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customTargetModelController.dispose();
    _customJudgeModelController.dispose();
    _customEndpointController.dispose();
    _customApiKeyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Problem 1: Double submission guard
    if (_isSubmitting) return;

    final expName = _nameController.text.trim();
    if (expName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter an experiment name to identify this safety run.'),
          backgroundColor: AppThemeColors.errorBorder(context),
        ),
      );
      return;
    }

    final target = _targetModel == 'custom'
        ? _customTargetModelController.text.trim()
        : _targetModel;
    final judge = _judgeModel == 'custom'
        ? _customJudgeModelController.text.trim()
        : _judgeModel;

    if (target.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a target model identifier (e.g. llama3.2:3b, gpt-4o).'),
          backgroundColor: AppThemeColors.errorBorder(context),
        ),
      );
      return;
    }

    final languages = <String>[];
    if (_includeEn) languages.add('en');
    if (_includeNe) languages.add('ne');

    final promptTypes = <String>[];
    if (_includeHarmful) promptTypes.add('harmful');
    if (_includeBenign) promptTypes.add('benign');

    if (languages.isEmpty || promptTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one language (EN/NE) and one prompt category.'),
          backgroundColor: AppThemeColors.errorBorder(context),
        ),
      );
      return;
    }

    // Problem 1: Lock form and disable submit button immediately
    setState(() => _isSubmitting = true);
    final idempotencyKey = '${DateTime.now().millisecondsSinceEpoch}-${expName.hashCode}';

    try {
      await ApiService.createExperiment(
        name: expName,
        targetModel: target,
        judgeModel: judge,
        languages: languages,
        promptTypes: promptTypes,
        guardrailEnabled: _enableGuardrails,
        defenseStrategy: _defenseStrategy,
        evaluationMode: _evaluationMode,
        customBaseUrl: (_targetModel == 'custom' && _useCustomEndpoint)
            ? _customEndpointController.text.trim()
            : null,
        customApiKey: (_targetModel == 'custom' && _useCustomEndpoint && _customApiKeyController.text.trim().isNotEmpty)
            ? _customApiKeyController.text.trim()
            : null,
        idempotencyKey: idempotencyKey,
      );

      // Clear draft on successful creation
      DraftService.instance.clearExperimentDraft();

      if (!mounted) return;
      Navigator.pop(context);
      widget.onCreated();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Evaluation "$expName" launched successfully.'),
          backgroundColor: AppThemeColors.successBorder(context),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Problem 1: Re-enable button on failure so user can retry
      setState(() => _isSubmitting = false);
      // Problem 2: Humanize raw technical error
      final friendlyError = AppErrorHandler.toHumanReadable(e, actionContext: 'launching evaluation experiment');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError),
          backgroundColor: AppThemeColors.errorBorder(context),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = AppThemeColors.border(context);
    final textPrimary = AppThemeColors.textPrimary(context);
    final subCardBg = AppThemeColors.subCardBg(context);
    final primary = AppThemeColors.primarySlate(context);

    // Problem 5: Guard against accidental pop / back button discarding input
    return PopScope(
      canPop: !_isSubmitting && !_hasUnsavedChanges(),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _isSubmitting) return;
        final shouldPop = await DraftService.confirmDiscard(context, formName: 'experiment configuration');
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
            Icon(Icons.biotech, color: primary),
            const SizedBox(width: 8),
            Text(
              'Configure Safety Evaluation',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          width: double.maxFinite,
          child: Material(
            color: Colors.transparent,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  enabled: !_isSubmitting,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  scrollPadding: const EdgeInsets.all(80),
                  decoration: const InputDecoration(
                    labelText: 'Experiment Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: 16),

                // Target LLM Selection
                DropdownButtonFormField<String>(
                  initialValue: _targetModel,
                  decoration: const InputDecoration(
                    labelText: 'Target LLM',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.smart_toy_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'gemini-1.5-flash', child: Text('gemini-1.5-flash (Google Free Tier)')),
                    DropdownMenuItem(value: 'gpt-4o-mini', child: Text('gpt-4o-mini')),
                    DropdownMenuItem(value: 'gpt-4o', child: Text('gpt-4o')),
                    DropdownMenuItem(value: 'mock-target', child: Text('mock-target (Offline)')),
                    DropdownMenuItem(value: 'custom', child: Text('Custom Model / Local Ollama (OpenAI compatible)...')),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() {
                              _targetModel = val;
                              if (val == 'custom') {
                                _useCustomEndpoint = true;
                              }
                            });
                            _syncDraft();
                          }
                        },
                ),

                // Custom Target Model Configuration Section
                if (_targetModel == 'custom') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: subCardBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Custom Model Configuration',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _customTargetModelController,
                          enabled: !_isSubmitting,
                          autocorrect: false,
                          textInputAction: TextInputAction.next,
                          scrollPadding: const EdgeInsets.all(80),
                          decoration: const InputDecoration(
                            labelText: 'Model Identifier / Tag',
                            hintText: 'e.g. llama3.2:3b, qwen2.5:7b, mistral',
                            border: OutlineInputBorder(),
                            isDense: true,
                            prefixIcon: Icon(Icons.tag, size: 18),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            ActionChip(
                              label: const Text('llama3.2:3b', style: TextStyle(fontSize: 11)),
                              onPressed: _isSubmitting
                                  ? null
                                  : () {
                                      setState(() => _customTargetModelController.text = 'llama3.2:3b');
                                      _syncDraft();
                                    },
                            ),
                            ActionChip(
                              label: const Text('qwen2.5:7b', style: TextStyle(fontSize: 11)),
                              onPressed: _isSubmitting
                                  ? null
                                  : () {
                                      setState(() => _customTargetModelController.text = 'qwen2.5:7b');
                                      _syncDraft();
                                    },
                            ),
                            ActionChip(
                              label: const Text('mistral', style: TextStyle(fontSize: 11)),
                              onPressed: _isSubmitting
                                  ? null
                                  : () {
                                      setState(() => _customTargetModelController.text = 'mistral');
                                      _syncDraft();
                                    },
                            ),
                            ActionChip(
                              label: const Text('gemini-2.5-pro', style: TextStyle(fontSize: 11)),
                              onPressed: _isSubmitting
                                  ? null
                                  : () {
                                      setState(() => _customTargetModelController.text = 'gemini-2.5-pro');
                                      _syncDraft();
                                    },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: const Text('Connect to Custom Endpoint / Local Ollama', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Run offline on your PC via Ollama, vLLM, or OpenRouter', style: TextStyle(fontSize: 11)),
                          value: _useCustomEndpoint,
                          onChanged: _isSubmitting
                              ? null
                              : (v) {
                                  setState(() => _useCustomEndpoint = v);
                                  _syncDraft();
                                },
                        ),
                        if (_useCustomEndpoint) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: _customEndpointController,
                            enabled: !_isSubmitting,
                            keyboardType: TextInputType.url,
                            autocorrect: false,
                            textInputAction: TextInputAction.next,
                            scrollPadding: const EdgeInsets.all(80),
                            decoration: const InputDecoration(
                              labelText: 'Base URL (OpenAI-compatible)',
                              hintText: 'http://localhost:11434/v1',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: Icon(Icons.lan_outlined, size: 18),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              ActionChip(
                                label: const Text('Ollama Local', style: TextStyle(fontSize: 11)),
                                onPressed: _isSubmitting
                                    ? null
                                    : () {
                                        setState(() => _customEndpointController.text = 'http://localhost:11434/v1');
                                        _syncDraft();
                                      },
                              ),
                              ActionChip(
                                label: const Text('vLLM / LocalAI', style: TextStyle(fontSize: 11)),
                                onPressed: _isSubmitting
                                    ? null
                                    : () {
                                        setState(() => _customEndpointController.text = 'http://localhost:8000/v1');
                                        _syncDraft();
                                      },
                              ),
                              ActionChip(
                                label: const Text('OpenRouter', style: TextStyle(fontSize: 11)),
                                onPressed: _isSubmitting
                                    ? null
                                    : () {
                                        setState(() => _customEndpointController.text = 'https://openrouter.ai/api/v1');
                                        _syncDraft();
                                      },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _customApiKeyController,
                            enabled: !_isSubmitting,
                            obscureText: true,
                            keyboardType: TextInputType.visiblePassword,
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: TextInputAction.done,
                            scrollPadding: const EdgeInsets.all(80),
                            decoration: const InputDecoration(
                              labelText: 'API Key (Optional for Ollama)',
                              hintText: 'Leave empty for local Ollama / vLLM',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: Icon(Icons.key_outlined, size: 18),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Judge LLM Selection
                DropdownButtonFormField<String>(
                  initialValue: _judgeModel,
                  decoration: const InputDecoration(
                    labelText: 'Judge / Critic LLM',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.gavel_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'gemini-1.5-flash', child: Text('gemini-1.5-flash (Google Free Tier)')),
                    DropdownMenuItem(value: 'gpt-4o-mini', child: Text('gpt-4o-mini')),
                    DropdownMenuItem(value: 'gpt-4o', child: Text('gpt-4o')),
                    DropdownMenuItem(value: 'mock-judge', child: Text('mock-judge (Offline)')),
                    DropdownMenuItem(value: 'custom', child: Text('Custom Judge Model...')),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() => _judgeModel = val);
                            _syncDraft();
                          }
                        },
                ),

                if (_judgeModel == 'custom') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _customJudgeModelController,
                    enabled: !_isSubmitting,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    scrollPadding: const EdgeInsets.all(80),
                    decoration: const InputDecoration(
                      labelText: 'Custom Judge Model Identifier',
                      hintText: 'e.g. gpt-4o, claude-3-5-sonnet',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: Icon(Icons.security, size: 18),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                const Text('Languages:', style: TextStyle(fontWeight: FontWeight.bold)),
                CheckboxListTile(
                  dense: true,
                  title: const Text('English (EN)'),
                  value: _includeEn,
                  onChanged: _isSubmitting
                      ? null
                      : (v) {
                          setState(() => _includeEn = v ?? false);
                          _syncDraft();
                        },
                ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('Nepali (NE)'),
                  value: _includeNe,
                  onChanged: _isSubmitting
                      ? null
                      : (v) {
                          setState(() => _includeNe = v ?? false);
                          _syncDraft();
                        },
                ),
                const SizedBox(height: 8),
                const Text('Prompt Types:', style: TextStyle(fontWeight: FontWeight.bold)),
                CheckboxListTile(
                  dense: true,
                  title: const Text('Harmful Benchmark Prompts'),
                  value: _includeHarmful,
                  onChanged: _isSubmitting
                      ? null
                      : (v) {
                          setState(() => _includeHarmful = v ?? false);
                          _syncDraft();
                        },
                ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('Benign Benchmark Prompts'),
                  value: _includeBenign,
                  onChanged: _isSubmitting
                      ? null
                      : (v) {
                          setState(() => _includeBenign = v ?? false);
                          _syncDraft();
                        },
                ),
                const Divider(height: 24),
                const Text('Safety Interceptor & Mode:', style: TextStyle(fontWeight: FontWeight.bold)),
                SwitchListTile(
                  dense: true,
                  title: const Text('Enable Bilingual Guardrails'),
                  subtitle: const Text('Regex & heuristic filters for EN/NE'),
                  value: _enableGuardrails,
                  onChanged: _isSubmitting
                      ? null
                      : (v) {
                          setState(() => _enableGuardrails = v);
                          _syncDraft();
                        },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _evaluationMode,
                  decoration: const InputDecoration(
                    labelText: 'Evaluation Mode',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'STATIC', child: Text('Static Baseline (Single-turn)')),
                    DropdownMenuItem(value: 'ADAPTIVE_RED_TEAM', child: Text('Batch Adaptive Red-Team')),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() => _evaluationMode = val);
                            _syncDraft();
                          }
                        },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _defenseStrategy,
                  decoration: const InputDecoration(
                    labelText: 'Mitigation Defense Strategy',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'NONE', child: Text('None (Standard Baseline)')),
                    DropdownMenuItem(value: 'SYSTEM_PROMPT_INOCULATION', child: Text('Bilingual Inoculation')),
                    DropdownMenuItem(value: 'TRANSLATION_PIVOT', child: Text('Cross-Lingual Translation-Pivot')),
                    DropdownMenuItem(value: 'HYBRID', child: Text('Hybrid (Inoculation + Pivot)')),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() {
                              _defenseStrategy = val;
                              if (val == 'TRANSLATION_PIVOT' || val == 'HYBRID') {
                                _enableGuardrails = true;
                              }
                            });
                            _syncDraft();
                          }
                        },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.playlist_add, size: 16),
                  label: const Text('Add Custom Prompt Pair to Benchmark'),
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const CreateCustomPromptDialog(),
                          );
                        },
                ),
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
                      final discard = await DraftService.confirmDiscard(context, formName: 'experiment configuration');
                      if (!discard || !context.mounted) return;
                    }
                    Navigator.pop(context);
                  },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Launch Experiment'),
          ),
        ],
      ),
    );
  }
}
