import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/models/transaction_model.dart';
import 'package:myduit/services/financial_advisor_service.dart';

void main() {
  group('FinancialAdvisorService Tests', () {
    test('analyze detects spending spike anomaly', () {
      final prevMonthTransactions = [
        TransactionModel(
          title: 'Makan',
          amount: 500000,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          date: DateTime(2026, 8, 10),
        ),
      ];

      final currentMonthTransactions = [
        TransactionModel(
          title: 'Resto Mewah',
          amount: 1500000, // 200% spike
          type: TransactionType.expense,
          category: TransactionCategory.food,
          date: DateTime(2026, 9, 10),
        ),
      ];

      final insights = FinancialAdvisorService.analyze(
        currentMonthTransactions: currentMonthTransactions,
        previousMonthTransactions: prevMonthTransactions,
        budgets: [],
        monthlyIncome: 10000000,
        monthlyExpense: 1500000,
      );

      final anomaly = insights.firstWhere((i) => i.type == InsightType.anomaly);
      expect(anomaly.title.contains('Lonjakan Pengeluaran'), true);
      expect(anomaly.impactAmount, 1000000.0);
    });

    test('queryTransactions filters by keyword, category and tags', () {
      final transactions = [
        TransactionModel(
          title: 'Kopi Susu Senja',
          amount: 25000,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          date: DateTime.now(),
          tags: ['nongkrong', 'kafe'],
        ),
        TransactionModel(
          title: 'Tiket Bioskop',
          amount: 50000,
          type: TransactionType.expense,
          category: TransactionCategory.entertainment,
          date: DateTime.now(),
          tags: ['hiburan'],
        ),
      ];

      final resKopi = FinancialAdvisorService.queryTransactions(
        transactions: transactions,
        query: 'kopi',
      );
      expect(resKopi.length, 1);
      expect(resKopi.first.title, 'Kopi Susu Senja');

      final resTag = FinancialAdvisorService.queryTransactions(
        transactions: transactions,
        query: 'hiburan',
      );
      expect(resTag.length, 1);
      expect(resTag.first.title, 'Tiket Bioskop');

      final resToday = FinancialAdvisorService.queryTransactions(
        transactions: transactions,
        query: 'hari ini',
      );
      expect(resToday.length, 2);
    });
  });
}
