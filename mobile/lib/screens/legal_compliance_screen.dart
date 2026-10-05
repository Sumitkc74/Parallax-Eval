import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/formatted_markdown_view.dart';
import '../widgets/skeleton_loader.dart';

class LegalComplianceScreen extends StatefulWidget {
  final int initialTabIndex;

  const LegalComplianceScreen({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  State<LegalComplianceScreen> createState() => _LegalComplianceScreenState();
}

class _LegalComplianceScreenState extends State<LegalComplianceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _legalSummary;
  Map<String, dynamic>? _consentInfo;
  String? _privacyPolicyText;
  String? _termsOfServiceText;
  String? _licensesText;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 4),
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final summaryFuture = ApiService.fetchLegalSummary();
      final consentFuture = ApiService.fetchConsentInfo();
      final privacyFuture = ApiService.fetchLegalDocument('privacy-policy');
      final termsFuture = ApiService.fetchLegalDocument('terms-of-service');
      final licensesFuture = ApiService.fetchLegalDocument('licenses');

      final results = await Future.wait([
        summaryFuture,
        consentFuture,
        privacyFuture,
        termsFuture,
        licensesFuture,
      ]);

      if (!mounted) return;
      setState(() {
        _legalSummary = results[0] as Map<String, dynamic>;
        _consentInfo = results[1] as Map<String, dynamic>;
        _privacyPolicyText = results[2] as String;
        _termsOfServiceText = results[3] as String;
        _licensesText = results[4] as String;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Title(
      title: 'Parallax-Eval | Governance, Legal & Compliance',
      color: const Color(0xFF1A283B),
      child: Scaffold(
        appBar: AppBar(
        title: const Text('Governance, Legal and Compliance Hub'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF1A283B),
          labelColor: const Color(0xFF1A283B),
          unselectedLabelColor: const Color(0xFF5A6675),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
          tabs: const [
            Tab(text: 'Compliance Overview'),
            Tab(text: 'Privacy Policy'),
            Tab(text: 'Terms of Service'),
            Tab(text: 'Research Disclaimers'),
            Tab(text: 'Licenses and SBOM'),
          ],
        ),
      ),
      body: _isLoading
          ? const SkeletonLoader(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SkeletonCard(),
                    SizedBox(height: 12),
                    SkeletonCard(),
                  ],
                ),
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E4E8)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Documentation Load Error', style: TextStyle(fontFamily: 'Georgia', fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Could not load documentation: $_error', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFF5A6675))),
                          const SizedBox(height: 14),
                          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildTextDocTab(_privacyPolicyText ?? 'No Privacy Policy found.'),
                    _buildTextDocTab(_termsOfServiceText ?? 'No Terms of Service found.'),
                    _buildDisclaimersTab(),
                    _buildTextDocTab(_licensesText ?? 'No License info found.'),
                  ],
                ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final summary = _legalSummary ?? {};
    final standards = (summary['compliance_standards'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Platform Governance Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E4E8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      summary['platform_name'] ?? 'Parallax-Eval',
                      style: const TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A283B)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF4F0),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: const Color(0xFFCFE2D7)),
                      ),
                      child: const Text('Audited Open Source', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF245E43))),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'License: ${summary['license'] ?? 'Apache 2.0'} | Version: ${summary['version'] ?? '1.0.0'}',
                  style: const TextStyle(color: Color(0xFF5A6675), fontSize: 12),
                ),
                const Divider(),
                _buildMetaRow('Age Restriction', summary['age_restriction'] ?? '18+'),
                const SizedBox(height: 8),
                _buildMetaRow(
                  'Cookie Consent',
                  summary['cookie_consent_required'] == false
                      ? 'Not Required (Zero tracking or advertising cookies deployed)'
                      : 'Required',
                ),
                const SizedBox(height: 8),
                _buildMetaRow('Zero-PII Policy', summary['zero_pii_rule'] ?? 'Strictly enforced'),
                const SizedBox(height: 8),
                _buildMetaRow('Billing Policy', summary['refund_cancellation_policy'] ?? 'Free open-source scientific tool'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Compliance Standards Table
          const Text(
            'Audited Compliance Frameworks',
            style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A283B)),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E4E8)),
            ),
            child: Table(
              border: TableBorder(
                horizontalInside: BorderSide(color: Colors.grey.shade200, width: 0.8),
              ),
              children: standards.map((s) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Text(s.toString(), style: const TextStyle(fontSize: 12, height: 1.4)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Data Subject Rights & Consent Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E4E8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Subject Rights',
                  style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A283B)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'In accordance with Articles 16 & 17 of GDPR and Section 8 of the Nepal Privacy Act 2075:',
                  style: TextStyle(fontSize: 12, color: Color(0xFF5A6675)),
                ),
                const SizedBox(height: 10),
                if (_consentInfo != null && _consentInfo!['data_subject_rights'] != null)
                  ...((_consentInfo!['data_subject_rights'] as List<dynamic>).map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: FormattedInlineText(
                        text: '• ${r.toString()}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF1E242B)),
                      ),
                    ),
                  ))
                else ...const [
                  FormattedInlineText(
                    text: '• **Right to Rectification**: Correct custom prompt text via `PUT /api/v1/behaviors/{id}`',
                    style: TextStyle(fontSize: 12, color: Color(0xFF1E242B)),
                  ),
                  SizedBox(height: 4),
                  FormattedInlineText(
                    text: '• **Right to Erasure**: Permanently delete custom prompt pairs via `DELETE /api/v1/behaviors/{id}`',
                    style: TextStyle(fontSize: 12, color: Color(0xFF1E242B)),
                  ),
                  SizedBox(height: 4),
                  FormattedInlineText(
                    text: '• **Right to Portability**: Export complete evaluation runs via CSV or JSON',
                    style: TextStyle(fontSize: 12, color: Color(0xFF1E242B)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimersTab() {
    final disclaimers = (_legalSummary?['disclaimers'] as List<dynamic>?) ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F2E8),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE6D9C5)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scientific and Research Disclaimers',
                style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF7D5518)),
              ),
              SizedBox(height: 4),
              Text(
                'Parallax-Eval is designed solely for empirical safety benchmarking and alignment auditing. Model outputs must not be operationalized for harmful actions.',
                style: TextStyle(fontSize: 12, color: Color(0xFF1E242B), height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...disclaimers.map((d) {
          final parts = d.toString().split(':');
          final title = parts.isNotEmpty ? parts[0] : '';
          final body = parts.length > 1 ? parts.sublist(1).join(':').trim() : '';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E4E8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FormattedInlineText(
                  text: title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A283B)),
                ),
                const SizedBox(height: 4),
                FormattedInlineText(
                  text: body.isNotEmpty ? body : d.toString(),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF5A6675), height: 1.4),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTextDocTab(String content) {
    if (content.isEmpty) {
      return const Center(
        child: Text('(No document content available)', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
      );
    }
    return FormattedMarkdownView(
      data: content,
      padding: const EdgeInsets.all(16),
    );
  }

  Widget _buildMetaRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text('$title:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF1A283B))),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF5A6675))),
        ),
      ],
    );
  }
}
