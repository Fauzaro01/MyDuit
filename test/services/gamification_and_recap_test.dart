import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/models/transaction_model.dart';
import 'package:myduit/models/savings_goal_model.dart';
import 'package:myduit/models/debt_model.dart';
import 'package:myduit/models/budget_model.dart';
import 'package:myduit/services/gamification_engine.dart';
import 'package:myduit/services/monthly_recap_service.dart';

void main() {
  group('GamificationEngine Tests', () {
    test('calculateStreak calculates continuous active logging days', () {
      final now = DateTime.now();
      final txs = [
        TransactionModel(
          title: 'Makan Siang',
          amount: 25000,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          date: now,
          walletId: 'w1',
        ),
        TransactionModel(
          title: 'Kopi',
          amount: 20000,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          date: now.subtract(const Duration(days: 1)),
          walletId: 'w1',
        ),
        TransactionModel(
          title: 'Bensin',
          amount: 30000,
          type: TransactionType.expense,
          category: TransactionCategory.transport,
          date: now.subtract(const Duration(days: 2)),
          walletId: 'w1',
        ),
      ];

      final streak = GamificationEngine.calculateStreak(txs);
      expect(streak.currentStreak, 3);
      expect(streak.longestStreak, 3);
    });

    test('evaluateBadges unlocks badges based on criteria', () {
      final now = DateTime.now();
      final txs = [
        TransactionModel(
          title: 'Gaji',
          amount: 10000000,
          type: TransactionType.income,
          category: TransactionCategory.salary,
          date: now,
          walletId: 'w1',
        ),
      ];
      final goals = [
        SavingsGoalModel(
          title: 'Dana Darurat',
          targetAmount: 5000000,
          currentAmount: 5000000,
          targetDate: now.add(const Duration(days: 30)),
        ),
      ];
      final debts = [
        DebtModel(
          personName: 'Budi',
          amount: 100000,
          paidAmount: 100000,
          type: DebtType.iOwe,
        ),
      ];
      final budgets = [
        BudgetModel(
          category: TransactionCategory.food,
          monthlyLimit: 1000000,
          year: now.year,
          month: now.month,
        ),
      ];

      final streak = GamificationEngine.calculateStreak(txs);
      final badges = GamificationEngine.evaluateBadges(
        transactions: txs,
        savingsGoals: goals,
        debts: debts,
        budgets: budgets,
        streak: streak,
      );

      final firstStep = badges.firstWhere((b) => b.id == 'first_step');
      expect(firstStep.isUnlocked, isTrue);

      final goalAchiever = badges.firstWhere((b) => b.id == 'goal_achiever');
      expect(goalAchiever.isUnlocked, isTrue);

      final debtFree = badges.firstWhere((b) => b.id == 'debt_free');
      expect(debtFree.isUnlocked, isTrue);
    });
  });

  group('MonthlyRecapService Tests', () {
    test('generateRecap produces correct savings rate and top category', () {
      final txs = [
        TransactionModel(
          title: 'Gaji',
          amount: 10000000,
          type: TransactionType.income,
          category: TransactionCategory.salary,
          date: DateTime(2026, 9, 1),
          walletId: 'w1',
        ),
        TransactionModel(
          title: 'Makan Resto',
          amount: 2000000,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          date: DateTime(2026, 9, 5),
          walletId: 'w1',
        ),
        TransactionModel(
          title: 'Belanja',
          amount: 1000000,
          type: TransactionType.expense,
          category: TransactionCategory.shopping,
          date: DateTime(2026, 9, 10),
          walletId: 'w1',
        ),
      ];

      final recap = MonthlyRecapService.generateRecap(
        year: 2026,
        month: 9,
        allTransactions: txs,
      );

      expect(recap.totalIncome, 10000000);
      expect(recap.totalExpense, 3000000);
      expect(recap.netSavings, 7000000);
      expect(recap.savingsRate, 70.0);
      expect(recap.topExpenseCategory, 'Makanan');
      expect(recap.mostExpensiveDayOfMonth, 5);
      expect(recap.personalityTitle, 'Sang Master Penabung');
    });
  });
}
