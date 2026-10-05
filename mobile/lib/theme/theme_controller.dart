// ThemeController singleton for toggling light/dark mode across the app.
import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  // Private constructor for singleton pattern.
  ThemeController._internal();
  static final ThemeController instance = ThemeController._internal();

  // Default to system theme; can be overridden by user.
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  /// Toggles between light, dark, and system theme modes.
  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.system;
    } else {
      // If currently system, default to dark.
      _themeMode = ThemeMode.dark;
    }
    notifyListeners();
  }
}

