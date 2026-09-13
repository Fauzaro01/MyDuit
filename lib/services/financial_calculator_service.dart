import 'dart:math';

class CompoundInterestResult {
  final double futureValue;
  final double totalPrincipal;
  final double totalInterest;
  final List<YearlyGrowth> yearlyBreakdown;

  CompoundInterestResult({
    required this.futureValue,
    required this.totalPrincipal,
    required this.totalInterest,
    required this.yearlyBreakdown,
  });
}

class YearlyGrowth {
  final int year;
  final double balance;
  final double totalDeposits;
  final double interestEarned;

  YearlyGrowth({
    required this.year,
    required this.balance,
    required this.totalDeposits,
    required this.interestEarned,
  });
}

class LoanCalculationResult {
  final double monthlyPayment;
  final double totalPayment;
  final double totalInterest;

  LoanCalculationResult({
    required this.monthlyPayment,
    required this.totalPayment,
    required this.totalInterest,
  });
}

class EmergencyFundResult {
  final double targetAmount;
  final int recommendedMonths;
  final String recommendation;

  EmergencyFundResult({
    required this.targetAmount,
    required this.recommendedMonths,
    required this.recommendation,
  });
}

class RetirementResult {
  final double targetNestEgg;
  final double monthlySavingsNeeded;
  final int yearsToRetirement;

  RetirementResult({
    required this.targetNestEgg,
    required this.monthlySavingsNeeded,
    required this.yearsToRetirement,
  });
}

class FinancialCalculatorService {
  /// Calculate compound interest with monthly deposits
  static CompoundInterestResult calculateCompoundInterest({
    required double initialDeposit,
    required double monthlyDeposit,
    required double annualInterestRatePercent,
    required int years,
  }) {
    final rate = annualInterestRatePercent / 100.0;
    final monthlyRate = rate / 12.0;
    final totalMonths = years * 12;

    double currentBalance = initialDeposit;
    double totalDeposited = initialDeposit;
    final List<YearlyGrowth> breakdown = [];

    for (int m = 1; m <= totalMonths; m++) {
      currentBalance += currentBalance * monthlyRate;
      currentBalance += monthlyDeposit;
      totalDeposited += monthlyDeposit;

      if (m % 12 == 0) {
        final year = m ~/ 12;
        breakdown.add(
          YearlyGrowth(
            year: year,
            balance: currentBalance,
            totalDeposits: totalDeposited,
            interestEarned: (currentBalance - totalDeposited).clamp(0.0, double.infinity),
          ),
        );
      }
    }

    final totalInterest = (currentBalance - totalDeposited).clamp(0.0, double.infinity);

    return CompoundInterestResult(
      futureValue: currentBalance,
      totalPrincipal: totalDeposited,
      totalInterest: totalInterest,
      yearlyBreakdown: breakdown,
    );
  }

  /// Calculate fixed loan / mortgage monthly payment (Anuitas)
  static LoanCalculationResult calculateLoan({
    required double principal,
    required double annualInterestRatePercent,
    required int tenureMonths,
  }) {
    if (principal <= 0 || tenureMonths <= 0) {
      return LoanCalculationResult(
        monthlyPayment: 0,
        totalPayment: 0,
        totalInterest: 0,
      );
    }

    final monthlyRate = (annualInterestRatePercent / 100.0) / 12.0;

    if (monthlyRate == 0) {
      final monthly = principal / tenureMonths;
      return LoanCalculationResult(
        monthlyPayment: monthly,
        totalPayment: principal,
        totalInterest: 0,
      );
    }

    // PMT = P * r * (1 + r)^n / ((1 + r)^n - 1)
    final powFactor = pow(1 + monthlyRate, tenureMonths).toDouble();
    final monthlyPayment = principal * (monthlyRate * powFactor) / (powFactor - 1);
    final totalPayment = monthlyPayment * tenureMonths;
    final totalInterest = totalPayment - principal;

    return LoanCalculationResult(
      monthlyPayment: monthlyPayment,
      totalPayment: totalPayment,
      totalInterest: totalInterest.clamp(0.0, double.infinity),
    );
  }

  /// Calculate emergency fund recommendation
  static EmergencyFundResult calculateEmergencyFund({
    required double monthlyExpense,
    required bool isMarried,
    required int dependentsCount,
    required bool isFreelancer,
  }) {
    int months = 3;
    if (isMarried) months += 3;
    months += dependentsCount * 2;
    if (isFreelancer) months += 3;

    months = months.clamp(3, 12);
    final target = monthlyExpense * months;

    String recommendation = 'Disarankan menyimpan dana darurat sebesar $months bulan pengeluaran';
    if (isFreelancer) {
      recommendation += ' karena pendapatan tidak tetap.';
    } else if (dependentsCount > 0) {
      recommendation += ' untuk perlindungan keluarga dan tanggungan.';
    } else {
      recommendation += ' untuk stabilitas finansial dasar.';
    }

    return EmergencyFundResult(
      targetAmount: target,
      recommendedMonths: months,
      recommendation: recommendation,
    );
  }

  /// Calculate FIRE / Retirement target using 4% rule (25x annual expense)
  static RetirementResult calculateRetirement({
    required double currentMonthlyExpense,
    required int currentAge,
    required int targetRetirementAge,
    required double currentSavings,
    required double expectedAnnualReturnPercent,
  }) {
    final years = (targetRetirementAge - currentAge).clamp(1, 80);
    final annualExpense = currentMonthlyExpense * 12;
    final targetNestEgg = annualExpense * 25; // 4% rule

    final rate = expectedAnnualReturnPercent / 100.0;
    final monthlyRate = rate / 12.0;
    final totalMonths = years * 12;

    // Future value of current savings
    final fvCurrentSavings = currentSavings * pow(1 + monthlyRate, totalMonths);
    final remainingTarget = (targetNestEgg - fvCurrentSavings).clamp(0.0, double.infinity);

    double monthlyNeeded = 0;
    if (monthlyRate > 0) {
      final powFactor = pow(1 + monthlyRate, totalMonths).toDouble();
      monthlyNeeded = remainingTarget * monthlyRate / (powFactor - 1);
    } else {
      monthlyNeeded = remainingTarget / totalMonths;
    }

    return RetirementResult(
      targetNestEgg: targetNestEgg,
      monthlySavingsNeeded: monthlyNeeded.clamp(0.0, double.infinity),
      yearsToRetirement: years,
    );
  }
}
