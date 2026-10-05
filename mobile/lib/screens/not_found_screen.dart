import 'package:flutter/material.dart';

class NotFoundScreen extends StatelessWidget {
  final String? routeName;

  const NotFoundScreen({Key? key, this.routeName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const canvasColor = Color(0xFFF8F8F6);
    const primarySlate = Color(0xFF1A283B);
    const borderColor = Color(0xFFE2E4E8);
    const mutedText = Color(0xFF5A6675);
    const charcoalText = Color(0xFF1E242B);

    return Title(
      title: '404 - Page Not Found | Parallax-Eval',
      color: primarySlate,
      child: Scaffold(
        backgroundColor: canvasColor,
        appBar: AppBar(
          backgroundColor: canvasColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text('Parallax-Eval', style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.bold, fontSize: 18)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
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
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: const BorderSide(color: borderColor, width: 1.0),
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
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
                        ),
                        child: const Text(
                          'HTTP 404',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
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
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: mutedText,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: borderColor),
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
                              Navigator.pushReplacementNamed(context, '/');
                            },
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primarySlate,
                              side: const BorderSide(color: borderColor, width: 1.0),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            icon: const Icon(Icons.arrow_back, size: 16),
                            label: const Text('Back to Previous Screen'),
                            onPressed: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                Navigator.pushReplacementNamed(context, '/');
                              }
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

