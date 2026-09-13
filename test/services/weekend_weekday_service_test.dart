import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/models/transaction_model.dart';
import 'package:myduit/services/weekend_weekday_service.dart';

void main() {
  group('WeekendWeekdayService Tests', () {
    test('Correctly calculates weekday and weekend spending totals and counts', () {
      final transactions = [
        // Monday (Weekday)
        TransactionModel(
          title: 'Lunch',
          amount: 50000,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          date: DateTime(2026, 9, 14), // Monday
        ),
        // Tuesday (Weekday)
        TransactionModel(
          title: 'Transport',
          amount: 30000,
          type: TransactionType.expense,
          category: TransactionCategory.transport,
          date: DateTime(2026, 9, 15), // Tuesday
        ),
        // Saturday (Weekend)
        TransactionModel(
          title: 'Movie',
          amount: 100000,
          type: TransactionType.expense,
          category: TransactionCategory.entertainment,
          date: DateTime(2026, 9, 19), // Saturday
        ),
        // Sunday (Weekend)
        TransactionModel(
          title: 'Dinner',
          amount: 150000,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          date: DateTime(2026, 9, 20), // Sunday
        ),
        // Income should be excluded
        TransactionModel(
          title: 'Salary',
          amount: 5000000,
          type: TransactionType.income,
          category: TransactionCategory.salary,
          date: DateTime(2026, 9, 15),
        ),
      ];

      final stats = WeekendWeekdayService.analyzeSpending(transactions);

      expect(stats.weekdayTotal, equals(80000.0));
      expect(stats.weekendTotal, equals(250000.0));
      expect(stats.totalExpense, equals(330000.0));
      expect(stats.weekdayCount, equals(2));
      expect(stats.weekendCount, equals(2));
      expect(stats.weekdayDailyAvg, equals(40000.0));
      expect(stats.weekendDailyAvg, equals(125000.0));
      expect(stats.weekdayPercentage, closeTo(24.24, 0.1));
      expect(stats.weekendPercentage, closeTo(75.75, 0.1));
      expect(stats.highestDay, isNotNull);
      expect(stats.highestDay!.amount, equals(150000.0));
      expect(stats.highestDay!.transactionCount, equals(1));
    });

    test('Handles empty transactions gracefully', () {
      final stats = WeekendWeekdayService.analyzeSpending([]);

      expect(stats.weekdayTotal, equals(0.0));
      expect(stats.weekendTotal, equals(0.0));
      expect(stats.totalExpense, equals(0.0));
      expect(stats.weekdayPercentage, equals(0.0));
      expect(stats.weekendPercentage, equals(0.0));
      expect(stats.highestDay, isNull);
    });
  });
}
