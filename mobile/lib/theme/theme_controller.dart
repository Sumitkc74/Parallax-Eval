// ThemeController singleton for toggling light/dark mode across the app.
import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  // Private constructor for singleton pattern.
  ThemeController._internal();
  static final ThemeController instance = ThemeController._internal();

  // Default to system theme; can be overridden by user.
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  /// Returns whether dark mode is currently active, taking context and platform into account.
  bool isDark([BuildContext? context]) {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    if (context != null) {
      return Theme.of(context).brightness == Brightness.dark;
    }
    return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  }

  /// Explicitly set the theme mode (system, light, or dark).
  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  /// Toggles cleanly between Light and Dark mode.
  /// If currently effective is Dark, switches to Light.
  /// If currently effective is Light, switches to Dark.
  void toggleTheme([BuildContext? context]) {
    if (isDark(context)) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }
    notifyListeners();
  }
}

