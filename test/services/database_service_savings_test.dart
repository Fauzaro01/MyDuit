import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:myduit/models/savings_goal_model.dart';
import 'package:myduit/services/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseService.addToSavingsGoal', () {
    test('full contribution funds the goal, returns true, and logs history', () async {
      final dbService = DatabaseService();
      final goal = SavingsGoalModel(title: 'Liburan', targetAmount: 100000);
      await dbService.insertSavingsGoal(goal);

      final justCompleted = await dbService.addToSavingsGoal(
        goal.id,
        100000,
        walletId: 'wallet-1',
      );
      expect(justCompleted, isTrue);

      final all = await dbService.getAllSavingsGoals();
      final updated = all.firstWhere((g) => g.id == goal.id);
      expect(updated.isCompleted, isTrue);
      expect(updated.currentAmount, 100000);

      final history = await dbService.getSavingsContributions(goal.id);
      expect(history, hasLength(1));
      expect(history.first.amount, 100000);
      expect(history.first.walletId, 'wallet-1');
    });

    test('partial contribution does not fund the goal', () async {
      final dbService = DatabaseService();
      final goal = SavingsGoalModel(title: 'Dana Darurat', targetAmount: 100000);
      await dbService.insertSavingsGoal(goal);

      final justCompleted = await dbService.addToSavingsGoal(goal.id, 40000);
      expect(justCompleted, isFalse);

      final all = await dbService.getAllSavingsGoals();
      final updated = all.firstWhere((g) => g.id == goal.id);
      expect(updated.isCompleted, isFalse);
      expect(updated.currentAmount, 40000);
    });

    test('a contribution without a wallet is logged as unsynced (walletId null)', () async {
      final dbService = DatabaseService();
      final goal = SavingsGoalModel(title: 'Tanpa sync', targetAmount: 50000);
      await dbService.insertSavingsGoal(goal);

      await dbService.addToSavingsGoal(goal.id, 10000);

      final history = await dbService.getSavingsContributions(goal.id);
      expect(history.single.walletId, isNull);
    });
  });

  group('DatabaseService.deleteSavingsGoal', () {
    test('cascades to delete its contribution history', () async {
      final dbService = DatabaseService();
      final goal = SavingsGoalModel(title: 'Akan dihapus', targetAmount: 50000);
      await dbService.insertSavingsGoal(goal);
      await dbService.addToSavingsGoal(goal.id, 10000);

      await dbService.deleteSavingsGoal(goal.id);

      final history = await dbService.getSavingsContributions(goal.id);
      expect(history, isEmpty);
    });
  });
}
