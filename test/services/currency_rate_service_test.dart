import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/services/currency_rate_service.dart';

void main() {
  group('CurrencyRateService', () {
    final mockRatesToIdr = {
      'IDR': 1.0,
      'USD': 16000.0,
      'EUR': 17000.0,
      'SGD': 12000.0,
      'MYR': 3500.0,
    };

    test('convert same currency returns original amount', () {
      final res = CurrencyRateService.convert(
        amount: 100000,
        fromCode: 'IDR',
        toCode: 'IDR',
        ratesToIdr: mockRatesToIdr,
      );
      expect(res, 100000.0);
    });

    test('convert foreign currency to IDR correctly', () {
      final res = CurrencyRateService.convert(
        amount: 10,
        fromCode: 'USD',
        toCode: 'IDR',
        ratesToIdr: mockRatesToIdr,
      );
      expect(res, 160000.0);
    });

    test('convert IDR to foreign currency correctly', () {
      final res = CurrencyRateService.convert(
        amount: 160000,
        fromCode: 'IDR',
        toCode: 'USD',
        ratesToIdr: mockRatesToIdr,
      );
      expect(res, 10.0);
    });

    test('convert cross-currency correctly (USD to SGD)', () {
      // 100 USD = 1,600,000 IDR -> 1,600,000 / 12,000 = 133.333 SGD
      final res = CurrencyRateService.convert(
        amount: 100,
        fromCode: 'USD',
        toCode: 'SGD',
        ratesToIdr: mockRatesToIdr,
      );
      expect(res, closeTo(133.33, 0.01));
    });
  });
}
