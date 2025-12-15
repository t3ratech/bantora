import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _keyTheme = 'settings.theme';

  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _saveTheme();
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyTheme);
    if (raw == null) {
      return;
    }

    switch (raw.toUpperCase()) {
      case 'DARK':
        _themeMode = ThemeMode.dark;
        break;
      case 'LIGHT':
        _themeMode = ThemeMode.light;
        break;
      default:
        throw StateError('Invalid stored theme value: $raw');
    }

    notifyListeners();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final value = _themeMode == ThemeMode.dark ? 'DARK' : 'LIGHT';
    await prefs.setString(_keyTheme, value);
  }
}
