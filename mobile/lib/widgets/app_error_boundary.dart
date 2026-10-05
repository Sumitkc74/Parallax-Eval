import 'package:flutter/material.dart';

class AppErrorBoundaryWidget extends StatelessWidget {
  final FlutterErrorDetails details;

  const AppErrorBoundaryWidget({Key? key, required this.details}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF9F9FB),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E4E8)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 40, color: Color(0xFFB0895D)),
                  const SizedBox(height: 16),
                  const Text(
                    'Visual Display Error',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A283B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A rendering issue occurred while displaying this view. Your session and data remain intact.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF5A6675), height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A283B),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      // Restart or pop to root if possible
                    },
                    child: const Text('Reload Interface'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
