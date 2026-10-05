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

  static Color cardBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2C2C2C)
          : Colors.white;

  static Color subCardBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF3A3A3A)
          : const Color(0xFFF4F5F7);

  // Error related tokens
  static Color errorBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF442A2A)
          : const Color(0xFFF8EDED);

  static Color errorBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF8A2C2C)
          : const Color(0xFFE8CFCF);

  static Color errorText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.redAccent.shade200
          : const Color(0xFF8A2C2C);

  // Warning related tokens
  static Color warningBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF3B2E2E)
          : const Color(0xFFFFF4E5);

  static Color warningBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFB0895D)
          : const Color(0xFFB0895D);

  static Color warningText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFFFD580)
          : const Color(0xFFB0895D);

  // Success related tokens
  static Color successBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2E3B2E)
          : const Color(0xFFE5F5E5);

  static Color successBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF4CAF50)
          : const Color(0xFF4CAF50);

  static Color successText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF81C784)
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
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF1A283B),
      scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF4A6B82),
        secondary: Color(0xFF6C8299),
        surface: Color(0xFF2C2C2C),
        error: Color(0xFFCF6679),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2C2C2C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}
