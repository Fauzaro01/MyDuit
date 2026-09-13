class FinancialBadge {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final bool isUnlocked;
  final double progress; // 0.0 to 1.0
  final String progressLabel;

  const FinancialBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.isUnlocked,
    required this.progress,
    required this.progressLabel,
  });
}

class StreakData {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;

  const StreakData({
    required this.currentStreak,
    required this.longestStreak,
    this.lastActiveDate,
  });
}
