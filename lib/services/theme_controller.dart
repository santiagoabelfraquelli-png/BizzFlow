import 'package:flutter/material.dart';

import 'app_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  final AppPreferences preferences = AppPreferences.instance;

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> load() async {
    await preferences.load();

    final savedTheme = await preferences.getThemeMode();

    switch (savedTheme) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;

      case 'dark':
        _themeMode = ThemeMode.dark;
        break;

      case 'system':
      default:
        _themeMode = ThemeMode.system;
        break;
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;

    await preferences.setThemeMode(
      mode.name,
    );

    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    await setThemeMode(
      enabled ? ThemeMode.dark : ThemeMode.light,
    );
  }
}