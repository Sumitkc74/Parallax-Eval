import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/not_found_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'widgets/app_error_boundary.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Problem 2: Add friendly fallback Error Boundary so visual crashes never blank the screen
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return AppErrorBoundaryWidget(details: details);
  };

  runApp(const ParallaxEvalApp());
}

class ParallaxEvalApp extends StatelessWidget {
  const ParallaxEvalApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Problem 4: Adapt dynamically to system preferences and user toggle
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Parallax-Eval | Cross-Lingual AI Safety Benchmark & Red-Teaming',
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          routes: {
            '/': (context) => const DashboardScreen(),
            '/dashboard': (context) => const DashboardScreen(),
          },
          onUnknownRoute: (settings) => MaterialPageRoute(
            builder: (_) => NotFoundScreen(routeName: settings.name),
            settings: settings,
          ),
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeController.instance.themeMode,
        );
      },
    );
  }
}
