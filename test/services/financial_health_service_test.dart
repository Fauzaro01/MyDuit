import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/models/financial_health_model.dart';
import 'package:myduit/models/transaction_model.dart';
import 'package:myduit/services/financial_health_service.dart';

void main() {
  group('FinancialHealthService', () {
    test('evaluates healthy state when high savings rate and emergency fund', () {
      final transactions = [
        TransactionModel(
          title: 'Gaji',
          amount: 10000000,
          type: TransactionType.income,
          category: TransactionCategory.salary,
          date: DateTime.now(),
        ),
        TransactionModel(
          title: 'Makan',
          amount: 2500000,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          date: DateTime.now(),
        ),
        TransactionModel(
          title: 'Listrik & Air',
          amount: 1000000,
          type: TransactionType.expense,
          category: TransactionCategory.bills,
          date: DateTime.now(),
        ),
      ];

      final health = FinancialHealthService.evaluate(
        transactions: transactions,
        currentTotalBalance: 20000000, // 20M / 3.5M = ~5.7 months
        debts: [],
        monthlyIncome: 10000000,
        monthlyExpense: 3500000,
      );

      expect(health.score, greaterThanOrEqualTo(80));
      expect(health.status, HealthStatus.healthy);
      expect(health.savingsPercentage, 65.0);
      expect(health.emergencyFundMonths, closeTo(5.7, 0.1));
    });
  });
}
