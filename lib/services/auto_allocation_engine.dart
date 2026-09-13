import '../models/savings_goal_model.dart';

enum AllocationStrategy {
  equal, // Rata ke semua target aktif
  proportional, // Sesuai sisa kekurangan target (proporsional)
  priorityFirst, // Prioritaskan yang deadline-nya paling dekat atau progress tertinggi
}

class AllocationResult {
  final String goalId;
  final String goalTitle;
  final String emoji;
  final double allocatedAmount;
  final double newCurrentAmount;
  final double targetAmount;
  final bool willComplete;

  const AllocationResult({
    required this.goalId,
    required this.goalTitle,
    required this.emoji,
    required this.allocatedAmount,
    required this.newCurrentAmount,
    required this.targetAmount,
    required this.willComplete,
  });
}

class AutoAllocationEngine {
  /// Calculate smart distribution of deposit amount across active savings goals
  static List<AllocationResult> calculateAllocation({
    required double depositAmount,
    required List<SavingsGoalModel> activeGoals,
    AllocationStrategy strategy = AllocationStrategy.proportional,
  }) {
    if (depositAmount <= 0 || activeGoals.isEmpty) return [];

    final unreachedGoals = activeGoals.where((g) => !g.isReached).toList();
    if (unreachedGoals.isEmpty) return [];

    final results = <AllocationResult>[];

    if (strategy == AllocationStrategy.equal) {
      final perGoal = depositAmount / unreachedGoals.length;
      for (final goal in unreachedGoals) {
        final added = perGoal;
        final newAmt = goal.currentAmount + added;
        results.add(
          AllocationResult(
            goalId: goal.id,
            goalTitle: goal.title,
            emoji: goal.emoji,
            allocatedAmount: added,
            newCurrentAmount: newAmt,
            targetAmount: goal.targetAmount,
            willComplete: newAmt >= goal.targetAmount,
          ),
        );
      }
    } else if (strategy == AllocationStrategy.proportional) {
      final totalRemainingNeeded = unreachedGoals.fold(0.0, (s, g) => s + g.remainingAmount);

      if (totalRemainingNeeded <= 0) {
        // Fallback to equal
        return calculateAllocation(
          depositAmount: depositAmount,
          activeGoals: activeGoals,
          strategy: AllocationStrategy.equal,
        );
      }

      for (final goal in unreachedGoals) {
        final weight = goal.remainingAmount / totalRemainingNeeded;
        final added = (depositAmount * weight).roundToDouble();
        final newAmt = goal.currentAmount + added;
        results.add(
          AllocationResult(
            goalId: goal.id,
            goalTitle: goal.title,
            emoji: goal.emoji,
            allocatedAmount: added,
            newCurrentAmount: newAmt,
            targetAmount: goal.targetAmount,
            willComplete: newAmt >= goal.targetAmount,
          ),
        );
      }
    } else if (strategy == AllocationStrategy.priorityFirst) {
      // Sort: closest deadline first, or highest completion
      final sorted = List<SavingsGoalModel>.from(unreachedGoals)
        ..sort((a, b) {
          if (a.targetDate != null && b.targetDate != null) {
            return a.targetDate!.compareTo(b.targetDate!);
          } else if (a.targetDate != null) {
            return -1;
          } else if (b.targetDate != null) {
            return 1;
          }
          return b.progressPercent.compareTo(a.progressPercent);
        });

      double remainingDeposit = depositAmount;
      for (final goal in sorted) {
        if (remainingDeposit <= 0) {
          results.add(
            AllocationResult(
              goalId: goal.id,
              goalTitle: goal.title,
              emoji: goal.emoji,
              allocatedAmount: 0,
              newCurrentAmount: goal.currentAmount,
              targetAmount: goal.targetAmount,
              willComplete: false,
            ),
          );
          continue;
        }

        final needed = goal.remainingAmount;
        final added = remainingDeposit >= needed ? needed : remainingDeposit;
        remainingDeposit -= added;
        final newAmt = goal.currentAmount + added;

        results.add(
          AllocationResult(
            goalId: goal.id,
            goalTitle: goal.title,
            emoji: goal.emoji,
            allocatedAmount: added,
            newCurrentAmount: newAmt,
            targetAmount: goal.targetAmount,
            willComplete: newAmt >= goal.targetAmount,
          ),
        );
      }

      // If leftover, distribute to first goal
      if (remainingDeposit > 0 && results.isNotEmpty) {
        final first = results.first;
        results[0] = AllocationResult(
          goalId: first.goalId,
          goalTitle: first.goalTitle,
          emoji: first.emoji,
          allocatedAmount: first.allocatedAmount + remainingDeposit,
          newCurrentAmount: first.newCurrentAmount + remainingDeposit,
          targetAmount: first.targetAmount,
          willComplete: true,
        );
      }
    }

    return results;
  }
}
