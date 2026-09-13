import '../models/transaction_model.dart';

enum SpendingPaceStatus {
  underPace, // Green: spending slower than daily budget allow
  onTrack,   // Blue/Green: spending right on track with days elapsed
  fastPace,  // Orange: spending faster than month elapsed ratio
  critical,  // Red: budget already depleted or at high risk of early exhaustion
}

class SpendingVelocityResult {
  final double totalBudget;
  final double totalSpent;
  final double dailyBurnTarget;
  final double actualDailyBurn;
  final double projectedMonthEndSpend;
  final double paceRatio; // actual / target
  final int daysElapsed;
  final int daysInMonth;
  final int daysRemaining;
  final SpendingPaceStatus status;
  final String statusMessage;

  const SpendingVelocityResult({
    required this.totalBudget,
    required this.totalSpent,
    required this.dailyBurnTarget,
    required this.actualDailyBurn,
    required this.projectedMonthEndSpend,
    required this.paceRatio,
    required this.daysElapsed,
    required this.daysInMonth,
    required this.daysRemaining,
    required this.status,
    required this.statusMessage,
  });
}

class SpendingVelocityService {
  /// Calculate spending velocity and burn pace for a given month
  static SpendingVelocityResult calculateVelocity({
    required double totalBudget,
    required double totalSpent,
    required int year,
    required int month,
    DateTime? currentDate,
  }) {
    final now = currentDate ?? DateTime.now();
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // Determine elapsed days in selected month
    int daysElapsed;
    if (year == now.year && month == now.month) {
      daysElapsed = now.day.clamp(1, daysInMonth);
    } else if (DateTime(year, month).isBefore(DateTime(now.year, now.month))) {
      daysElapsed = daysInMonth;
    } else {
      daysElapsed = 1;
    }
    final daysRemaining = (daysInMonth - daysElapsed).clamp(0, daysInMonth);

    final dailyBurnTarget = totalBudget > 0 ? (totalBudget / daysInMonth) : 0.0;
    final actualDailyBurn = daysElapsed > 0 ? (totalSpent / daysElapsed) : 0.0;
    final projectedMonthEndSpend = actualDailyBurn * daysInMonth;

    final paceRatio = dailyBurnTarget > 0 ? (actualDailyBurn / dailyBurnTarget) : 1.0;

    SpendingPaceStatus status;
    String statusMessage;

    if (totalBudget <= 0) {
      status = SpendingPaceStatus.onTrack;
      statusMessage = 'Belum ada batas anggaran';
    } else if (totalSpent >= totalBudget) {
      status = SpendingPaceStatus.critical;
      statusMessage = 'Anggaran habis sebelum akhir bulan';
    } else if (paceRatio > 1.25) {
      status = SpendingPaceStatus.fastPace;
      statusMessage = 'Pengeluaran berjalan ${(paceRatio * 100 - 100).toStringAsFixed(0)}% lebih cepat';
    } else if (paceRatio < 0.85) {
      status = SpendingPaceStatus.underPace;
      statusMessage = 'Sangat terkendali! Dibawah batas harian';
    } else {
      status = SpendingPaceStatus.onTrack;
      statusMessage = 'Kecepatan belanja stabil sesuai target';
    }

    return SpendingVelocityResult(
      totalBudget: totalBudget,
      totalSpent: totalSpent,
      dailyBurnTarget: dailyBurnTarget,
      actualDailyBurn: actualDailyBurn,
      projectedMonthEndSpend: projectedMonthEndSpend,
      paceRatio: paceRatio,
      daysElapsed: daysElapsed,
      daysInMonth: daysInMonth,
      daysRemaining: daysRemaining,
      status: status,
      statusMessage: statusMessage,
    );
  }

  /// 50-30-20 Envelope Quick-Split Generator
  /// Returns a map of TransactionCategory to recommended monthly limit
  static Map<TransactionCategory, double> generate50_30_20Envelopes(double monthlyIncome) {
    if (monthlyIncome <= 0) return {};

    final needs = monthlyIncome * 0.50;  // 50% Kebutuhan Pokok
    final wants = monthlyIncome * 0.30;  // 30% Keinginan
    final savings = monthlyIncome * 0.20; // 20% Tabungan & Investasi

    return {
      // 50% Needs
      TransactionCategory.food: needs * 0.50,         // Makanan & Minuman
      TransactionCategory.transport: needs * 0.25,    // Transportasi
      TransactionCategory.bills: needs * 0.25,        // Tagihan & Utilitas

      // 30% Wants
      TransactionCategory.shopping: wants * 0.50,     // Belanja
      TransactionCategory.entertainment: wants * 0.30, // Hiburan
      TransactionCategory.health: wants * 0.20,       // Gaya hidup & Kesehatan

      // 20% Savings/Invest
      TransactionCategory.investment: savings * 0.60, // Investasi
      TransactionCategory.education: savings * 0.40,  // Edukasi / Pengembangan diri
    };
  }
}
