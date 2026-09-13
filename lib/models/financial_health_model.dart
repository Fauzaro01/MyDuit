enum HealthStatus {
  healthy('Sehat 🌟', 0xFF0D9373),
  good('Cukup Sehat 👍', 0xFF3B82F6),
  warning('Perlu Waspada ⚠️', 0xFFF59E0B),
  critical('Kritis 🚨', 0xFFEF4444);

  final String label;
  final int colorValue;
  const HealthStatus(this.label, this.colorValue);
}

class FinancialHealthScore {
  final int score; // 0 to 100
  final HealthStatus status;
  final double needsPercentage; // Target ~50%
  final double wantsPercentage; // Target ~30%
  final double savingsPercentage; // Target ~20%
  final double emergencyFundMonths; // Months of expenses covered
  final double debtToIncomeRatio; // DTI ratio percentage
  final List<String> recommendations;

  const FinancialHealthScore({
    required this.score,
    required this.status,
    required this.needsPercentage,
    required this.wantsPercentage,
    required this.savingsPercentage,
    required this.emergencyFundMonths,
    required this.debtToIncomeRatio,
    required this.recommendations,
  });
}

class CashflowForecastItem {
  final DateTime date;
  final double projectedBalance;
  final double dailyNetChange;
  final bool isDeficit;

  const CashflowForecastItem({
    required this.date,
    required this.projectedBalance,
    required this.dailyNetChange,
    this.isDeficit = false,
  });
}
