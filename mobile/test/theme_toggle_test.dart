import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/screens/dashboard_screen.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/theme/theme_controller.dart';

void main() {
  testWidgets('ThemeController toggles cleanly between Light and Dark mode', (WidgetTester tester) async {
    // Reset to system or light
    ThemeController.instance.setThemeMode(ThemeMode.light);

    await tester.pumpWidget(const ParallaxEvalApp());
    await tester.pumpAndSettle();

    final BuildContext lightCtx = tester.element(find.byType(DashboardScreen));
    expect(AppThemeColors.isDark(lightCtx), isFalse);
    expect(AppThemeColors.cardBg(lightCtx), Colors.white);

    // Find and tap theme toggle in AppBar
    final themeToggleBtn = find.byTooltip(RegExp(r'Switch to Dark Mode'));
    expect(themeToggleBtn, findsOneWidget);

    await tester.tap(themeToggleBtn);
    await tester.pumpAndSettle();

    // After toggle: must be Dark mode
    final BuildContext darkCtx = tester.element(find.byType(DashboardScreen));
    expect(AppThemeColors.isDark(darkCtx), isTrue);
    expect(AppThemeColors.cardBg(darkCtx), const Color(0xFF1E2632));
    expect(AppThemeColors.scaffoldBg(darkCtx), const Color(0xFF141920));
    expect(AppThemeColors.subCardBg(darkCtx), const Color(0xFF243040));

    // Verify all container boxes on dashboard have updated dark backgrounds
    final containers = tester.widgetList<Container>(find.byType(Container));
    int darkCardCount = 0;
    for (final c in containers) {
      if (c.decoration is BoxDecoration) {
        final box = c.decoration as BoxDecoration;
        if (box.color == const Color(0xFF1E2632) || box.color == const Color(0xFF243040)) {
          darkCardCount++;
        }
      }
    }
    expect(darkCardCount, greaterThanOrEqualTo(1));

    // Tap again to switch back to Light mode
    final switchBackBtn = find.byTooltip(RegExp(r'Switch to Light Mode'));
    expect(switchBackBtn, findsOneWidget);

    await tester.tap(switchBackBtn);
    await tester.pumpAndSettle();

    final BuildContext toggledBackCtx = tester.element(find.byType(DashboardScreen));
    expect(AppThemeColors.isDark(toggledBackCtx), isFalse);
    expect(AppThemeColors.cardBg(toggledBackCtx), Colors.white);
  });
}
