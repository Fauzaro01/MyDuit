import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppAccentColor {
  emerald, // default
  indigo,
  ocean,
  sunset,
  rose,
  obsidian,
}

extension AppAccentColorExtension on AppAccentColor {
  String get label {
    switch (this) {
      case AppAccentColor.emerald:
        return 'Emerald (Default)';
      case AppAccentColor.indigo:
        return 'Royal Indigo';
      case AppAccentColor.ocean:
        return 'Ocean Blue';
      case AppAccentColor.sunset:
        return 'Sunset Amber';
      case AppAccentColor.rose:
        return 'Rose Pink';
      case AppAccentColor.obsidian:
        return 'Obsidian Slate';
    }
  }

  Color get lightColor {
    switch (this) {
      case AppAccentColor.emerald:
        return const Color(0xFF0D9373);
      case AppAccentColor.indigo:
        return const Color(0xFF6366F1);
      case AppAccentColor.ocean:
        return const Color(0xFF0284C7);
      case AppAccentColor.sunset:
        return const Color(0xFFD97706);
      case AppAccentColor.rose:
        return const Color(0xFFE11D48);
      case AppAccentColor.obsidian:
        return const Color(0xFF475569);
    }
  }

  Color get darkColor {
    switch (this) {
      case AppAccentColor.emerald:
        return const Color(0xFF4AEDC4);
      case AppAccentColor.indigo:
        return const Color(0xFF818CF8);
      case AppAccentColor.ocean:
        return const Color(0xFF38BDF8);
      case AppAccentColor.sunset:
        return const Color(0xFFFBBF24);
      case AppAccentColor.rose:
        return const Color(0xFFFB7185);
      case AppAccentColor.obsidian:
        return const Color(0xFF94A3B8);
    }
  }
}

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _accentKey = 'accent_color';
  static const String _privacyKey = 'incognito_privacy_mode';

  ThemeMode _themeMode = ThemeMode.system;
  AppAccentColor _accentColor = AppAccentColor.emerald;
  bool _isPrivacyMode = false;

  ThemeMode get themeMode => _themeMode;
  AppAccentColor get accentColor => _accentColor;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isPrivacyMode => _isPrivacyMode;

  ThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    final accentIndex = prefs.getInt(_accentKey) ?? 0;
    _themeMode = ThemeMode.values[themeIndex];
    if (accentIndex >= 0 && accentIndex < AppAccentColor.values.length) {
      _accentColor = AppAccentColor.values[accentIndex];
    }
    _isPrivacyMode = prefs.getBool(_privacyKey) ?? false;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<void> setAccentColor(AppAccentColor accent) async {
    _accentColor = accent;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentKey, accent.index);
  }

  Future<void> togglePrivacyMode() async {
    _isPrivacyMode = !_isPrivacyMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyKey, _isPrivacyMode);
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}
