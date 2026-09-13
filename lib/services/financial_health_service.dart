import '../models/financial_health_model.dart';
import '../models/transaction_model.dart';
import '../models/debt_model.dart';

class FinancialHealthService {
  /// Evaluates financial health score based on transaction history and current balances
  static FinancialHealthScore evaluate({
    required List<TransactionModel> transactions,
    required double currentTotalBalance,
    required List<DebtModel> debts,
    required double monthlyIncome,
    required double monthlyExpense,
  }) {
    if (monthlyIncome <= 0 && monthlyExpense <= 0) {
      return const FinancialHealthScore(
        score: 50,
        status: HealthStatus.good,
        needsPercentage: 0,
        wantsPercentage: 0,
        savingsPercentage: 0,
        emergencyFundMonths: 0,
        debtToIncomeRatio: 0,
        recommendations: [
          'Mulai catat pemasukan dan pengeluaran rutin untuk melihat analisis keuangan.',
        ],
      );
    }

    // 1. Calculate 50/30/20 breakdown
    double needsExpense = 0;
    double wantsExpense = 0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.expense) {
        if (tx.customCategoryId != null) {
          // Custom category expenses default to needs if title contains essential keywords
          final lower = tx.title.toLowerCase();
          if (lower.contains('makan') ||
              lower.contains('listrik') ||
              lower.contains('air') ||
              lower.contains('sewa') ||
              lower.contains('obat') ||
              lower.contains('sekolah')) {
            needsExpense += tx.amount;
          } else {
            wantsExpense += tx.amount;
          }
        } else if (_isNeedCategory(tx.category)) {
          needsExpense += tx.amount;
        } else {
          wantsExpense += tx.amount;
        }
      }
    }

    final totalTrackedExp = needsExpense + wantsExpense;
    final totalExp = monthlyExpense > 0
        ? monthlyExpense
        : (totalTrackedExp > 0 ? totalTrackedExp : 1.0);
    final needsPct = totalTrackedExp > 0 ? ((needsExpense / totalExp) * 100) : 0.0;
    final wantsPct = totalTrackedExp > 0 ? ((wantsExpense / totalExp) * 100) : 0.0;
    final savingsPct = monthlyIncome > 0
        ? (((monthlyIncome - monthlyExpense) / monthlyIncome) * 100)
            .clamp(0.0, 100.0)
        : 0.0;

    // 2. Emergency Fund Ratio (Months of expenses covered by current cash)
    final emergencyMonths = monthlyExpense > 0
        ? (currentTotalBalance / monthlyExpense)
        : (currentTotalBalance > 0 ? 12.0 : 0.0);

    // 3. Debt-to-Income (DTI)
    final totalUnsettledDebt = debts
        .where((d) => d.type == DebtType.iOwe && !d.isSettled)
        .fold(0.0, (sum, d) => sum + d.remainingAmount);
    final dtiPct =
        monthlyIncome > 0 ? (totalUnsettledDebt / monthlyIncome) * 100 : 0.0;

    // 4. Compute Health Score (0 - 100)
    int score = 50;

    // Savings rate scoring (up to +25 points)
    if (savingsPct >= 20) {
      score += 25;
    } else if (savingsPct >= 10) {
      score += 15;
    } else if (savingsPct > 0) {
      score += 5;
    } else {
      score -= 15; // Spending more than income
    }

    // Emergency fund scoring (up to +20 points)
    if (emergencyMonths >= 6) {
      score += 20;
    } else if (emergencyMonths >= 3) {
      score += 15;
    } else if (emergencyMonths >= 1) {
      score += 8;
    } else {
      score -= 10;
    }

    // Debt burden scoring (up to +15 points)
    if (dtiPct == 0) {
      score += 15;
    } else if (dtiPct <= 20) {
      score += 10;
    } else if (dtiPct <= 40) {
      score += 0;
    } else {
      score -= 20; // High debt risk
    }

    // Needs proportion scoring (+/- 10 points)
    if (needsPct <= 60 && wantsPct <= 35) {
      score += 10;
    } else if (needsPct > 80) {
      score -= 10;
    }

    final clampedScore = score.clamp(0, 100);

    // Status
    HealthStatus status;
    if (clampedScore >= 80) {
      status = HealthStatus.healthy;
    } else if (clampedScore >= 60) {
      status = HealthStatus.good;
    } else if (clampedScore >= 40) {
      status = HealthStatus.warning;
    } else {
      status = HealthStatus.critical;
    }

    // Generate Recommendations
    final List<String> recs = [];
    if (savingsPct < 20) {
      recs.add(
        'Tingkatkan rasio tabungan hingga minimal 20% dari pemasukan bulanan.',
      );
    }
    if (emergencyMonths < 3) {
      recs.add(
        'Siapkan dana darurat minimal setara 3-6 bulan pengeluaran rutin Anda.',
      );
    }
    if (dtiPct > 35) {
      recs.add(
        'Beban cicilan/hutang cukup tinggi (>35% pemasukan). Prioritaskan pelunasan hutang berbunga tinggi.',
      );
    }
    if (wantsPct > 35) {
      recs.add(
        'Pengeluaran keinginan (Wants) melampaui 35%. Evaluasi pos belanja gaya hidup & hiburan.',
      );
    }
    if (recs.isEmpty) {
      recs.add(
        'Kondisi keuangan sangat prima! Pertahankan pola arus kas dan alokasikan ke target tabungan/investasi.',
      );
    }

    return FinancialHealthScore(
      score: clampedScore,
      status: status,
      needsPercentage: needsPct,
      wantsPercentage: wantsPct,
      savingsPercentage: savingsPct,
      emergencyFundMonths: emergencyMonths,
      debtToIncomeRatio: dtiPct,
      recommendations: recs,
    );
  }

  static bool _isNeedCategory(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.food:
      case TransactionCategory.transport:
      case TransactionCategory.bills:
      case TransactionCategory.health:
      case TransactionCategory.education:
        return true;
      case TransactionCategory.shopping:
      case TransactionCategory.entertainment:
      case TransactionCategory.salary:
      case TransactionCategory.freelance:
      case TransactionCategory.gift:
      case TransactionCategory.investment:
      case TransactionCategory.travel:
      case TransactionCategory.other:
        return false;
    }
  }
}
