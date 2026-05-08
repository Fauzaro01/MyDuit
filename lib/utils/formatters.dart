import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String format(double amount) {
    return _formatter.format(amount);
  }

  static String formatCompact(double amount) {
    if (amount >= 1000000000) {
      return 'Rp ${(amount / 1000000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}Jt';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(1)}Rb';
    }
    return format(amount);
  }
}

/// TextInputFormatter that auto-formats amount input as Indonesian Rupiah.
/// Digits-only; uses dot (.) as thousands separator.
/// Examples: 1000 → 1.000  |  12000 → 12.000  |  1200300 → 1.200.300
class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Strip all non-digits
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    // Remove leading zeros
    final stripped = digits.replaceFirst(RegExp(r'^0+'), '');
    final clean = stripped.isEmpty ? '0' : stripped;
    final formatted = _addDots(clean);

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Add dot separator every 3 digits from right
  static String _addDots(String digits) {
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  /// Strip formatting and parse to double (handles both 1.200 and 1200).
  static double parse(String text) {
    final clean = text.replaceAll('.', '').replaceAll(',', '').trim();
    if (clean.isEmpty) return 0;
    return double.tryParse(clean) ?? 0;
  }

  /// Format a double as Rupiah input string for pre-filling text fields.
  static String formatNumber(double amount) {
    return _addDots(amount.toStringAsFixed(0));
  }
}

/// Service to persist and cache the currency input formatting preference.
/// Always call [load] at app startup before accessing [isFormatted].
class CurrencyInputService {
  static const _prefKey = 'currency_input_formatted';

  /// Cached value — true means use formatted (1.000, 12.000) input.
  static bool _isFormatted = true; // default ON

  /// Synchronous getter for the cached preference.
  static bool get isFormatted => _isFormatted;

  /// Load preference from SharedPreferences. Call once at app startup.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isFormatted = prefs.getBool(_prefKey) ?? true;
    } catch (_) {}
  }

  /// Save and update the cached preference.
  static Future<void> setFormatted(bool value) async {
    _isFormatted = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, value);
    } catch (_) {}
  }
}

class DateFormatter {
  static String monthYear(int year, int month) {
    final date = DateTime(year, month);
    return DateFormat('MMMM yyyy', 'id_ID').format(date);
  }

  static String fullDate(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  }

  static String shortDate(DateTime date) {
    return DateFormat('dd MMM', 'id_ID').format(date);
  }

  static String dayMonth(DateTime date) {
    return DateFormat('dd/MM').format(date);
  }

  static String relative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    final diff = today.difference(dateOnly).inDays;

    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    if (diff < 7) return '$diff hari lalu';

    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  static String time(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }
}

// Category color palette — subtle, consistent tones
class CategoryColors {
  static Color getColor(int index, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? _darkColors : _lightColors;
    return colors[index % colors.length];
  }

  static const _lightColors = [
    Color(0xFF0D9373),
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
    Color(0xFFF97316),
    Color(0xFF14B8A6),
    Color(0xFF6366F1),
    Color(0xFFD946EF),
    Color(0xFF84CC16),
    Color(0xFF64748B),
  ];

  static const _darkColors = [
    Color(0xFF4AEDC4),
    Color(0xFF60A5FA),
    Color(0xFFFBBF24),
    Color(0xFFF87171),
    Color(0xFFA78BFA),
    Color(0xFFF472B6),
    Color(0xFF22D3EE),
    Color(0xFFFB923C),
    Color(0xFF2DD4BF),
    Color(0xFF818CF8),
    Color(0xFFE879F9),
    Color(0xFFA3E635),
    Color(0xFF94A3B8),
  ];
}
