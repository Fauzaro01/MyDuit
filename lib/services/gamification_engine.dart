import '../models/transaction_model.dart';
import '../models/savings_goal_model.dart';
import '../models/debt_model.dart';
import '../models/budget_model.dart';
import '../models/financial_badge_model.dart';

class GamificationEngine {
  /// Calculate daily logging streak from transactions
  static StreakData calculateStreak(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return const StreakData(currentStreak: 0, longestStreak: 0);
    }

    final uniqueDates = transactions
        .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Newest first

    if (uniqueDates.isEmpty) {
      return const StreakData(currentStreak: 0, longestStreak: 0);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final mostRecent = uniqueDates.first;
    int currentStreak = 0;

    // Check if active today or yesterday
    if (mostRecent == today || mostRecent == yesterday) {
      DateTime checkDate = mostRecent;
      for (final date in uniqueDates) {
        if (date == checkDate) {
          currentStreak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else if (date.isBefore(checkDate)) {
          break;
        }
      }
    }

    // Calculate longest streak
    int longest = 0;
    int tempStreak = 0;
    DateTime? prevDate;

    // Sort oldest first for longest calculation
    final sortedAsc = uniqueDates.toList()..sort((a, b) => a.compareTo(b));
    for (final date in sortedAsc) {
      if (prevDate == null) {
        tempStreak = 1;
      } else {
        final diff = date.difference(prevDate).inDays;
        if (diff == 1) {
          tempStreak++;
        } else if (diff > 1) {
          tempStreak = 1;
        }
      }
      if (tempStreak > longest) longest = tempStreak;
      prevDate = date;
    }

    return StreakData(
      currentStreak: currentStreak,
      longestStreak: longest,
      lastActiveDate: mostRecent,
    );
  }

  /// Evaluate unlocked financial badges
  static List<FinancialBadge> evaluateBadges({
    required List<TransactionModel> transactions,
    required List<SavingsGoalModel> savingsGoals,
    required List<DebtModel> debts,
    required List<BudgetModel> budgets,
    required StreakData streak,
  }) {
    final badges = <FinancialBadge>[];

    // 1. First Step - Catat 1 transaksi
    final txCount = transactions.length;
    badges.add(
      FinancialBadge(
        id: 'first_step',
        title: 'Langkah Pertama',
        description: 'Catat transaksi pertamamu di MyDuit.',
        emoji: '🌱',
        isUnlocked: txCount >= 1,
        progress: (txCount / 1).clamp(0.0, 1.0),
        progressLabel: '$txCount/1 transaksi',
      ),
    );

    // 2. Consistent Logger - 3 hari beruntun
    badges.add(
      FinancialBadge(
        id: 'streak_3',
        title: 'Pencatat Rajin',
        description: 'Catat keuangan 3 hari berturut-turut.',
        emoji: '🔥',
        isUnlocked: streak.currentStreak >= 3 || streak.longestStreak >= 3,
        progress: (streak.longestStreak / 3).clamp(0.0, 1.0),
        progressLabel: '${streak.longestStreak}/3 hari',
      ),
    );

    // 3. Discipline Master - 7 hari beruntun
    badges.add(
      FinancialBadge(
        id: 'streak_7',
        title: 'Pejuang Disiplin',
        description: 'Capai streak pencatatan selama 7 hari.',
        emoji: '⚡',
        isUnlocked: streak.currentStreak >= 7 || streak.longestStreak >= 7,
        progress: (streak.longestStreak / 7).clamp(0.0, 1.0),
        progressLabel: '${streak.longestStreak}/7 hari',
      ),
    );

    // 4. Financial Habit Guru - 30 hari beruntun
    badges.add(
      FinancialBadge(
        id: 'streak_30',
        title: 'Habit Guru 30 Hari',
        description: 'Konsistensi 30 hari pencatatan tanpa henti.',
        emoji: '👑',
        isUnlocked: streak.currentStreak >= 30 || streak.longestStreak >= 30,
        progress: (streak.longestStreak / 30).clamp(0.0, 1.0),
        progressLabel: '${streak.longestStreak}/30 hari',
      ),
    );

    // 5. Centurion - 100 transaksi
    badges.add(
      FinancialBadge(
        id: 'centurion',
        title: 'Centurion 100',
        description: 'Mencatat total 100 transaksi.',
        emoji: '💯',
        isUnlocked: txCount >= 100,
        progress: (txCount / 100).clamp(0.0, 1.0),
        progressLabel: '$txCount/100 transaksi',
      ),
    );

    // 6. Goal Achiever - Menyelesaikan minimal 1 target tabungan
    final completedGoals = savingsGoals.where((g) => g.currentAmount >= g.targetAmount).length;
    badges.add(
      FinancialBadge(
        id: 'goal_achiever',
        title: 'Goal Achiever',
        description: 'Selesaikan minimal 1 target tabungan (100%).',
        emoji: '🎯',
        isUnlocked: completedGoals >= 1,
        progress: (completedGoals / 1).clamp(0.0, 1.0),
        progressLabel: '$completedGoals/1 target tercapai',
      ),
    );

    // 7. Debt Free Hero - Semua hutang lunas
    final myDebts = debts.where((d) => d.type == DebtType.iOwe).toList();
    final settledDebts = myDebts.where((d) => d.isFullyPaid).length;
    final isDebtFree = myDebts.isNotEmpty && settledDebts == myDebts.length;
    badges.add(
      FinancialBadge(
        id: 'debt_free',
        title: 'Bebas Hutang Hero',
        description: 'Lunasi semua catatan hutang pribadi.',
        emoji: '🕊️',
        isUnlocked: isDebtFree,
        progress: myDebts.isEmpty ? 0.0 : (settledDebts / myDebts.length).clamp(0.0, 1.0),
        progressLabel: myDebts.isEmpty ? 'Belum ada hutang' : '$settledDebts/${myDebts.length} hutang lunas',
      ),
    );

    // 8. Budget Guardian - Memiliki minimal 1 anggaran dan tidak overbudget
    final activeBudgets = budgets.where((b) => b.monthlyLimit > 0).toList();
    int safeBudgets = 0;
    for (final b in activeBudgets) {
      final spent = transactions
          .where((t) => t.type == TransactionType.expense && t.category == b.category)
          .fold(0.0, (s, t) => s + t.amount);
      if (spent <= b.monthlyLimit) {
        safeBudgets++;
      }
    }
    final isBudgetMaster = activeBudgets.isNotEmpty && safeBudgets == activeBudgets.length;
    badges.add(
      FinancialBadge(
        id: 'budget_guardian',
        title: 'Pengendali Anggaran',
        description: 'Seluruh pos anggaran terkendali dalam batas aman.',
        emoji: '🛡️',
        isUnlocked: isBudgetMaster,
        progress: activeBudgets.isEmpty ? 0.0 : (safeBudgets / activeBudgets.length).clamp(0.0, 1.0),
        progressLabel: activeBudgets.isEmpty ? 'Belum ada anggaran' : '$safeBudgets/${activeBudgets.length} pos aman',
      ),
    );

    return badges;
  }
}
