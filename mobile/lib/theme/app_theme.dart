// app_theme.dart
// Provides a centralized theme token class to replace raw Colors throughout the app.
// Each static method returns a Color based on the current Theme (light/dark) and
// a consistent palette. The implementation uses Theme.of(context).colorScheme
// and custom shades to match the design requirements.

import 'package:flutter/material.dart';

class AppThemeColors {
  // Example token getters. Adjust the actual color values to match the design.
  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF424242)
          : const Color(0xFFE2E4E8);

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : const Color(0xFF1A283B);

  static Color textMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFB0B0B0)
          : const Color(0xFF5A6675);

  static Color primarySlate(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  // Background & surface tokens
  static Color scaffoldBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF141920)
          : const Color(0xFFF8F8F6);

  static Color drawerBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1B222C)
          : const Color(0xFFF8F8F6);

  static Color cardBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E2632)
          : Colors.white;

  static Color subCardBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF26303E)
          : const Color(0xFFF4F5F7);

  static Color selectedTileBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2A3748)
          : const Color(0xFFEDF2F7);

  // Status tag colors with proper dark mode contrast
  static Color tagCompletedBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF183324)
          : const Color(0xFFEDF4F0);

  static Color tagCompletedText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF68D391)
          : const Color(0xFF245E43);

  static Color tagCompletedBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2F855A)
          : const Color(0xFFCFE2D7);

  static Color tagRunningBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E2D42)
          : const Color(0xFFEDF2F7);

  static Color tagRunningText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF90CDF4)
          : const Color(0xFF1A283B);

  static Color tagRunningBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF3182CE)
          : const Color(0xFFCBD5E1);

  static Color tagFailedBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF3D1B1B)
          : const Color(0xFFF8EDED);

  static Color tagFailedText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFFEB2B2)
          : const Color(0xFF8A2C2C);

  static Color tagFailedBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF9B2C2C)
          : const Color(0xFFE8CFCF);

  // Error related tokens
  static Color errorBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF3D1B1B)
          : const Color(0xFFF8EDED);

  static Color errorBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF9B2C2C)
          : const Color(0xFFE8CFCF);

  static Color errorText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFFEB2B2)
          : const Color(0xFF8A2C2C);

  // Warning related tokens
  static Color warningBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF3B2E1E)
          : const Color(0xFFFFF4E5);

  static Color warningBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFD69E2E)
          : const Color(0xFFB0895D);

  static Color warningText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFFBD38D)
          : const Color(0xFFB0895D);

  // Success related tokens
  static Color successBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF183324)
          : const Color(0xFFE5F5E5);

  static Color successBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2F855A)
          : const Color(0xFF4CAF50);

  static Color successText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF68D391)
          : const Color(0xFF4CAF50);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF1A283B),
      scaffoldBackgroundColor: const Color(0xFFF8F8F6),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1A283B),
        secondary: Color(0xFF2C3E50),
        surface: Colors.white,
        error: Color(0xFF8A2C2C),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1A283B),
        elevation: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        modalBackgroundColor: Colors.white,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF4A6B82),
      scaffoldBackgroundColor: const Color(0xFF141920),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF4A6B82),
        secondary: Color(0xFF6C8299),
        surface: Color(0xFF1E2632),
        error: Color(0xFFCF6679),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1B222C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E2632),
        modalBackgroundColor: Color(0xFF1E2632),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF1E2632),
      ),
    );
  }
}
