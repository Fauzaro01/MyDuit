import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/models/savings_goal_model.dart';

void main() {
  group('SavingsGoalModel.isOverdue', () {
    test('false when there is no target date', () {
      final goal = SavingsGoalModel(title: 'No deadline', targetAmount: 100000);
      expect(goal.isOverdue, isFalse);
    });

    test('false when target date is in the future', () {
      final goal = SavingsGoalModel(
        title: 'Future',
        targetAmount: 100000,
        targetDate: DateTime.now().add(const Duration(days: 10)),
      );
      expect(goal.isOverdue, isFalse);
    });

    test('true when target date passed and goal is not yet funded', () {
      final goal = SavingsGoalModel(
        title: 'Past due',
        targetAmount: 100000,
        currentAmount: 10000,
        targetDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(goal.isOverdue, isTrue);
    });

    test('false when target date passed but goal is already funded', () {
      final goal = SavingsGoalModel(
        title: 'Past due but funded',
        targetAmount: 100000,
        currentAmount: 100000,
        targetDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(goal.isOverdue, isFalse);
    });
  });

  group('SavingsGoalModel.suggestedMonthlyAmount', () {
    test('null when there is no target date', () {
      final goal = SavingsGoalModel(title: 'No deadline', targetAmount: 100000);
      expect(goal.suggestedMonthlyAmount, isNull);
    });

    test('null when already reached', () {
      final goal = SavingsGoalModel(
        title: 'Done',
        targetAmount: 100000,
        currentAmount: 100000,
        targetDate: DateTime.now().add(const Duration(days: 30)),
      );
      expect(goal.suggestedMonthlyAmount, isNull);
    });

    test('null when target date already passed', () {
      final goal = SavingsGoalModel(
        title: 'Overdue',
        targetAmount: 100000,
        targetDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(goal.suggestedMonthlyAmount, isNull);
    });

    test('divides remaining amount across whole months remaining', () {
      final now = DateTime.now();
      final goal = SavingsGoalModel(
        title: 'Two months out',
        targetAmount: 1000000,
        currentAmount: 0,
        targetDate: DateTime(now.year, now.month + 2, now.day),
      );
      expect(goal.suggestedMonthlyAmount, 500000);
    });
  });
}
