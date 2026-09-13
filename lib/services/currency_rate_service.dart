import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/currency_model.dart';

class CurrencyRateService {
  static const _cacheKey = 'cached_currency_rates';
  static const _lastUpdatedKey = 'cached_currency_rates_time';

  /// Converts an amount between two currencies using IDR as the common pivot base
  static double convert({
    required double amount,
    required String fromCode,
    required String toCode,
    required Map<String, double> ratesToIdr,
  }) {
    if (fromCode.toUpperCase() == toCode.toUpperCase()) return amount;

    final fromRate = ratesToIdr[fromCode.toUpperCase()] ?? 1.0;
    final toRate = ratesToIdr[toCode.toUpperCase()] ?? 1.0;

    if (toRate <= 0 || fromRate <= 0 || amount.isNaN || amount.isInfinite) {
      return amount;
    }

    // Convert from source to IDR first, then to target currency
    final inIdr = amount * fromRate;
    return inIdr / toRate;
  }

  /// Load cached rates from SharedPreferences or defaults
  static Future<Map<String, double>> loadCachedRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      if (cachedJson != null) {
        final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
        return decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
      }
    } catch (e) {
      debugPrint('Error loading cached rates: $e');
    }

    // Default rates to IDR
    return {
      for (final c in CurrencyModel.defaultCurrencies) c.code: c.rateToIdr,
    };
  }

  /// Fetch latest exchange rates from free public API
  static Future<DateTime?> getLastUpdatedTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(_lastUpdatedKey);
      if (ms != null) {
        return DateTime.fromMillisecondsSinceEpoch(ms);
      }
    } catch (_) {}
    return null;
  }

  /// Fetch latest exchange rates from free public API
  static Future<Map<String, double>?> fetchLiveRates() async {
    try {
      final response = await http
          .get(
            Uri.parse('https://open.er-api.com/v6/latest/USD'),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>?;

        if (rates != null && rates.containsKey('IDR')) {
          final usdToIdr = (rates['IDR'] as num).toDouble();
          final Map<String, double> ratesToIdr = {'IDR': 1.0};

          rates.forEach((code, rateValue) {
            final usdRate = (rateValue as num).toDouble();
            if (usdRate > 0) {
              // Rate to IDR = (USD to IDR) / (USD to Foreign Currency)
              ratesToIdr[code] = usdToIdr / usdRate;
            }
          });

          // Save to cache
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cacheKey, jsonEncode(ratesToIdr));
          await prefs.setInt(
            _lastUpdatedKey,
            DateTime.now().millisecondsSinceEpoch,
          );

          return ratesToIdr;
        }
      }
    } catch (e) {
      debugPrint('Error fetching live rates (offline fallback used): $e');
    }
    return null;
  }
}
