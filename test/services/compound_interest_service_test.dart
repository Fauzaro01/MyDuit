import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/services/compound_interest_service.dart';

void main() {
  group('CompoundInterestService Tests', () {
    test('calculates accurate compound growth schedule', () {
      // Starting with 10.000.000, adding 1.000.000/month, 6% annual rate for 12 months
      final schedule = CompoundInterestService.calculateGrowthSchedule(
        initialAmount: 10000000,
        monthlyDeposit: 1000000,
        annualRatePercent: 6.0,
        durationMonths: 12,
      );

      expect(schedule.length, 12);
      expect(schedule.last.totalPrincipalDeposited, 22000000); // 10M + 12 * 1M
      expect(schedule.last.totalInterestEarned, greaterThan(600000));
      expect(schedule.last.totalFutureValue, greaterThan(22600000));
    });
  });
}
