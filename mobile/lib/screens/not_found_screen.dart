import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NotFoundScreen extends StatelessWidget {
  final String? routeName;

  const NotFoundScreen({Key? key, this.routeName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final canvasColor = AppThemeColors.scaffoldBg(context);
    final primarySlate = AppThemeColors.isDark(context) ? const Color(0xFF3B82F6) : const Color(0xFF1A283B);
    final borderColor = AppThemeColors.border(context);
    final mutedText = AppThemeColors.textMuted(context);
    final charcoalText = AppThemeColors.textPrimary(context);
    final cardBg = AppThemeColors.cardBg(context);

    return Title(
      title: '404 - Page Not Found | Parallax-Eval',
      color: primarySlate,
      child: Scaffold(
        backgroundColor: canvasColor,
        appBar: AppBar(
          backgroundColor: canvasColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            'Parallax-Eval',
            style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.bold, fontSize: 18, color: charcoalText),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: charcoalText),
            tooltip: 'Return to Safety Dashboard',
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Card(
                elevation: 0,
                color: cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(color: borderColor, width: 1.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppThemeColors.isDark(context) ? const Color(0xFF3D1B1B) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppThemeColors.isDark(context) ? const Color(0xFF9B2C2C) : const Color(0xFFFCA5A5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'HTTP 404',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppThemeColors.isDark(context) ? const Color(0xFFFEB2B2) : const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Benchmark Route Not Found',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: charcoalText,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        routeName != null && routeName!.isNotEmpty
                            ? 'The requested safety benchmark resource at "$routeName" could not be located on this node.'
                            : 'The requested evaluation route does not exist or has been relocated.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: mutedText,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Divider(color: borderColor),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primarySlate,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            icon: const Icon(Icons.dashboard_outlined, size: 16),
                            label: const Text('Return to Safety Dashboard'),
                            onPressed: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                Navigator.pushReplacementNamed(context, '/');
                              }
                            },
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: charcoalText,
                              side: BorderSide(color: borderColor),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            icon: const Icon(Icons.bug_report_outlined, size: 16),
                            label: const Text('File Route Discrepancy'),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Discrepancy logged for local engine telemetry.')),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
