import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myduit/providers/theme_provider.dart';
import 'package:flutter/material.dart';

void main() {
  group('ThemeProvider', () {
    setUp(() {
      // Set up fake SharedPreferences for each test
      SharedPreferences.setMockInitialValues({});
    });

    test('initial theme mode is system', () {
      final provider = ThemeProvider();
      // Default before loading from prefs
      expect(provider.themeMode, ThemeMode.system);
    });

    test('isDarkMode returns correct value', () {
      final provider = ThemeProvider();
      expect(provider.isDarkMode, isFalse);
    });

    test('setThemeMode updates theme to dark', () async {
      final provider = ThemeProvider();

      await provider.setThemeMode(ThemeMode.dark);

      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.isDarkMode, isTrue);
    });

    test('setThemeMode updates theme to light', () async {
      final provider = ThemeProvider();

      await provider.setThemeMode(ThemeMode.light);

      expect(provider.themeMode, ThemeMode.light);
      expect(provider.isDarkMode, isFalse);
    });

    test('setThemeMode updates theme to system', () async {
      final provider = ThemeProvider();

      await provider.setThemeMode(ThemeMode.dark);
      await provider.setThemeMode(ThemeMode.system);

      expect(provider.themeMode, ThemeMode.system);
    });

    test('toggleTheme switches from dark to light', () async {
      final provider = ThemeProvider();

      await provider.setThemeMode(ThemeMode.dark);
      await provider.toggleTheme();

      expect(provider.themeMode, ThemeMode.light);
    });

    test('toggleTheme switches from light to dark', () async {
      final provider = ThemeProvider();

      await provider.setThemeMode(ThemeMode.light);
      await provider.toggleTheme();

      expect(provider.themeMode, ThemeMode.dark);
    });

    test('toggleTheme switches from system to dark', () async {
      final provider = ThemeProvider();

      // Default is system, which is not dark, so toggle should go to dark
      await provider.toggleTheme();

      expect(provider.themeMode, ThemeMode.dark);
    });

    test('persists theme mode to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = ThemeProvider();

      await provider.setThemeMode(ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('theme_mode'), ThemeMode.dark.index);
    });

    test('loads theme mode from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': ThemeMode.dark.index,
      });

      final provider = ThemeProvider();

      // Wait for async _loadTheme to complete
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.themeMode, ThemeMode.dark);
    });

    test('loads light theme from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': ThemeMode.light.index,
      });

      final provider = ThemeProvider();

      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.themeMode, ThemeMode.light);
    });

    test('notifies listeners on theme change', () async {
      final provider = ThemeProvider();
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.setThemeMode(ThemeMode.dark);

      expect(notifyCount, greaterThanOrEqualTo(1));
    });

    test('notifies listeners on toggle', () async {
      final provider = ThemeProvider();
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.toggleTheme();

      expect(notifyCount, greaterThanOrEqualTo(1));
    });
  });
}
