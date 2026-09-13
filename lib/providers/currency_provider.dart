import 'package:flutter/material.dart';
import '../models/currency_model.dart';
import '../services/currency_rate_service.dart';

class CurrencyProvider extends ChangeNotifier {
  String _baseCurrencyCode = 'IDR';
  Map<String, double> _ratesToIdr = {};
  bool _isLoading = false;
  DateTime? _lastRefreshed;

  String get baseCurrencyCode => _baseCurrencyCode;
  Map<String, double> get ratesToIdr => _ratesToIdr;
  bool get isLoading => _isLoading;
  DateTime? get lastRefreshed => _lastRefreshed;

  List<CurrencyModel> get availableCurrencies {
    return CurrencyModel.defaultCurrencies.map((c) {
      final currentRate = _ratesToIdr[c.code] ?? c.rateToIdr;
      return CurrencyModel(
        code: c.code,
        symbol: c.symbol,
        name: c.name,
        rateToIdr: currentRate,
        lastUpdated: _lastRefreshed ?? c.lastUpdated,
      );
    }).toList();
  }

  Future<void> init() async {
    _ratesToIdr = await CurrencyRateService.loadCachedRates();
    if (_ratesToIdr.isNotEmpty) {
      _lastRefreshed = DateTime.now();
    }
    notifyListeners();
    // Silently refresh in background
    refreshRates();
  }

  void setBaseCurrency(String code) {
    if (_baseCurrencyCode != code) {
      _baseCurrencyCode = code.toUpperCase();
      notifyListeners();
    }
  }

  Future<void> refreshRates() async {
    _isLoading = true;
    notifyListeners();

    final liveRates = await CurrencyRateService.fetchLiveRates();
    if (liveRates != null && liveRates.isNotEmpty) {
      _ratesToIdr = liveRates;
      _lastRefreshed = DateTime.now();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Convert amount from any currency code to base currency (or custom target)
  double convert(
    double amount, {
    required String fromCurrency,
    String? toCurrency,
  }) {
    final target = toCurrency ?? _baseCurrencyCode;
    return CurrencyRateService.convert(
      amount: amount,
      fromCode: fromCurrency,
      toCode: target,
      ratesToIdr: _ratesToIdr,
    );
  }

  /// Get symbol for a currency code
  String getSymbol(String code) {
    final found = CurrencyModel.defaultCurrencies.firstWhere(
      (c) => c.code.toUpperCase() == code.toUpperCase(),
      orElse: () => CurrencyModel(
        code: code,
        symbol: code,
        name: code,
        rateToIdr: 1.0,
        lastUpdated: DateTime.now(),
      ),
    );
    return found.symbol;
  }
}
