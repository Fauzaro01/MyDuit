import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../utils/formatters.dart';

class InsightsCard extends StatelessWidget {
  const InsightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (provider.isLoading || provider.transactions.isEmpty) {
      return const SizedBox.shrink();
    }

    final insights = _generateInsights(provider, isDark);
    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Insight 💡', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: insights.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final insight = insights[index];
              return _InsightChip(
                    icon: insight.icon,
                    title: insight.title,
                    value: insight.value,
                    color: insight.color,
                    isDark: isDark,
                  )
                  .animate()
                  .fadeIn(
                    delay: Duration(milliseconds: 100 * index),
                    duration: 400.ms,
                  )
                  .slideX(begin: 0.1, end: 0);
            },
          ),
        ),
      ],
    );
  }

  List<_InsightData> _generateInsights(
    TransactionProvider provider,
    bool isDark,
  ) {
    final insights = <_InsightData>[];

    // 1. Savings rate
    if (provider.totalIncome > 0) {
      final savingsRate =
          ((provider.totalIncome - provider.totalExpense) /
          provider.totalIncome *
          100);
      insights.add(
        _InsightData(
          icon: Icons.savings_outlined,
          title: 'Tingkat Tabungan',
          value: '${savingsRate.toStringAsFixed(0)}%',
          color: savingsRate >= 20
              ? AppColors.income
              : (savingsRate >= 0
                    ? const Color(0xFFF59E0B)
                    : AppColors.expense),
        ),
      );
    }

    // 2. Top spending category
    if (provider.expenseCategoryTotals.isNotEmpty) {
      final topEntry = provider.expenseCategoryTotals.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      insights.add(
        _InsightData(
          icon: Icons.trending_up_rounded,
          title: 'Pengeluaran Terbesar',
          value: '${topEntry.key.icon} ${topEntry.key.label}',
          color: AppColors.expense,
        ),
      );
    }

    // 3. Average daily spending
    if (provider.totalExpense > 0) {
      final now = DateTime.now();
      final daysInMonth = DateTime(
        provider.selectedYear,
        provider.selectedMonth + 1,
        0,
      ).day;
      final currentDay =
          (provider.selectedYear == now.year &&
              provider.selectedMonth == now.month)
          ? now.day
          : daysInMonth;
      final avgDaily = provider.totalExpense / currentDay;
      insights.add(
        _InsightData(
          icon: Icons.calendar_today_rounded,
          title: 'Rata-rata/Hari',
          value: CurrencyFormatter.formatCompact(avgDaily),
          color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
        ),
      );
    }

    // 4. Transaction count
    final txCount = provider.transactions.length;
    insights.add(
      _InsightData(
        icon: Icons.receipt_outlined,
        title: 'Total Transaksi',
        value: '$txCount kali',
        color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
      ),
    );

    return insights;
  }
}

class _InsightData {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _InsightData({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });
}

class _InsightChip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final bool isDark;

  const _InsightChip({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const Spacer(),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
