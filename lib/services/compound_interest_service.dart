class CompoundGrowthProjection {
  final int monthIndex;
  final double totalPrincipalDeposited;
  final double totalInterestEarned;
  final double totalFutureValue;

  const CompoundGrowthProjection({
    required this.monthIndex,
    required this.totalPrincipalDeposited,
    required this.totalInterestEarned,
    required this.totalFutureValue,
  });
}

class CompoundInterestService {
  /// Calculate Future Value (FV) with regular monthly deposits and compound interest
  /// [initialAmount]: starting principal (e.g. current saved amount)
  /// [monthlyDeposit]: regular monthly addition
  /// [annualRatePercent]: annual interest / return rate (e.g. 6.0 for 6% p.a.)
  /// [durationMonths]: investment horizon in months
  static List<CompoundGrowthProjection> calculateGrowthSchedule({
    required double initialAmount,
    required double monthlyDeposit,
    required double annualRatePercent,
    required int durationMonths,
  }) {
    final List<CompoundGrowthProjection> schedule = [];
    final monthlyRate = (annualRatePercent / 100.0) / 12.0;

    double currentBalance = initialAmount;
    double principalDeposited = initialAmount;

    for (int m = 1; m <= durationMonths; m++) {
      // Add monthly interest on current balance
      final interestThisMonth = currentBalance * monthlyRate;
      currentBalance += interestThisMonth + monthlyDeposit;
      principalDeposited += monthlyDeposit;

      final totalInterest = currentBalance - principalDeposited;

      schedule.add(
        CompoundGrowthProjection(
          monthIndex: m,
          totalPrincipalDeposited: principalDeposited,
          totalInterestEarned: totalInterest > 0 ? totalInterest : 0.0,
          totalFutureValue: currentBalance,
        ),
      );
    }

    return schedule;
  }
}
