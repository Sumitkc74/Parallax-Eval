// app_theme.dart
// Provides a centralized theme token class to replace raw Colors throughout the app.
// Each static method returns a Color based on the current Theme (light/dark) and
// a consistent palette. The implementation uses ThemeController.instance.isDark(context)
// and custom shades to match the design requirements.

import 'package:flutter/material.dart';
import 'theme_controller.dart';

class AppThemeColors {
  /// Unifies dark mode checking across platform dispatcher, user override, and Theme context.
  static bool isDark(BuildContext context) =>
      ThemeController.instance.isDark(context);

  static Color border(BuildContext context) =>
      isDark(context)
          ? const Color(0xFF2E3B4E)
          : const Color(0xFFE2E4E8);

  static Color textPrimary(BuildContext context) =>
      isDark(context)
          ? Colors.white
          : const Color(0xFF1A283B);

  static Color textMuted(BuildContext context) =>
      isDark(context)
          ? const Color(0xFF94A3B8)
          : const Color(0xFF5A6675);

  static Color primarySlate(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  // Background & surface tokens
  static Color scaffoldBg(BuildContext context) =>
      isDark(context)
          ? const Color(0xFF141920)
          : const Color(0xFFF8F8F6);

  static Color drawerBg(BuildContext context) =>
      isDark(context)
          ? const Color(0xFF161E28)
          : const Color(0xFFF8F8F6);

  static Color cardBg(BuildContext context) =>
      isDark(context)
          ? const Color(0xFF1E2632)
          : Colors.white;

  static Color subCardBg(BuildContext context) =>
      isDark(context)
          ? const Color(0xFF243040)
          : const Color(0xFFF4F5F7);

  static Color selectedTileBg(BuildContext context) =>
      isDark(context)
          ? const Color(0xFF243042)
          : const Color(0xFFEDF2F7);

  // Status tag colors with proper dark mode contrast
  static Color tagCompletedBg(BuildContext context) =>
      isDark(context)
          ? const Color(0xFF183324)
          : const Color(0xFFEDF4F0);

  static Color tagCompletedText(BuildContext context) =>
      isDark(context)
          ? const Color(0xFF68D391)
          : const Color(0xFF245E43);

  static Color tagCompletedBorder(BuildContext context) =>
      isDark(context)
          ? const Color(0xFF2F855A)
          : const Color(0xFFCFE2D7);

  static Color tagRunningBg(BuildContext context) =>
      isDark(context)
          ? const Color(0xFF1E2D42)
          : const Color(0xFFEDF2F7);

  static Color tagRunningText(BuildContext context) =>
      isDark(context)
          ? const Color(0xFF90CDF4)
          : const Color(0xFF1A283B);

  static Color tagRunningBorder(BuildContext context) =>
      isDark(context)
          ? const Color(0xFF3182CE)
          : const Color(0xFFCBD5E1);

  static Color tagFailedBg(BuildContext context) =>
      isDark(context)
          ? const Color(0xFF3D1B1B)
          : const Color(0xFFF8EDED);

  static Color tagFailedText(BuildContext context) =>
      isDark(context)
          ? const Color(0xFFFEB2B2)
          : const Color(0xFF8A2C2C);

  static Color tagFailedBorder(BuildContext context) =>
      isDark(context)
          ? const Color(0xFF9B2C2C)
          : const Color(0xFFE8CFCF);

  // Error related tokens
  static Color errorBg(BuildContext context) =>
      isDark(context)
          ? const Color(0xFF3D1B1B)
          : const Color(0xFFF8EDED);

  static Color errorBorder(BuildContext context) =>
      isDark(context)
          ? const Color(0xFF9B2C2C)
          : const Color(0xFFE8CFCF);

  static Color errorText(BuildContext context) =>
      isDark(context)
          ? const Color(0xFFFEB2B2)
          : const Color(0xFF8A2C2C);

  // Warning related tokens
  static Color warningBg(BuildContext context) =>
      isDark(context)
          ? const Color(0xFF3B2E1E)
          : const Color(0xFFFFF4E5);

  static Color warningBorder(BuildContext context) =>
      isDark(context)
          ? const Color(0xFFD69E2E)
          : const Color(0xFFB0895D);

  static Color warningText(BuildContext context) =>
      isDark(context)
          ? const Color(0xFFFBD38D)
          : const Color(0xFFB0895D);

  // Success related tokens
  static Color successBg(BuildContext context) =>
      isDark(context)
          ? const Color(0xFF183324)
          : const Color(0xFFE5F5E5);

  static Color successBorder(BuildContext context) =>
      isDark(context)
          ? const Color(0xFF2F855A)
          : const Color(0xFF4CAF50);

  static Color successText(BuildContext context) =>
      isDark(context)
          ? const Color(0xFF68D391)
          : const Color(0xFF4CAF50);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      primaryColor: const Color(0xFF1A283B),
      scaffoldBackgroundColor: const Color(0xFFF8F8F6),
      cardColor: Colors.white,
      canvasColor: Colors.white,
      dividerColor: const Color(0xFFE2E4E8),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1A283B),
        secondary: Color(0xFF2C3E50),
        surface: Colors.white,
        error: Color(0xFF8A2C2C),
        surfaceContainerLow: Color(0xFFF8F8F6),
        surfaceContainer: Colors.white,
        surfaceContainerHigh: Color(0xFFF1F3F5),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          side: BorderSide(color: Color(0xFFE2E4E8), width: 1.0),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1A283B),
        elevation: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        modalBackgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: Color(0xFF1A283B),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(
          color: Color(0xFF5A6675),
          fontSize: 13,
        ),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: Color(0xFF1A283B), fontSize: 13),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E4E8),
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.white,
        filled: true,
        labelStyle: const TextStyle(color: Color(0xFF5A6675)),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFE2E4E8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFE2E4E8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF1A283B), width: 1.5),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      primaryColor: const Color(0xFF4A6B82),
      scaffoldBackgroundColor: const Color(0xFF141920),
      cardColor: const Color(0xFF1E2632),
      canvasColor: const Color(0xFF1E2632),
      dividerColor: const Color(0xFF263344),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF60A5FA),
        secondary: Color(0xFF94A3B8),
        surface: Color(0xFF1E2632),
        error: Color(0xFFFEB2B2),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
        surfaceContainerLow: Color(0xFF1A222C),
        surfaceContainer: Color(0xFF1E2632),
        surfaceContainerHigh: Color(0xFF243040),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF1E2632),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          side: BorderSide(color: Color(0xFF2E3B4E), width: 1.0),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1B222C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E2632),
        modalBackgroundColor: Color(0xFF1E2632),
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF1E2632),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(
          color: Color(0xFFCBD5E1),
          fontSize: 13,
        ),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: Color(0xFF1E2632),
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: Colors.white, fontSize: 13),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF263344),
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: const Color(0xFF161E28),
        filled: true,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF2E3B4E)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF2E3B4E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 1.5),
        ),
      ),
    );
  }
}
