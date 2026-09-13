import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/models/budget_model.dart';
import 'package:myduit/models/transaction_model.dart';
import 'package:myduit/services/budget_rollover_service.dart';

void main() {
  group('BudgetRolloverService Tests', () {
    test('calculateRollover returns positive surplus on underspent', () {
      final budget = BudgetModel(
        id: '1',
        category: TransactionCategory.food,
        monthlyLimit: 1000000,
        year: 2026,
        month: 9,
        isRollover: true,
      );

      final prevTransactions = [
        TransactionModel(
          title: 'Lunch',
          amount: 200000,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          date: DateTime(2026, 8, 10),
        ),
        TransactionModel(
          title: 'Dinner',
          amount: 300000,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          date: DateTime(2026, 8, 20),
        ),
      ];

      final surplus = BudgetRolloverService.calculateRollover(
        budget: budget,
        previousMonthTransactions: prevTransactions,
        previousMonthLimit: 1000000,
      );

      expect(surplus, 500000.0);
    });

    test('calculateRollover returns 0 if isRollover is false', () {
      final budget = BudgetModel(
        id: '1',
        category: TransactionCategory.food,
        monthlyLimit: 1000000,
        year: 2026,
        month: 9,
        isRollover: false,
      );

      final prevTransactions = [
        TransactionModel(
          title: 'Lunch',
          amount: 200000,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          date: DateTime(2026, 8, 10),
        ),
      ];

      final surplus = BudgetRolloverService.calculateRollover(
        budget: budget,
        previousMonthTransactions: prevTransactions,
        previousMonthLimit: 1000000,
      );

      expect(surplus, 0.0);
    });

    test('getPreviousPeriod returns correct period even across year boundary', () {
      final sep = BudgetRolloverService.getPreviousPeriod(2026, 9);
      expect(sep, (2026, 8));

      final jan = BudgetRolloverService.getPreviousPeriod(2026, 1);
      expect(jan, (2025, 12));
    });

    test('evaluate correctly classifies alert levels', () {
      final budget = BudgetModel(
        id: '1',
        category: TransactionCategory.food,
        monthlyLimit: 1000000,
        year: 2026,
        month: 9,
      );

      // 40% spent -> safe
      final reportSafe = BudgetRolloverService.evaluate(
        budget: budget,
        currentMonthTransactions: [
          TransactionModel(
            title: 'Food',
            amount: 400000,
            type: TransactionType.expense,
            category: TransactionCategory.food,
            date: DateTime(2026, 9, 5),
          ),
        ],
      );
      expect(reportSafe.alertLevel, BudgetAlertLevel.safe);
      expect(reportSafe.usagePercentage, 40.0);

      // 60% spent -> warning
      final reportWarning = BudgetRolloverService.evaluate(
        budget: budget,
        currentMonthTransactions: [
          TransactionModel(
            title: 'Food',
            amount: 600000,
            type: TransactionType.expense,
            category: TransactionCategory.food,
            date: DateTime(2026, 9, 5),
          ),
        ],
      );
      expect(reportWarning.alertLevel, BudgetAlertLevel.warning);

      // 85% spent -> alert
      final reportAlert = BudgetRolloverService.evaluate(
        budget: budget,
        currentMonthTransactions: [
          TransactionModel(
            title: 'Food',
            amount: 850000,
            type: TransactionType.expense,
            category: TransactionCategory.food,
            date: DateTime(2026, 9, 5),
          ),
        ],
      );
      expect(reportAlert.alertLevel, BudgetAlertLevel.alert);

      // 110% spent -> exceeded
      final reportExceeded = BudgetRolloverService.evaluate(
        budget: budget,
        currentMonthTransactions: [
          TransactionModel(
            title: 'Food',
            amount: 1100000,
            type: TransactionType.expense,
            category: TransactionCategory.food,
            date: DateTime(2026, 9, 5),
          ),
        ],
      );
      expect(reportExceeded.alertLevel, BudgetAlertLevel.exceeded);
    });
  });
}
