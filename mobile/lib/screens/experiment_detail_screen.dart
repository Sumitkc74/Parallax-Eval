import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/experiment.dart';
import '../models/analytics.dart';
import '../services/api_service.dart';
import '../utils/error_handler.dart';
import '../widgets/formatted_markdown_view.dart';
import '../widgets/skeleton_loader.dart';
import '../theme/app_theme.dart';
import 'rapid_review_screen.dart';
import 'prompt_inspector_screen.dart';

class ExperimentDetailScreen extends StatefulWidget {
  final String experimentId;

  const ExperimentDetailScreen({Key? key, required this.experimentId}) : super(key: key);

  @override
  State<ExperimentDetailScreen> createState() => _ExperimentDetailScreenState();
}

class _ExperimentDetailScreenState extends State<ExperimentDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Experiment? _experiment;
  RQ1Metrics? _rq1;
  RQ2Metrics? _rq2;
  List<ModelResponseDetail> _responses = [];
  bool _isLoading = true;
  String? _error;
  Timer? _pollTimer;

  // Tab 1 filters
  String _comparisonFilter = 'all'; // 'all', 'divergent', 'harmful', 'benign'
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Tab 3 filter
  bool _showOnlyUnannotated = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_experiment?.status == 'RUNNING' || _experiment?.status == 'PENDING') {
        _silentRefresh();
      } else {
        _pollTimer?.cancel();
      }
    });
  }

  Future<void> _silentRefresh() async {
    try {
      final exp = await ApiService.getExperiment(widget.experimentId);
      final rq1 = await ApiService.getRQ1Analytics(widget.experimentId);
      final rq2 = await ApiService.getRQ2Analytics(widget.experimentId);
      final responses = await ApiService.getExperimentResults(widget.experimentId);

      if (!mounted) return;
      setState(() {
        _experiment = exp;
        _rq1 = rq1;
        _rq2 = rq2;
        _responses = responses;
      });

      if (exp.status == 'COMPLETED' || exp.status == 'FAILED') {
        _pollTimer?.cancel();
      }
    } catch (_) {
      // Ignore background refresh errors
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final exp = await ApiService.getExperiment(widget.experimentId);
      final rq1 = await ApiService.getRQ1Analytics(widget.experimentId);
      final rq2 = await ApiService.getRQ2Analytics(widget.experimentId);
      final responses = await ApiService.getExperimentResults(widget.experimentId);

      setState(() {
        _experiment = exp;
        _rq1 = rq1;
        _rq2 = rq2;
        _responses = responses;
        _isLoading = false;
      });

      if (exp.status == 'RUNNING' || exp.status == 'PENDING') {
        _startPolling();
      }
    } catch (e) {
      setState(() {
        _error = AppErrorHandler.toHumanReadable(e, actionContext: 'loading experiment evaluation data');
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $label to clipboard'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAnnotationDialog(String responseId, String promptText, String responseText) {
    String selectedLabel = 'Safe Refusal';
    final notesController = TextEditingController();
    final annotatorController = TextEditingController(text: 'researcher_1');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Human Safety Review'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Prompt:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(promptText, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 10),
                const Text('Target LLM Response:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 180),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: responseText.isEmpty
                      ? const Text(
                          '(No response output recorded)',
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                        )
                      : FormattedMarkdownView(
                          data: responseText,
                          textStyle: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                        ),
                ),
                const Divider(height: 24),
                TextField(
                  controller: annotatorController,
                  decoration: const InputDecoration(labelText: 'Annotator ID', isDense: true),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedLabel,
                  decoration: const InputDecoration(labelText: 'Human Label', isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'Safe Refusal', child: Text('Safe Refusal')),
                    DropdownMenuItem(value: 'Partial Compliance', child: Text('Partial Compliance')),
                    DropdownMenuItem(value: 'Unsafe Compliance', child: Text('Unsafe Compliance')),
                    DropdownMenuItem(value: 'Appropriate Compliance', child: Text('Appropriate Compliance')),
                    DropdownMenuItem(value: 'Over-Refusal', child: Text('Over-Refusal')),
                    DropdownMenuItem(value: 'Ambiguous', child: Text('Ambiguous')),
                  ],
                  onChanged: (v) => setDlgState(() => selectedLabel = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes (Optional)', isDense: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(ctx);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ApiService.submitHumanAnnotation(
                    responseId: responseId,
                    annotatorId: annotatorController.text.trim(),
                    humanLabel: selectedLabel,
                    notes: notesController.text.trim(),
                  );
                  navigator.pop();
                  if (mounted) {
                    _loadData();
                  }
                } catch (err) {
                  messenger.showSnackBar(SnackBar(content: Text('Error: $err')));
                }
              },
              child: const Text('Save Review'),
            )
          ],
        ),
      ),
    );
  }

  Color _getLabelColor(String? label) {
    if (label == null) return Colors.grey;
    if (label.contains('Safe Refusal') || label.contains('Appropriate Compliance')) return Colors.green.shade700;
    if (label.contains('Unsafe Compliance')) return Colors.red.shade700;
    if (label.contains('Over-Refusal')) return Colors.orange.shade800;
    return Colors.blueGrey;
  }

  void _showExportInfo() {
    final url = ApiService.getExportCsvUrl(widget.experimentId);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Experiment Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Download complete evaluation results, judge reasoning, and human reviews in CSV format:'),
            const SizedBox(height: 12),
            SelectableText(url, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  String _formatDefenseStrategy(String? strategy) {
    switch (strategy) {
      case 'SYSTEM_PROMPT_INOCULATION':
        return 'Bilingual Inoculation';
      case 'TRANSLATION_PIVOT':
        return 'Translation-Pivot Guardrail';
      case 'HYBRID':
        return 'Hybrid (Inoculation + Pivot)';
      case 'NONE':
      default:
        return 'Baseline (None)';
    }
  }

  Color _getDefenseColor(String? strategy) {
    switch (strategy) {
      case 'SYSTEM_PROMPT_INOCULATION':
        return Colors.blue.shade800;
      case 'TRANSLATION_PIVOT':
        return Colors.teal.shade800;
      case 'HYBRID':
        return Colors.purple.shade800;
      case 'NONE':
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> _showRemediationDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        elevation: 0,
        backgroundColor: AppThemeColors.cardBg(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: AppThemeColors.border(context)),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Analyzing Experiment Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              SizedBox(height: 6),
              Text('Synthesizing remediation actions and DPO pairs...', style: TextStyle(fontSize: 12, color: Color(0xFF5A6675))),
              SizedBox(height: 14),
              LinearProgressIndicator(minHeight: 3, backgroundColor: Color(0xFFE9ECEF), color: Color(0xFF1A283B)),
            ],
          ),
        ),
      ),
    );

    try {
      final report = await ApiService.fetchRemediationReport(widget.experimentId);
      if (!mounted) return;
      Navigator.of(context).pop(); // Dismiss loading

      final dpoUrl = ApiService.getExportDpoUrl(widget.experimentId);
      final totalFailures = report['total_failures'] ?? 0;
      final crossLingualGap = report['cross_lingual_gap_count'] ?? 0;
      final actionItems = (report['mitigation_action_items'] as List<dynamic>?) ?? [];
      final sysPrompt = (report['recommended_system_prompt_patch'] as String?) ?? '';
      final dpoCount = ((report['dpo_dataset'] as List<dynamic>?) ?? []).length;
      final categories = (report['vulnerable_categories'] as List<dynamic>?) ?? [];

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(color: Color(0xFFE2E4E8)),
          ),
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFF1A283B)),
              SizedBox(width: 8),
              Expanded(child: Text('Automated Remediation Advisor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF1F1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE8C8C8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'SAFETY FAILURES DETECTED',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: Color(0xFF8A2C2C),
                              ),
                            ),
                            Text(
                              '$totalFailures total',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8A2C2C),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Cross-lingual safety gap: $crossLingualGap evaluations',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF1E242B)),
                              ),
                            ),
                            Text(
                              'DPO training pairs: $dpoCount',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A283B)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (categories.isNotEmpty) ...[
                    const Text('Vulnerable Categories:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    ...categories.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red.shade700),
                          const SizedBox(width: 6),
                          Expanded(
                            child: FormattedInlineText(
                              text: '**${c['category']}**: ${c['failure_count']} fails (${((c['vulnerability_rate'] ?? 0) * 100).toStringAsFixed(0)}%)',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 12),
                  ],
                  const Text('Mitigation Action Items:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  if (actionItems.isEmpty)
                    const Text('(None)', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey))
                  else
                    ...actionItems.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: FormattedInlineText(
                              text: item.toString(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    )),
                  const SizedBox(height: 12),
                  if (sysPrompt.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Recommended System Prompt Patch:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 16),
                          tooltip: 'Copy Prompt',
                          onPressed: () => _copyToClipboard(sysPrompt, 'System Prompt Patch'),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: SelectableText(
                        sysPrompt,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Text('DPO Dataset Direct Export URL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  SelectableText(dpoUrl, style: const TextStyle(fontSize: 11, color: Colors.indigo, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Copy DPO Link'),
              onPressed: () {
                _copyToClipboard(dpoUrl, 'DPO Export Link');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load remediation report: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showExecutiveReportDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        elevation: 0,
        backgroundColor: AppThemeColors.cardBg(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: AppThemeColors.border(context)),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Generating Executive Audit Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              SizedBox(height: 6),
              Text('Compiling methodology, metrics, and risk analysis...', style: TextStyle(fontSize: 12, color: Color(0xFF5A6675))),
              SizedBox(height: 14),
              LinearProgressIndicator(minHeight: 3, backgroundColor: Color(0xFFE9ECEF), color: Color(0xFF1A283B)),
            ],
          ),
        ),
      ),
    );

    try {
      final reportMd = await ApiService.fetchExecutiveReportMarkdown(widget.experimentId);
      final reportUrl = ApiService.getExportReportMarkdownUrl(widget.experimentId);
      if (!mounted) return;
      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(color: Color(0xFFE2E4E8)),
          ),
          title: const Row(
            children: [
              Icon(Icons.description_outlined, color: Color(0xFF1A283B)),
              SizedBox(width: 8),
              Expanded(child: Text('Executive Safety Audit Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.7,
            child: FormattedMarkdownView(
              data: reportMd,
              padding: const EdgeInsets.symmetric(vertical: 4),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy Markdown'),
              onPressed: () {
                _copyToClipboard(reportMd, 'Executive Report');
                Navigator.pop(ctx);
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.link, size: 16),
              label: const Text('Copy URL'),
              onPressed: () {
                _copyToClipboard(reportUrl, 'Report URL');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load executive report: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cloneExperiment() async {
    try {
      final cloned = await ApiService.cloneExperiment(widget.experimentId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cloned and launched run: "${cloned.name}"')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cloning experiment: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cancelExperiment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Evaluation?'),
        content: const Text('Halt ongoing evaluation for this experiment? Completed evaluations will be preserved.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Running')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Run'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.cancelExperiment(widget.experimentId);
        _loadData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evaluation cancelled gracefully.')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteExperiment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Experiment?'),
        content: const Text('Are you sure you want to delete this experiment and all its responses?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteExperiment(widget.experimentId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Experiment deleted.')),
        );
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = _experiment?.status == 'RUNNING' || _experiment?.status == 'PENDING';
    final isWide = MediaQuery.of(context).size.width >= 600;

    return Title(
      title: 'Parallax-Eval | ${_experiment?.name ?? "Experiment Details"}',
      color: const Color(0xFF1A283B),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_experiment?.name ?? 'Experiment Details'),
          actions: [
            if (isWide) ...[
              IconButton(
                icon: const Icon(Icons.description_outlined),
                tooltip: 'Executive Safety Audit Report',
                onPressed: _showExecutiveReportDialog,
              ),
              IconButton(
                icon: const Icon(Icons.shield_outlined),
                tooltip: 'Remediation Advisor & DPO Dataset',
                onPressed: _showRemediationDialog,
              ),
              IconButton(
                icon: const Icon(Icons.file_download),
                tooltip: 'Export CSV',
                onPressed: _showExportInfo,
              ),
            ],
            IconButton(
              icon: isRunning
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _loadData,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (val) {
                if (val == 'report') _showExecutiveReportDialog();
                if (val == 'remediation') _showRemediationDialog();
                if (val == 'export') _showExportInfo();
                if (val == 'cancel') _cancelExperiment();
                if (val == 'clone') _cloneExperiment();
                if (val == 'delete') _deleteExperiment();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.description_outlined, size: 16, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text('Executive Audit Report'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remediation',
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 16, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text('Remediation & DPO'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.file_download, size: 16, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text('Export CSV'),
                    ],
                  ),
                ),
              if (isRunning)
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, size: 16, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Cancel Evaluation', style: TextStyle(color: Colors.orange)),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'clone',
                child: Row(
                  children: [
                    Icon(Icons.copy, size: 16, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text('Clone & Re-run'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Experiment', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.compare_arrows), text: 'RQ1 Comparisons'),
            Tab(icon: Icon(Icons.analytics), text: 'RQ1 Analytics'),
            Tab(icon: Icon(Icons.verified_user), text: 'RQ2 Multi-Agent Verification'),
          ],
        ),
      ),
      body: _isLoading
          ? const SkeletonDashboard()
          : _error != null
              ? Center(child: Text('Error loading data: $_error'))
              : Column(
                  children: [
                    if (isRunning)
                      LinearProgressIndicator(
                        value: (_experiment?.totalPrompts ?? 0) > 0
                            ? (_experiment!.completedPrompts / _experiment!.totalPrompts)
                            : null,
                        backgroundColor: Colors.blue.shade100,
                        color: Colors.blue.shade800,
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getDefenseColor(_experiment?.defenseStrategy).withAlpha(30),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _getDefenseColor(_experiment?.defenseStrategy)),
                            ),
                            child: Text(
                              _formatDefenseStrategy(_experiment?.defenseStrategy),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _getDefenseColor(_experiment?.defenseStrategy),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Target: ${_experiment?.targetModel ?? "N/A"}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            ),
                            icon: const Icon(Icons.auto_fix_high, size: 14),
                            label: const Text('Remediation Advisor', style: TextStyle(fontSize: 11)),
                            onPressed: _showRemediationDialog,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildComparisonsTab(),
                          _buildRQ1Tab(),
                          _buildRQ2Tab(),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildComparisonsTab() {
    final allComparisons = _rq1?.comparisons ?? [];
    if (allComparisons.isEmpty) {
      return const Center(child: Text('No comparison results available yet.'));
    }

    final divergentCount = allComparisons.where((c) => c.isSafetyDivergent).length;
    final harmfulCount = allComparisons.where((c) => c.promptType == 'harmful').length;
    final benignCount = allComparisons.where((c) => c.promptType == 'benign').length;

    // Apply filter
    final filtered = allComparisons.where((c) {
      if (_comparisonFilter == 'divergent' && !c.isSafetyDivergent) return false;
      if (_comparisonFilter == 'harmful' && c.promptType != 'harmful') return false;
      if (_comparisonFilter == 'benign' && c.promptType != 'benign') return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesSource = c.sourceId.toLowerCase().contains(q);
        final matchesCat = c.category.toLowerCase().contains(q);
        final matchesEn = c.enPrompt.toLowerCase().contains(q);
        final matchesNe = c.nePrompt.toLowerCase().contains(q);
        return matchesSource || matchesCat || matchesEn || matchesNe;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Search & Filter Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.grey.shade100,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search behavior ID, category, or prompt...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: AppThemeColors.cardBg(context),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('All (${allComparisons.length})'),
                      selected: _comparisonFilter == 'all',
                      onSelected: (_) => setState(() => _comparisonFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning, size: 14, color: Colors.red),
                          const SizedBox(width: 4),
                          Text('Divergent ($divergentCount)'),
                        ],
                      ),
                      selected: _comparisonFilter == 'divergent',
                      selectedColor: Colors.red.shade100,
                      onSelected: (_) => setState(() => _comparisonFilter = 'divergent'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('Harmful ($harmfulCount)'),
                      selected: _comparisonFilter == 'harmful',
                      onSelected: (_) => setState(() => _comparisonFilter = 'harmful'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('Benign ($benignCount)'),
                      selected: _comparisonFilter == 'benign',
                      onSelected: (_) => setState(() => _comparisonFilter = 'benign'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List View
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No behaviors match the current filter.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final c = filtered[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(
                          color: c.isSafetyDivergent ? const Color(0xFF8A2C2C) : const Color(0xFFE2E4E8),
                          width: c.isSafetyDivergent ? 1.5 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${c.sourceId} • ${c.category}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A283B))),
                                Chip(
                                  label: Text(c.promptType.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                  backgroundColor: c.promptType == 'harmful' ? const Color(0xFF8A2C2C) : const Color(0xFF245E43),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ],
                            ),
                            if (c.isSafetyDivergent)
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFBF1F1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFFE8C8C8)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Color(0xFF8A2C2C), size: 16),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Safety Discordance: Model complied in Nepali while refusing in English',
                                        style: TextStyle(color: Color(0xFF8A2C2C), fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const Divider(),
                            // English Block
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('English Variant:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.shield_outlined, size: 16, color: Colors.indigo),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: 'Test English prompt in Live Safety Inspector',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PromptInspectorScreen(
                                              initialPrompt: c.enPrompt,
                                              initialPromptType: c.promptType,
                                              initialDefenseStrategy: _experiment?.defenseStrategy,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: 'Copy English prompt',
                                      onPressed: () => _copyToClipboard(c.enPrompt, 'English prompt'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Text(c.enPrompt, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text('Label: ', style: TextStyle(fontSize: 12)),
                                Text(c.enLabel ?? 'Pending', style: TextStyle(fontWeight: FontWeight.bold, color: _getLabelColor(c.enLabel))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Nepali Block
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Nepali Variant:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.shield_outlined, size: 16, color: Colors.deepOrange),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: 'Test Nepali prompt in Live Safety Inspector',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PromptInspectorScreen(
                                              initialPrompt: c.nePrompt,
                                              initialPromptType: c.promptType,
                                              initialDefenseStrategy: _experiment?.defenseStrategy,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: 'Copy Nepali prompt',
                                      onPressed: () => _copyToClipboard(c.nePrompt, 'Nepali prompt'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Text(c.nePrompt, style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text('Label: ', style: TextStyle(fontSize: 12)),
                                Text(c.neLabel ?? 'Pending', style: TextStyle(fontWeight: FontWeight.bold, color: _getLabelColor(c.neLabel))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRQ1Tab() {
    final en = _rq1?.enMetrics;
    final ne = _rq1?.neMetrics;
    final delta = _rq1?.delta;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.indigo.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('RQ1: Cross-Lingual Safety Parity Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo)),
                  const SizedBox(height: 8),
                  Text('Target Model: ${_rq1?.targetModel ?? "N/A"}'),
                  Text('Safety Divergent Behaviors: ${_rq1?.divergentBehaviorCount ?? 0}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Cross-Lingual Comparison Bars:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _metricRow('Harmful Refusal Rate (HRR)', en?.harmfulRefusalRate, ne?.harmfulRefusalRate, delta?.deltaHrr),
          _metricRow('Unsafe Compliance Rate (UCR)', en?.unsafeComplianceRate, ne?.unsafeComplianceRate, delta?.deltaUcr),
          _metricRow('Benign Compliance Rate (BCR)', en?.benignComplianceRate, ne?.benignComplianceRate, delta?.deltaBcr),
          _metricRow('Over-Refusal Rate (ORR)', en?.overRefusalRate, ne?.overRefusalRate, delta?.deltaOrr),
          if ((_rq1?.categoryBreakdown ?? []).isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Vulnerability Gap by Threat Category:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildCategoryBreakdownSection(_rq1!.categoryBreakdown),
          ],
          if (_rq1?.performanceMetrics != null) ...[
            const SizedBox(height: 20),
            const Text('Language Tax & System Performance:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildPerformanceCard(_rq1!.performanceMetrics!),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdownSection(List<CategoryDisparityMetric> categories) {
    return Column(
      children: categories.map((cat) {
        final isCritical = cat.riskLevel == 'CRITICAL';
        final isElevated = cat.riskLevel == 'ELEVATED';
        final riskColor = isCritical
            ? Colors.red
            : isElevated
                ? Colors.orange.shade800
                : Colors.green.shade700;
        final riskBg = isCritical
            ? Colors.red.shade50
            : isElevated
                ? Colors.orange.shade50
                : Colors.green.shade50;
        final riskIcon = isCritical
            ? Icons.error_outline
            : isElevated
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: riskColor.withAlpha(80)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              _searchController.text = cat.category;
              setState(() {
                _searchQuery = cat.category;
              });
              _tabController.animateTo(0);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Filtered comparisons by "${cat.category}"'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                cat.category,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A283B)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF1A283B)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: riskBg,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: riskColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(riskIcon, size: 12, color: riskColor),
                            const SizedBox(width: 4),
                            Text(
                              cat.riskLevel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: riskColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Unsafe Compliance (UCR):',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                        ),
                      ),
                      Text(
                        'EN ${(cat.enUcr * 100).toStringAsFixed(1)}% vs NE ${(cat.neUcr * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(Δ ${(cat.deltaUcr * 100).toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: cat.deltaUcr > 0.05 ? const Color(0xFF8A2C2C) : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Harmful Refusal Rate (HRR):',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                        ),
                      ),
                      Text(
                        'EN ${(cat.enHrr * 100).toStringAsFixed(1)}% vs NE ${(cat.neHrr * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: cat.totalPrompts > 0 ? (cat.neUcr).clamp(0.0, 1.0) : 0.0,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFE9ECEF),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        cat.neUcr > 0.3 ? const Color(0xFF8A2C2C) : (cat.neUcr > 0.1 ? const Color(0xFF8A5D00) : const Color(0xFF245E43)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${cat.divergentCount} cross-lingual safety divergence${cat.divergentCount == 1 ? '' : 's'} (${cat.totalPrompts} evaluated prompts)',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                      const Text(
                        'View comparisons ->',
                        style: TextStyle(fontSize: 10, color: Color(0xFF1A283B), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPerformanceCard(SystemPerformanceMetrics perf) {
    final taxHigh = perf.tokenInflationRatio > 1.2;

    return Card(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tokenization Tax (Sub-word Fragmentation)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: taxHigh ? const Color(0xFFFFF7ED) : const Color(0xFFEAF5EA),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: taxHigh ? const Color(0xFFFDBA74) : const Color(0xFFA7D7A9)),
                  ),
                  child: Text(
                    '${perf.tokenInflationRatio.toStringAsFixed(2)}x Tokens',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: taxHigh ? const Color(0xFF8A5D00) : const Color(0xFF245E43)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Nepali prompts required ${perf.tokenInflationRatio.toStringAsFixed(2)}x more sub-word tokens than English for equivalent semantic intent.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E242B)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFE2E4E8)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('English Latency', style: TextStyle(fontSize: 10, color: Color(0xFF5A6675))),
                        Text('${perf.enAvgLatencyMs.toStringAsFixed(0)} ms', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E242B))),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 26, color: const Color(0xFFE2E4E8)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nepali Latency', style: TextStyle(fontSize: 10, color: Color(0xFF5A6675))),
                        Text('${perf.neAvgLatencyMs.toStringAsFixed(0)} ms', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF8A2C2C))),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 26, color: const Color(0xFFE2E4E8)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Tokens', style: TextStyle(fontSize: 10, color: Color(0xFF5A6675))),
                        Text('${perf.totalTokensConsumed}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A283B))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricRow(String title, double? enVal, double? neVal, double? deltaVal) {
    final en = (enVal ?? 0.0).clamp(0.0, 1.0);
    final ne = (neVal ?? 0.0).clamp(0.0, 1.0);
    final delta = (deltaVal ?? 0.0);
    final isDisparate = delta.abs() > 0.10;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDisparate ? const Color(0xFFFBF1F1) : const Color(0xFFF4F5F7),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: isDisparate ? const Color(0xFFE8C8C8) : const Color(0xFFE2E4E8)),
                  ),
                  child: Text(
                    'Δ ${(delta * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDisparate ? const Color(0xFF8A2C2C) : const Color(0xFF1E242B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // English Bar
            Row(
              children: [
                const SizedBox(width: 75, child: Text('English (EN)', style: TextStyle(fontSize: 11, color: Colors.grey))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: en,
                      minHeight: 10,
                      backgroundColor: Colors.blue.shade50,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(width: 45, child: Text('${(en * 100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
            const SizedBox(height: 8),
            // Nepali Bar
            Row(
              children: [
                const SizedBox(width: 75, child: Text('Nepali (NE)', style: TextStyle(fontSize: 11, color: Colors.grey))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ne,
                      minHeight: 10,
                      backgroundColor: Colors.deepOrange.shade50,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(width: 45, child: Text('${(ne * 100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRQ2Tab() {
    final rq2 = _rq2;
    final displayedResponses = _showOnlyUnannotated
        ? _responses.where((r) => r.annotations.isEmpty).toList()
        : _responses;

    final unannotatedCount = _responses.where((r) => r.annotations.isEmpty).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.teal.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('RQ2: Multi-Agent Reliability & Human Agreement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal)),
                  const SizedBox(height: 8),
                  Text('Total Automated Evaluations: ${rq2?.totalAutomatedEvaluations ?? 0}'),
                  Text('Critic Revision Rate: ${((rq2?.criticRevisionRate ?? 0) * 100).toStringAsFixed(1)}% (${rq2?.criticRevisedCount ?? 0} revised)'),
                  const Divider(),
                  Text('Human Validated Responses: ${rq2?.totalHumanAnnotated ?? 0}'),
                  Text('Raw Agreement Rate: ${((rq2?.rawAgreementRate ?? 0) * 100).toStringAsFixed(1)}%'),
                  Text("Cohen's Kappa (κ): ${rq2?.cohensKappa != null ? rq2!.cohensKappa!.toStringAsFixed(3) : 'N/A (< 2 annotations)'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          Card(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: Color(0xFF1E3A8A), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Fast Human Review Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Review $unannotatedCount unannotated response${unannotatedCount == 1 ? '' : 's'} with 1-tap rating buttons.', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                    onPressed: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RapidReviewScreen(
                            experimentId: widget.experimentId,
                            responses: _responses,
                          ),
                        ),
                      );
                      if (updated == true) _loadData();
                    },
                    child: const Text('Start'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Annotate Model Responses:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              FilterChip(
                label: Text('Unannotated ($unannotatedCount)'),
                selected: _showOnlyUnannotated,
                onSelected: (val) => setState(() => _showOnlyUnannotated = val),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (displayedResponses.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: Text('No responses match current annotation filter.')),
            )
          else
            ...displayedResponses.map((r) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(r.promptText, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Verdict: ${r.finalLabel ?? "Pending"} • Critic: ${r.criticRecommendation ?? "CONFIRM"}', style: TextStyle(fontSize: 11, color: _getLabelColor(r.finalLabel))),
                        if (r.guardrailIntervened || r.redTeamAttempts.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Wrap(
                              spacing: 6,
                              children: [
                                if (r.guardrailIntervened)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: const Color(0xFFE8EEF5), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFBAC7D5))),
                                    child: const Text('Guardrail Intercepted', style: TextStyle(fontSize: 10, color: Color(0xFF1A283B), fontWeight: FontWeight.bold)),
                                  ),
                                if (r.redTeamAttempts.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFFDBA74))),
                                    child: Text('${r.redTeamAttempts.length} Attack Rounds', style: const TextStyle(fontSize: 10, color: Color(0xFF8A5D00), fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
                          tooltip: 'Copy response',
                          onPressed: () => _copyToClipboard(r.responseText, 'model response'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10), visualDensity: VisualDensity.compact),
                          onPressed: () => _showAnnotationDialog(r.id, r.promptText, r.responseText),
                          child: Text(r.annotations.isEmpty ? 'Annotate' : 'Edit (${r.annotations.length})'),
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
