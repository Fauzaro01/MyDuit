import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/models/transaction_model.dart';
import 'package:myduit/services/spending_velocity_service.dart';

void main() {
  group('SpendingVelocityService Tests', () {
    test('calculates accurate daily burn pace and on-track status', () {
      // 30-day month, day 15 (halfway)
      // Total budget = 3.000.000 (Target = 100.000/day)
      // Total spent = 1.500.000 (Actual = 100.000/day)
      final res = SpendingVelocityService.calculateVelocity(
        totalBudget: 3000000,
        totalSpent: 1500000,
        year: 2026,
        month: 9, // September has 30 days
        currentDate: DateTime(2026, 9, 15),
      );

      expect(res.daysInMonth, 30);
      expect(res.daysElapsed, 15);
      expect(res.daysRemaining, 15);
      expect(res.dailyBurnTarget, 100000);
      expect(res.actualDailyBurn, 100000);
      expect(res.projectedMonthEndSpend, 3000000);
      expect(res.paceRatio, 1.0);
      expect(res.status, SpendingPaceStatus.onTrack);
    });

    test('detects fast pace when burn rate exceeds 125%', () {
      // Day 10 of 30 days
      // Total budget = 3.000.000 (Target = 100.000/day)
      // Total spent = 1.500.000 (Actual = 150.000/day -> 150% pace)
      final res = SpendingVelocityService.calculateVelocity(
        totalBudget: 3000000,
        totalSpent: 1500000,
        year: 2026,
        month: 9,
        currentDate: DateTime(2026, 9, 10),
      );

      expect(res.paceRatio, 1.5);
      expect(res.status, SpendingPaceStatus.fastPace);
      expect(res.projectedMonthEndSpend, 4500000);
    });

    test('generates accurate 50-30-20 envelope splits', () {
      const income = 10000000.0; // 10 Million
      final splits = SpendingVelocityService.generate50_30_20Envelopes(income);

      // 50% Needs = 5.000.000
      expect(splits[TransactionCategory.food], 2500000); // 50% of needs
      expect(splits[TransactionCategory.transport], 1250000); // 25% of needs
      expect(splits[TransactionCategory.bills], 1250000); // 25% of needs

      // 30% Wants = 3.000.000
      expect(splits[TransactionCategory.shopping], 1500000); // 50% of wants
      expect(splits[TransactionCategory.entertainment], 900000); // 30% of wants
      expect(splits[TransactionCategory.health], 600000); // 20% of wants

      // 20% Savings = 2.000.000
      expect(splits[TransactionCategory.investment], 1200000); // 60% of savings
      expect(splits[TransactionCategory.education], 800000); // 40% of savings
    });
  });
}
