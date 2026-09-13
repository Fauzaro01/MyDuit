import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/models/debt_model.dart';
import 'package:myduit/models/recurring_transaction_model.dart';
import 'package:myduit/models/subscription_model.dart';
import 'package:myduit/models/transaction_model.dart';
import 'package:myduit/services/financial_calendar_service.dart';

void main() {
  group('FinancialCalendarService Tests', () {
    test('generateMonthSummary aggregates daily transactions and heatmap levels', () {
      final transactions = [
        TransactionModel(
          title: 'Gaji',
          amount: 5000000,
          type: TransactionType.income,
          category: TransactionCategory.salary,
          date: DateTime(2026, 9, 1),
        ),
        TransactionModel(
          title: 'Makan',
          amount: 100000,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          date: DateTime(2026, 9, 1),
        ),
        TransactionModel(
          title: 'Belanja Besar',
          amount: 1200000,
          type: TransactionType.expense,
          category: TransactionCategory.shopping,
          date: DateTime(2026, 9, 15),
        ),
      ];

      final debts = [
        DebtModel(
          id: '1',
          personName: 'Budi',
          amount: 300000,
          type: DebtType.iOwe,
          dueDate: DateTime(2026, 9, 15),
          createdAt: DateTime(2026, 9, 1),
        ),
      ];

      final recurrings = [
        RecurringTransactionModel(
          id: '1',
          title: 'Internet',
          amount: 350000,
          type: TransactionType.expense,
          category: TransactionCategory.bills,
          frequency: RecurrenceFrequency.monthly,
          startDate: DateTime(2026, 9, 20),
        ),
      ];

      final subscriptions = [
        SubscriptionModel(
          id: '1',
          name: 'Netflix',
          amount: 186000,
          dueDay: 20,
        ),
      ];

      final summaries = FinancialCalendarService.generateMonthSummary(
        year: 2026,
        month: 9,
        transactions: transactions,
        debts: debts,
        recurrings: recurrings,
        subscriptions: subscriptions,
      );

      expect(summaries.length, 30); // September has 30 days

      // Day 1
      final day1 = summaries[1]!;
      expect(day1.totalIncome, 5000000.0);
      expect(day1.totalExpense, 100000.0);
      expect(day1.transactions.length, 2);

      // Day 15
      final day15 = summaries[15]!;
      expect(day15.totalExpense, 1200000.0);
      expect(day15.debtsDue.length, 1);
      expect(day15.hasEvents, true);
      expect(day15.heatLevel, greaterThan(0));

      // Day 20
      final day20 = summaries[20]!;
      expect(day20.recurringsDue.length, 1);
      expect(day20.subscriptionsDue.length, 1);
      expect(day20.hasEvents, true);
    });
  });
}
