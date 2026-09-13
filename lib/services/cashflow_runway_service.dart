import '../models/transaction_model.dart';
import '../models/recurring_transaction_model.dart';
import '../models/subscription_model.dart';
import '../models/debt_model.dart';

class CashflowProjectionPoint {
  final DateTime date;
  final double projectedBalance;
  final double dailyNetChange;
  final List<String> events;

  CashflowProjectionPoint({
    required this.date,
    required this.projectedBalance,
    required this.dailyNetChange,
    this.events = const [],
  });
}

class RunwayAnalysisResult {
  final double currentBalance;
  final int daysUntilDeficit; // -1 if never runs out
  final double avgDailyBurnRate;
  final double projectedBalance30d;
  final double projectedBalance60d;
  final double projectedBalance90d;
  final List<CashflowProjectionPoint> projectionPoints;
  final bool hasDeficitWarning;
  final String recommendation;

  RunwayAnalysisResult({
    required this.currentBalance,
    required this.daysUntilDeficit,
    required this.avgDailyBurnRate,
    required this.projectedBalance30d,
    required this.projectedBalance60d,
    required this.projectedBalance90d,
    required this.projectionPoints,
    required this.hasDeficitWarning,
    required this.recommendation,
  });
}

class CashflowRunwayService {
  /// Computes simulated cashflow runway for the next 90 days combining past daily burn rate,
  /// recurring transactions, upcoming subscriptions, and debt due dates.
  static RunwayAnalysisResult analyzeRunway({
    required double currentBalance,
    required List<TransactionModel> recentTransactions,
    required List<RecurringTransactionModel> recurrings,
    required List<SubscriptionModel> subscriptions,
    required List<DebtModel> debts,
    int projectionDays = 90,
  }) {
    // 1. Calculate base baseline daily burn rate from past 30 days
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final past30dTx = recentTransactions.where((t) => t.date.isAfter(thirtyDaysAgo)).toList();

    double pastIncome = 0;
    double pastExpense = 0;
    for (final tx in past30dTx) {
      if (tx.type == TransactionType.income) {
        pastIncome += tx.amount;
      } else {
        pastExpense += tx.amount;
      }
    }

    final dailyBaselineIncome = pastIncome / 30.0;
    final dailyBaselineExpense = pastExpense / 30.0;
    final netDailyBaseline = dailyBaselineIncome - dailyBaselineExpense;

    final points = <CashflowProjectionPoint>[];
    double runningBalance = currentBalance;
    int deficitDay = -1;

    for (int day = 1; day <= projectionDays; day++) {
      final curDate = now.add(Duration(days: day));
      double dailyChange = netDailyBaseline;
      final events = <String>[];

      // Check recurring
      for (final r in recurrings.where((r) => r.isActive)) {
        bool matches = false;
        if (r.frequency == RecurrenceFrequency.daily) {
          matches = true;
        } else if (r.frequency == RecurrenceFrequency.weekly && curDate.weekday == r.startDate.weekday) {
          matches = true;
        } else if (r.frequency == RecurrenceFrequency.monthly && curDate.day == r.startDate.day) {
          matches = true;
        } else if (r.frequency == RecurrenceFrequency.yearly && curDate.month == r.startDate.month && curDate.day == r.startDate.day) {
          matches = true;
        }

        if (matches) {
          final impact = r.type == TransactionType.income ? r.amount : -r.amount;
          dailyChange += impact;
          events.add('${r.title} (${r.type == TransactionType.income ? "+" : "-"}${r.amount.toInt()})');
        }
      }

      // Check subscriptions (monthly dueDay)
      for (final sub in subscriptions.where((s) => s.isActive)) {
        if (curDate.day == sub.dueDay) {
          dailyChange -= sub.amount;
          events.add('Tagihan: ${sub.name} (-${sub.amount.toInt()})');
        }
      }

      // Check debts due
      for (final debt in debts.where((d) => !d.isSettled && d.dueDate != null)) {
        final due = debt.dueDate!;
        if (curDate.year == due.year && curDate.month == due.month && curDate.day == due.day) {
          if (debt.type == DebtType.iOwe) {
            dailyChange -= debt.remainingAmount;
            events.add('Jatuh tempo hutang: ${debt.personName}');
          } else {
            dailyChange += debt.remainingAmount;
            events.add('Jatuh tempo piutang: ${debt.personName}');
          }
        }
      }

      runningBalance += dailyChange;
      if (runningBalance < 0 && deficitDay == -1) {
        deficitDay = day;
      }

      points.add(
        CashflowProjectionPoint(
          date: curDate,
          projectedBalance: runningBalance,
          dailyNetChange: dailyChange,
          events: events,
        ),
      );
    }

    final bal30 = points.length >= 30 ? points[29].projectedBalance : runningBalance;
    final bal60 = points.length >= 60 ? points[59].projectedBalance : runningBalance;
    final bal90 = points.length >= 90 ? points[89].projectedBalance : runningBalance;

    String recommendation;
    if (deficitDay > 0 && deficitDay <= 30) {
      recommendation = '🚨 Waspada! Saldo diproyeksikan minus dalam $deficitDay hari ke depan. Kurangi pengeluaran fleksibel segera.';
    } else if (deficitDay > 30) {
      recommendation = '⚠️ Potensi defisit terdeteksi dalam $deficitDay hari. Persiapkan dana cadangan atau percepat penerimaan piutang.';
    } else if (bal90 > currentBalance * 1.2) {
      recommendation = '🌟 Arus kas sangat sehat! Saldo diproyeksikan meningkat stabil dalam 90 hari. Pertimbangkan dialokasikan ke Tabungan/Investasi.';
    } else {
      recommendation = '✅ Arus kas stabil. Pertahankan pola belanja dan pantau tagihan rutin Anda.';
    }

    return RunwayAnalysisResult(
      currentBalance: currentBalance,
      daysUntilDeficit: deficitDay,
      avgDailyBurnRate: dailyBaselineExpense,
      projectedBalance30d: bal30,
      projectedBalance60d: bal60,
      projectedBalance90d: bal90,
      projectionPoints: points,
      hasDeficitWarning: deficitDay > 0 && deficitDay <= 60,
      recommendation: recommendation,
    );
  }
}
