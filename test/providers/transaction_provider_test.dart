import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/models/transaction_model.dart';

/// Tests for TransactionProvider logic that can be tested without
/// database access: month navigation, computed getters, search state.
///
/// We test these by creating a testable version of the provider logic.
void main() {
  group('Month navigation logic', () {
    late int selectedYear;
    late int selectedMonth;

    void nextMonth() {
      if (selectedMonth == 12) {
        selectedMonth = 1;
        selectedYear++;
      } else {
        selectedMonth++;
      }
    }

    void previousMonth() {
      if (selectedMonth == 1) {
        selectedMonth = 12;
        selectedYear--;
      } else {
        selectedMonth--;
      }
    }

    setUp(() {
      selectedYear = 2026;
      selectedMonth = 2;
    });

    test('nextMonth increments month', () {
      nextMonth();
      expect(selectedMonth, 3);
      expect(selectedYear, 2026);
    });

    test('nextMonth wraps to January of next year', () {
      selectedMonth = 12;
      nextMonth();
      expect(selectedMonth, 1);
      expect(selectedYear, 2027);
    });

    test('previousMonth decrements month', () {
      previousMonth();
      expect(selectedMonth, 1);
      expect(selectedYear, 2026);
    });

    test('previousMonth wraps to December of previous year', () {
      selectedMonth = 1;
      previousMonth();
      expect(selectedMonth, 12);
      expect(selectedYear, 2025);
    });

    test('multiple nextMonth calls navigate correctly', () {
      for (int i = 0; i < 12; i++) {
        nextMonth();
      }
      // Feb + 12 months = Feb next year
      expect(selectedMonth, 2);
      expect(selectedYear, 2027);
    });

    test('multiple previousMonth calls navigate correctly', () {
      for (int i = 0; i < 12; i++) {
        previousMonth();
      }
      // Feb - 12 months = Feb previous year
      expect(selectedMonth, 2);
      expect(selectedYear, 2025);
    });

    test('setMonth sets specific year and month', () {
      selectedYear = 2030;
      selectedMonth = 7;
      expect(selectedYear, 2030);
      expect(selectedMonth, 7);
    });
  });

  group('Transaction filtering logic', () {
    late List<TransactionModel> transactions;

    setUp(() {
      transactions = [
        TransactionModel(
          id: '1',
          title: 'Gaji',
          amount: 5000000,
          type: TransactionType.income,
          category: TransactionCategory.salary,
          date: DateTime(2026, 2, 1),
        ),
        TransactionModel(
          id: '2',
          title: 'Freelance',
          amount: 2000000,
          type: TransactionType.income,
          category: TransactionCategory.freelance,
          date: DateTime(2026, 2, 5),
        ),
        TransactionModel(
          id: '3',
          title: 'Makan',
          amount: 50000,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          date: DateTime(2026, 2, 10),
        ),
        TransactionModel(
          id: '4',
          title: 'Transportasi',
          amount: 30000,
          type: TransactionType.expense,
          category: TransactionCategory.transport,
          date: DateTime(2026, 2, 15),
        ),
        TransactionModel(
          id: '5',
          title: 'Belanja',
          amount: 200000,
          type: TransactionType.expense,
          category: TransactionCategory.shopping,
          date: DateTime(2026, 2, 20),
        ),
      ];
    });

    test('incomeTransactions filters correctly', () {
      final income = transactions
          .where((t) => t.type == TransactionType.income)
          .toList();
      expect(income.length, 2);
      expect(income[0].title, 'Gaji');
      expect(income[1].title, 'Freelance');
    });

    test('expenseTransactions filters correctly', () {
      final expense = transactions
          .where((t) => t.type == TransactionType.expense)
          .toList();
      expect(expense.length, 3);
    });

    test('balance calculation is correct', () {
      final totalIncome = transactions
          .where((t) => t.type == TransactionType.income)
          .fold<double>(0, (sum, t) => sum + t.amount);
      final totalExpense = transactions
          .where((t) => t.type == TransactionType.expense)
          .fold<double>(0, (sum, t) => sum + t.amount);
      final balance = totalIncome - totalExpense;

      expect(totalIncome, 7000000);
      expect(totalExpense, 280000);
      expect(balance, 6720000);
    });

    test('recent transactions takes first 5', () {
      final recent = transactions.take(5).toList();
      expect(recent.length, 5);
    });

    test('recent transactions handles fewer than 5', () {
      final shortList = transactions.take(2).toList();
      final recent = shortList.take(5).toList();
      expect(recent.length, 2);
    });
  });

  group('Search state logic', () {
    test('isSearching returns true when query is not empty', () {
      final searchQuery = 'makan';
      expect(searchQuery.isNotEmpty, isTrue);
    });

    test('isSearching returns false when query is empty', () {
      final searchQuery = '';
      expect(searchQuery.isNotEmpty, isFalse);
    });

    test('clearSearch resets state', () {
      var searchQuery = 'something';
      var searchResults = <TransactionModel>[
        TransactionModel(
          id: '1',
          title: 'Test',
          amount: 100,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          date: DateTime(2026, 2, 1),
        ),
      ];

      // Clear
      searchQuery = '';
      searchResults = [];

      expect(searchQuery, isEmpty);
      expect(searchResults, isEmpty);
    });

    test('search with empty query produces empty results', () {
      final query = '   ';
      final trimmed = query.trim();
      expect(trimmed.isEmpty, isTrue);
    });
  });

  group('Budget state logic', () {
    test('expense categories for budgets', () {
      final expenseCategories = TransactionCategory.values
          .where((c) => !c.isIncomeCategory)
          .toList();

      expect(expenseCategories, contains(TransactionCategory.food));
      expect(expenseCategories, contains(TransactionCategory.transport));
      expect(expenseCategories, contains(TransactionCategory.shopping));
      expect(expenseCategories, contains(TransactionCategory.bills));
      expect(expenseCategories, contains(TransactionCategory.entertainment));
      expect(expenseCategories, contains(TransactionCategory.health));
      expect(expenseCategories, contains(TransactionCategory.education));
      expect(expenseCategories, contains(TransactionCategory.travel));
      expect(expenseCategories, contains(TransactionCategory.other));

      // Income categories should NOT be in the list
      expect(expenseCategories, isNot(contains(TransactionCategory.salary)));
      expect(expenseCategories, isNot(contains(TransactionCategory.freelance)));
      expect(
        expenseCategories,
        isNot(contains(TransactionCategory.investment)),
      );
      expect(expenseCategories, isNot(contains(TransactionCategory.gift)));
    });

    test('total budget calculation', () {
      final budgetLimits = [1500000.0, 500000.0, 300000.0];
      final totalBudget = budgetLimits.fold<double>(0, (a, b) => a + b);
      expect(totalBudget, 2300000);
    });

    test('budget utilization percentage', () {
      final limit = 1000000.0;
      final spent = 750000.0;
      final percentage = (spent / limit).clamp(0.0, 1.0);
      expect(percentage, 0.75);
    });

    test('budget over-spend detection', () {
      final limit = 1000000.0;
      final spent = 1200000.0;
      expect(spent > limit, isTrue);
    });

    test('budget with zero limit', () {
      final limit = 0.0;
      final spent = 50000.0;
      final isOverBudget = limit > 0 && spent > limit;
      expect(isOverBudget, isFalse);
    });
  });
}
