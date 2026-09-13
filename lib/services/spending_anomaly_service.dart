import '../models/transaction_model.dart';
import '../utils/formatters.dart';

enum AnomalySeverity { info, warning, alert }

class SpendingAnomaly {
  final String title;
  final String message;
  final String emoji;
  final AnomalySeverity severity;
  final TransactionModel? transaction;
  final TransactionCategory? category;
  final double? excessAmount;

  SpendingAnomaly({
    required this.title,
    required this.message,
    this.emoji = '⚠️',
    this.severity = AnomalySeverity.warning,
    this.transaction,
    this.category,
    this.excessAmount,
  });
}

class SpendingAnomalyService {
  /// Detect anomalies across the provided transactions
  static List<SpendingAnomaly> detectAnomalies(
    List<TransactionModel> allTransactions, {
    int targetMonth = 0,
    int targetYear = 0,
  }) {
    final now = DateTime.now();
    final month = targetMonth > 0 ? targetMonth : now.month;
    final year = targetYear > 0 ? targetYear : now.year;

    final expenses = allTransactions
        .where((t) => t.type == TransactionType.expense)
        .toList();
    if (expenses.length < 5) return [];

    final currentMonthExpenses = expenses
        .where((t) => t.date.year == year && t.date.month == month)
        .toList();
    final pastExpenses = expenses
        .where((t) => t.date.year != year || t.date.month != month)
        .toList();

    final List<SpendingAnomaly> anomalies = [];

    // 1. Detect single unusually high transaction in current month
    final categoryAverages = <TransactionCategory, double>{};
    final categoryCounts = <TransactionCategory, int>{};

    for (final tx in pastExpenses.isNotEmpty ? pastExpenses : expenses) {
      categoryAverages[tx.category] =
          (categoryAverages[tx.category] ?? 0) + tx.amount;
      categoryCounts[tx.category] = (categoryCounts[tx.category] ?? 0) + 1;
    }

    for (final cat in categoryAverages.keys) {
      final count = categoryCounts[cat] ?? 1;
      categoryAverages[cat] = categoryAverages[cat]! / count;
    }

    for (final tx in currentMonthExpenses) {
      final avg = categoryAverages[tx.category];
      if (avg != null && avg > 0 && tx.amount >= avg * 2.8 && tx.amount >= 100000) {
        anomalies.add(
          SpendingAnomaly(
            title: 'Lonjakan Pengeluaran: ${tx.title}',
            message:
                'Nominal ${CurrencyFormatter.format(tx.amount)} sekitar ${(tx.amount / avg).toStringAsFixed(1)}x lebih tinggi dari rata-rata kategori ${tx.category.label} (${CurrencyFormatter.format(avg)}).',
            emoji: '🚨',
            severity: AnomalySeverity.alert,
            transaction: tx,
            category: tx.category,
            excessAmount: tx.amount - avg,
          ),
        );
      }
    }

    // 2. Detect category monthly surge (> 1.5x past monthly average for category)
    if (pastExpenses.isNotEmpty) {
      final pastMonths = pastExpenses.map((t) => '${t.date.year}-${t.date.month}').toSet().length;
      final effectiveMonths = pastMonths > 0 ? pastMonths : 1;

      final currentMonthByCat = <TransactionCategory, double>{};
      for (final tx in currentMonthExpenses) {
        currentMonthByCat[tx.category] =
            (currentMonthByCat[tx.category] ?? 0) + tx.amount;
      }

      final pastByCat = <TransactionCategory, double>{};
      for (final tx in pastExpenses) {
        pastByCat[tx.category] = (pastByCat[tx.category] ?? 0) + tx.amount;
      }

      for (final entry in currentMonthByCat.entries) {
        final cat = entry.key;
        final currentTotal = entry.value;
        final pastTotal = pastByCat[cat] ?? 0;
        final pastMonthlyAvg = pastTotal / effectiveMonths;

        if (pastMonthlyAvg > 50000 && currentTotal >= pastMonthlyAvg * 1.6) {
          anomalies.add(
            SpendingAnomaly(
              title: 'Peningkatan Kategori: ${cat.label}',
              message:
                  'Total pengeluaran ${cat.label} bulan ini (${CurrencyFormatter.format(currentTotal)}) melonjak ${(currentTotal / pastMonthlyAvg).toStringAsFixed(1)}x dibanding rata-rata bulanan (${CurrencyFormatter.format(pastMonthlyAvg)}).',
              emoji: '📈',
              severity: AnomalySeverity.warning,
              category: cat,
              excessAmount: currentTotal - pastMonthlyAvg,
            ),
          );
        }
      }
    }

    return anomalies;
  }
}
