import '../models/transaction_model.dart';
import '../models/budget_model.dart';

enum InsightType {
  anomaly,
  praise,
  warning,
  suggestion,
}

class AdvisorInsight {
  final String title;
  final String description;
  final InsightType type;
  final double? impactAmount;

  const AdvisorInsight({
    required this.title,
    required this.description,
    required this.type,
    this.impactAmount,
  });
}

class FinancialAdvisorService {
  /// Detect anomalies and generate actionable insights
  static List<AdvisorInsight> analyze({
    required List<TransactionModel> currentMonthTransactions,
    required List<TransactionModel> previousMonthTransactions,
    required List<BudgetModel> budgets,
    required double monthlyIncome,
    required double monthlyExpense,
  }) {
    final List<AdvisorInsight> insights = [];

    // 1. Spending Velocity Analysis
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final currentDay = now.day;
    final daysRemaining = daysInMonth - currentDay;

    if (monthlyIncome > 0 && monthlyExpense > 0) {
      final expectedRunRate = (currentDay / daysInMonth) * monthlyIncome;
      if (monthlyExpense > expectedRunRate * 1.2) {
        insights.add(
          AdvisorInsight(
            title: 'Kecepatan Pengeluaran Cepat ⚠️',
            description:
                'Anda telah menghabiskan ${(monthlyExpense / monthlyIncome * 100).toStringAsFixed(0)}% pemasukan padahal baru hari ke-$currentDay ($daysRemaining hari tersisa).',
            type: InsightType.warning,
          ),
        );
      } else if (monthlyExpense < expectedRunRate * 0.7 && currentDay > 15) {
        insights.add(
          AdvisorInsight(
            title: 'Pengelolaan Anggaran Sangat Baik 🌟',
            description:
                'Pola pengeluaran Anda sangat terkendali dan jauh di bawah rata-rata laju bulanan.',
            type: InsightType.praise,
          ),
        );
      }
    }

    // 2. Category Anomaly Detection (Spike > 35% compared to previous month)
    final Map<TransactionCategory, double> currentCategorySpend = {};
    final Map<TransactionCategory, double> prevCategorySpend = {};

    for (final tx in currentMonthTransactions) {
      if (tx.type == TransactionType.expense) {
        currentCategorySpend[tx.category] =
            (currentCategorySpend[tx.category] ?? 0.0) + tx.amount;
      }
    }

    for (final tx in previousMonthTransactions) {
      if (tx.type == TransactionType.expense) {
        prevCategorySpend[tx.category] =
            (prevCategorySpend[tx.category] ?? 0.0) + tx.amount;
      }
    }

    for (final entry in currentCategorySpend.entries) {
      final cat = entry.key;
      final curAmount = entry.value;
      final prevAmount = prevCategorySpend[cat] ?? 0.0;

      if (prevAmount > 50000 && curAmount > prevAmount * 1.35) {
        final diff = curAmount - prevAmount;
        insights.add(
          AdvisorInsight(
            title: 'Lonjakan Pengeluaran: ${cat.label} 📈',
            description:
                'Pengeluaran ${cat.label} naik ${( (curAmount - prevAmount) / prevAmount * 100).toStringAsFixed(0)}% dibandingkan bulan lalu.',
            type: InsightType.anomaly,
            impactAmount: diff,
          ),
        );
      }
    }

    // 3. Top Expense Category Recommendation
    if (currentCategorySpend.isNotEmpty) {
      final sorted = currentCategorySpend.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topCat = sorted.first;
      if (monthlyExpense > 0 && (topCat.value / monthlyExpense) > 0.4) {
        insights.add(
          AdvisorInsight(
            title: 'Fokus Penghematan Utama 💡',
            description:
                'Kategori ${topCat.key.label} mendominasi ${(topCat.value / monthlyExpense * 100).toStringAsFixed(0)}% total belanja Anda.',
            type: InsightType.suggestion,
          ),
        );
      }
    }

    if (insights.isEmpty) {
      insights.add(
        const AdvisorInsight(
          title: 'Kondisi Finansial Stabil ✅',
          description:
              'Tidak ada lonjakan anomali atau risiko pengeluaran berlebih terdeteksi saat ini.',
          type: InsightType.praise,
        ),
      );
    }

    return insights;
  }

  /// Natural language transaction query resolver
  static List<TransactionModel> queryTransactions({
    required List<TransactionModel> transactions,
    required String query,
  }) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return transactions;

    final now = DateTime.now();

    if (clean == 'hari ini' || clean == 'today') {
      return transactions.where((t) =>
          t.date.year == now.year &&
          t.date.month == now.month &&
          t.date.day == now.day).toList();
    }

    if (clean == 'kemarin' || clean == 'yesterday') {
      final yesterday = now.subtract(const Duration(days: 1));
      return transactions.where((t) =>
          t.date.year == yesterday.year &&
          t.date.month == yesterday.month &&
          t.date.day == yesterday.day).toList();
    }

    if (clean == 'minggu ini' || clean == 'this week') {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      return transactions.where((t) => t.date.isAfter(start.subtract(const Duration(seconds: 1)))).toList();
    }

    // Category / Title / Tag keyword search
    return transactions.where((t) {
      final inTitle = t.title.toLowerCase().contains(clean);
      final inNote = t.note?.toLowerCase().contains(clean) ?? false;
      final inCat = t.category.label.toLowerCase().contains(clean);
      final inTag = t.tags.any((tag) => tag.toLowerCase().contains(clean));
      return inTitle || inNote || inCat || inTag;
    }).toList();
  }
}
