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
  static const String _hapticsKey = 'enable_haptics_feedback';
  static const String _amoledKey = 'enable_amoled_black_mode';
  static const String _fontScaleKey = 'app_font_scale';

  ThemeMode _themeMode = ThemeMode.system;
  AppAccentColor _accentColor = AppAccentColor.emerald;
  bool _isPrivacyMode = false;
  bool _isHapticsEnabled = true;
  bool _isAmoledMode = false;
  double _fontScale = 1.0;

  ThemeMode get themeMode => _themeMode;
  AppAccentColor get accentColor => _accentColor;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isPrivacyMode => _isPrivacyMode;
  bool get isHapticsEnabled => _isHapticsEnabled;
  bool get isAmoledMode => _isAmoledMode;
  double get fontScale => _fontScale;

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
    _isHapticsEnabled = prefs.getBool(_hapticsKey) ?? true;
    _isAmoledMode = prefs.getBool(_amoledKey) ?? false;
    _fontScale = prefs.getDouble(_fontScaleKey) ?? 1.0;
    notifyListeners();
  }

  Future<void> setFontScale(double scale) async {
    _fontScale = scale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, scale);
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

  Future<void> toggleHaptics() async {
    _isHapticsEnabled = !_isHapticsEnabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticsKey, _isHapticsEnabled);
  }

  Future<void> toggleAmoledMode() async {
    _isAmoledMode = !_isAmoledMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_amoledKey, _isAmoledMode);
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}
