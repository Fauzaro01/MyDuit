import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/models/budget_model.dart';
import 'package:myduit/models/transaction_model.dart';

void main() {
  group('BudgetModel', () {
    late BudgetModel budget;

    setUp(() {
      budget = BudgetModel(
        id: 'budget-id-123',
        category: TransactionCategory.food,
        monthlyLimit: 1500000,
        year: 2026,
        month: 2,
      );
    });

    test('creates instance with provided values', () {
      expect(budget.id, 'budget-id-123');
      expect(budget.category, TransactionCategory.food);
      expect(budget.monthlyLimit, 1500000);
      expect(budget.year, 2026);
      expect(budget.month, 2);
    });

    test('generates UUID if id not provided', () {
      final b = BudgetModel(
        category: TransactionCategory.food,
        monthlyLimit: 500000,
        year: 2026,
        month: 1,
      );
      expect(b.id, isNotEmpty);
      expect(b.id.length, greaterThan(10));
    });

    group('toMap', () {
      test('converts to map correctly', () {
        final map = budget.toMap();

        expect(map['id'], 'budget-id-123');
        expect(map['category'], TransactionCategory.food.index);
        expect(map['monthlyLimit'], 1500000);
        expect(map['year'], 2026);
        expect(map['month'], 2);
      });
    });

    group('fromMap', () {
      test('creates instance from map correctly', () {
        final map = {
          'id': 'from-map-id',
          'category': TransactionCategory.transport.index,
          'monthlyLimit': 750000.0,
          'year': 2026,
          'month': 3,
        };

        final b = BudgetModel.fromMap(map);

        expect(b.id, 'from-map-id');
        expect(b.category, TransactionCategory.transport);
        expect(b.monthlyLimit, 750000.0);
        expect(b.year, 2026);
        expect(b.month, 3);
      });

      test('handles int monthlyLimit from map', () {
        final map = {
          'id': 'id',
          'category': 0,
          'monthlyLimit': 500000,
          'year': 2026,
          'month': 1,
        };

        final b = BudgetModel.fromMap(map);
        expect(b.monthlyLimit, 500000.0);
        expect(b.monthlyLimit, isA<double>());
      });
    });

    group('toMap/fromMap round-trip', () {
      test('preserves all data through serialization', () {
        final map = budget.toMap();
        final restored = BudgetModel.fromMap(map);

        expect(restored.id, budget.id);
        expect(restored.category, budget.category);
        expect(restored.monthlyLimit, budget.monthlyLimit);
        expect(restored.year, budget.year);
        expect(restored.month, budget.month);
      });
    });

    group('copyWith', () {
      test('copies with no changes', () {
        final copy = budget.copyWith();

        expect(copy.id, budget.id);
        expect(copy.category, budget.category);
        expect(copy.monthlyLimit, budget.monthlyLimit);
        expect(copy.year, budget.year);
        expect(copy.month, budget.month);
      });

      test('copies with changed category', () {
        final copy = budget.copyWith(
          category: TransactionCategory.entertainment,
        );
        expect(copy.category, TransactionCategory.entertainment);
        expect(copy.monthlyLimit, budget.monthlyLimit);
      });

      test('copies with changed monthlyLimit', () {
        final copy = budget.copyWith(monthlyLimit: 2000000);
        expect(copy.monthlyLimit, 2000000);
        expect(copy.category, budget.category);
      });

      test('copies with changed year and month', () {
        final copy = budget.copyWith(year: 2027, month: 6);
        expect(copy.year, 2027);
        expect(copy.month, 6);
        expect(copy.id, budget.id);
      });

      test('copies with changed id', () {
        final copy = budget.copyWith(id: 'new-id');
        expect(copy.id, 'new-id');
      });

      test('copies with multiple changes at once', () {
        final copy = budget.copyWith(
          monthlyLimit: 999999,
          year: 2027,
          month: 12,
        );
        expect(copy.monthlyLimit, 999999);
        expect(copy.year, 2027);
        expect(copy.month, 12);
        expect(copy.id, budget.id);
        expect(copy.category, budget.category);
      });
    });

    group('edge cases', () {
      test('handles zero monthly limit', () {
        final b = BudgetModel(
          category: TransactionCategory.food,
          monthlyLimit: 0,
          year: 2026,
          month: 1,
        );
        expect(b.monthlyLimit, 0);
      });

      test('handles very large monthly limit', () {
        final b = BudgetModel(
          category: TransactionCategory.food,
          monthlyLimit: 999999999999.99,
          year: 2026,
          month: 1,
        );
        expect(b.monthlyLimit, 999999999999.99);
      });

      test('all expense categories can be used', () {
        final expenseCategories = TransactionCategory.values
            .where((c) => !c.isIncomeCategory)
            .toList();

        for (final cat in expenseCategories) {
          final b = BudgetModel(
            category: cat,
            monthlyLimit: 100000,
            year: 2026,
            month: 1,
          );
          expect(b.category, cat);
        }
      });
    });
  });
}
