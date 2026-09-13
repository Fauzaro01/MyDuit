import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/models/savings_goal_model.dart';
import 'package:myduit/services/auto_allocation_engine.dart';

void main() {
  group('AutoAllocationEngine Tests', () {
    final now = DateTime.now();
    final goal1 = SavingsGoalModel(
      id: 'g1',
      title: 'Target Liburan',
      emoji: '✈️',
      targetAmount: 5000000,
      currentAmount: 2000000, // remaining 3.000.000 (60%)
      targetDate: now.add(const Duration(days: 60)),
    );
    final goal2 = SavingsGoalModel(
      id: 'g2',
      title: 'Dana Darurat',
      emoji: '🛡️',
      targetAmount: 10000000,
      currentAmount: 8000000, // remaining 2.000.000 (40%)
      targetDate: now.add(const Duration(days: 30)),
    );

    test('equal strategy divides deposit equally across active goals', () {
      final res = AutoAllocationEngine.calculateAllocation(
        depositAmount: 1000000,
        activeGoals: [goal1, goal2],
        strategy: AllocationStrategy.equal,
      );

      expect(res.length, 2);
      expect(res[0].allocatedAmount, 500000);
      expect(res[1].allocatedAmount, 500000);
      expect(res[0].newCurrentAmount, 2500000);
      expect(res[1].newCurrentAmount, 8500000);
    });

    test('proportional strategy divides deposit according to deficit weight', () {
      // Total remaining needed = 3.000.000 + 2.000.000 = 5.000.000
      // Goal 1 weight = 3/5 = 60%, Goal 2 weight = 2/5 = 40%
      final res = AutoAllocationEngine.calculateAllocation(
        depositAmount: 1000000,
        activeGoals: [goal1, goal2],
        strategy: AllocationStrategy.proportional,
      );

      expect(res.length, 2);
      expect(res[0].allocatedAmount, 600000);
      expect(res[1].allocatedAmount, 400000);
    });

    test('priorityFirst strategy fills closest deadline first', () {
      // Goal 2 has 30 days deadline vs Goal 1 with 60 days
      final res = AutoAllocationEngine.calculateAllocation(
        depositAmount: 2500000,
        activeGoals: [goal1, goal2],
        strategy: AllocationStrategy.priorityFirst,
      );

      expect(res.length, 2);
      // Goal 2 (deadline 30d) receives 2.000.000 and completes
      final g2Res = res.firstWhere((r) => r.goalId == 'g2');
      expect(g2Res.allocatedAmount, 2000000);
      expect(g2Res.willComplete, isTrue);

      // Goal 1 receives remainder 500.000
      final g1Res = res.firstWhere((r) => r.goalId == 'g1');
      expect(g1Res.allocatedAmount, 500000);
      expect(g1Res.willComplete, isFalse);
    });
  });
}
