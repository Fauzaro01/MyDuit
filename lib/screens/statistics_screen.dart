import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../models/transaction_model.dart';
import '../providers/custom_category_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import '../widgets/transaction_detail_sheet.dart';

class _CategoryStatItem {
  final String label;
  final String icon;
  final double amount;
  final Color color;
  final int count;
  final TransactionCategory? category;
  final String? customCategoryId;

  const _CategoryStatItem({
    required this.label,
    required this.icon,
    required this.amount,
    required this.color,
    required this.count,
    this.category,
    this.customCategoryId,
  });
}

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _showExpense = true;

  void _showCategoryTransactionsSheet(BuildContext context, _CategoryStatItem item) {
    final provider = context.read<TransactionProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transactions = (item.category != null
            ? provider.transactions.where((t) => t.category == item.category && t.customCategoryId == null)
            : provider.transactions.where((t) => t.customCategoryId == item.customCategoryId))
        .where((t) =>
            _showExpense
                ? t.type == TransactionType.expense
                : t.type == TransactionType.income)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.75,
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(item.icon, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: Theme.of(ctx).textTheme.titleLarge,
                      ),
                      Text(
                        '${transactions.length} transaksi · ${CurrencyFormatter.format(item.amount)}',
                        style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            Expanded(
              child: transactions.isEmpty
                  ? const EmptyState(message: 'Tidak ada transaksi')
                  : ListView.separated(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      itemCount: transactions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final tx = transactions[i];
                        return TransactionTile(
                          transaction: tx,
                          onDismissed: () => provider.deleteTransaction(tx.id),
                          onTap: () => showTransactionDetail(
                            context,
                            tx,
                            onDeleted: () => provider.deleteTransaction(tx.id),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTagTransactionsSheet(
    BuildContext context,
    String tag,
    List<TransactionModel> transactions,
  ) {
    final provider = context.read<TransactionProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalAmount = transactions.fold(0.0, (sum, t) => sum + t.amount);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.75,
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🏷️', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#$tag',
                        style: Theme.of(ctx).textTheme.titleLarge,
                      ),
                      Text(
                        '${transactions.length} transaksi · ${CurrencyFormatter.format(totalAmount)}',
                        style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            Expanded(
              child: transactions.isEmpty
                  ? const EmptyState(message: 'Tidak ada transaksi')
                  : ListView.separated(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      itemCount: transactions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final tx = transactions[i];
                        return TransactionTile(
                          transaction: tx,
                          onDismissed: () => provider.deleteTransaction(tx.id),
                          onTap: () => showTransactionDetail(
                            context,
                            tx,
                            onDeleted: () => provider.deleteTransaction(tx.id),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final customCatProvider = Provider.of<CustomCategoryProvider?>(context);

    final categoryTotals = _showExpense
        ? provider.expenseCategoryTotals
        : provider.incomeCategoryTotals;

    final customTotals = _showExpense
        ? provider.expenseCustomTotals
        : provider.incomeCustomTotals;

    final targetTransactions = _showExpense
        ? provider.expenseTransactions
        : provider.incomeTransactions;

    // Merge standard and custom categories into unified list
    final List<_CategoryStatItem> items = [];
    int colorIdx = 0;

    for (final entry in categoryTotals.entries) {
      if (entry.value > 0) {
        final count = targetTransactions
            .where((t) => t.category == entry.key && t.customCategoryId == null)
            .length;
        items.add(_CategoryStatItem(
          label: entry.key.label,
          icon: entry.key.icon,
          amount: entry.value,
          color: CategoryColors.getColor(entry.key.index, context),
          count: count,
          category: entry.key,
        ));
      }
    }

    for (final entry in customTotals.entries) {
      if (entry.value > 0) {
        final customCat = customCatProvider?.getCategoryById(entry.key);
        final label = customCat?.name ?? 'Kategori Kustom';
        final icon = customCat?.emoji ?? '🏷️';
        final color = customCat != null
            ? Color(customCat.colorValue)
            : CategoryColors.getColor(colorIdx + 8, context);
        final count = targetTransactions
            .where((t) => t.customCategoryId == entry.key)
            .length;
        items.add(_CategoryStatItem(
          label: label,
          icon: icon,
          amount: entry.value,
          color: color,
          count: count,
          customCategoryId: entry.key,
        ));
        colorIdx++;
      }
    }

    // Sort by amount descending
    items.sort((a, b) => b.amount.compareTo(a.amount));

    final totalAmount = items.fold(0.0, (sum, item) => sum + item.amount);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Statistik', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  const MonthSelector(),
                  const SizedBox(height: 20),

                  // Toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.cardDark
                          : AppColors.cardAltLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ToggleTab(
                            label: 'Pengeluaran',
                            isSelected: _showExpense,
                            color: AppColors.expense,
                            isDark: isDark,
                            onTap: () => setState(() => _showExpense = true),
                          ),
                        ),
                        Expanded(
                          child: _ToggleTab(
                            label: 'Pemasukan',
                            isSelected: !_showExpense,
                            color: AppColors.income,
                            isDark: isDark,
                            onTap: () => setState(() => _showExpense = false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Summary card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _showExpense
                              ? 'Total Pengeluaran'
                              : 'Total Pemasukan',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.format(totalAmount),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: _showExpense
                                ? AppColors.expense
                                : AppColors.income,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 24),

                  // Pie Chart
                  if (items.isNotEmpty) ...[
                    Text(
                      'Berdasarkan Kategori',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                          height: 220,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 50,
                              sections: _buildPieSections(items, totalAmount),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 500.ms)
                        .scale(
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1, 1),
                        ),
                    const SizedBox(height: 20),

                    // Category list
                    ...items.asMap().entries.map((mapEntry) {
                      final index = mapEntry.key;
                      final item = mapEntry.value;
                      final percentage = totalAmount > 0
                          ? (item.amount / totalAmount * 100)
                          : 0.0;

                      return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _CategoryRow(
                              item: item,
                              percentage: percentage,
                              isDark: isDark,
                              onTap: () => _showCategoryTransactionsSheet(context, item),
                            ),
                          )
                          .animate()
                          .fadeIn(
                            delay: Duration(milliseconds: 300 + (index * 80)),
                            duration: 400.ms,
                          )
                          .slideX(begin: 0.05, end: 0);
                    }),
                  ] else ...[
                    const SizedBox(height: 40),
                    const EmptyState(
                      message: 'Belum ada data untuk ditampilkan',
                      icon: Icons.bar_chart_rounded,
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Line chart section
                  if (items.isNotEmpty) ...[
                    Text('Tren Harian', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),
                    _DailyTrendChart(showExpense: _showExpense, isDark: isDark),
                    const SizedBox(height: 24),

                    // Monthly comparison chart
                    Text(
                      'Perbandingan Bulanan',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Perbandingan pengeluaran & pemasukan 6 bulan terakhir',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _MonthlyComparisonChart(isDark: isDark),
                    const SizedBox(height: 24),

                    // Weekly summary
                    Text(
                      'Ringkasan Mingguan',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _WeeklySummary(showExpense: _showExpense, isDark: isDark),
                    const SizedBox(height: 24),

                    // Tag Analytics
                    Text('Analisis Tag', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Pengeluaran & pemasukan berdasarkan #tag',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _TagAnalyticsSection(
                      transactions: targetTransactions,
                      showExpense: _showExpense,
                      totalAmount: totalAmount,
                      isDark: isDark,
                      onTapTag: (tag, txs) =>
                          _showTagTransactionsSheet(context, tag, txs),
                    ),
                  ],
                  SizedBox(
                    height: 100 + MediaQuery.paddingOf(context).bottom,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
    List<_CategoryStatItem> items,
    double total,
  ) {
    return items.map((item) {
      final percentage = total > 0 ? (item.amount / total * 100) : 0.0;

      return PieChartSectionData(
        color: item.color,
        value: item.amount,
        title: '${percentage.toStringAsFixed(0)}%',
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        radius: 45,
      );
    }).toList();
  }
}

class _CategoryRow extends StatelessWidget {
  final _CategoryStatItem item;
  final double percentage;
  final bool isDark;
  final VoidCallback? onTap;

  const _CategoryRow({
    required this.item,
    required this.percentage,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(item.icon, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.label,
                            style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${item.count})',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: item.color.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(item.color),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatCompact(item.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: theme.textTheme.titleMedium?.color,
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: item.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyTrendChart extends StatefulWidget {
  final bool showExpense;
  final bool isDark;

  const _DailyTrendChart({required this.showExpense, required this.isDark});

  @override
  State<_DailyTrendChart> createState() => _DailyTrendChartState();
}

class _DailyTrendChartState extends State<_DailyTrendChart> {
  List<FlSpot> _spots = [];
  double _maxY = 100;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  @override
  void didUpdateWidget(_DailyTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showExpense != widget.showExpense) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final provider = context.read<TransactionProvider>();
    final type = widget.showExpense
        ? TransactionType.expense
        : TransactionType.income;
    final dailyData = await provider.getDailyTotals(type);

    final spots = <FlSpot>[];
    double maxVal = 0;

    for (final row in dailyData) {
      final day = (row['day'] as num?)?.toDouble() ??
          DateTime.fromMillisecondsSinceEpoch(row['date'] as int).day.toDouble();
      final total = (row['total'] as num).toDouble();

      if (spots.isNotEmpty && spots.last.x == day) {
        final lastSpot = spots.removeLast();
        final combined = lastSpot.y + total;
        spots.add(FlSpot(day, combined));
        if (combined > maxVal) maxVal = combined;
      } else {
        spots.add(FlSpot(day, total));
        if (total > maxVal) maxVal = total;
      }
    }

    if (mounted) {
      setState(() {
        _spots = spots;
        _maxY = maxVal > 0 ? maxVal * 1.2 : 100;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.showExpense ? AppColors.expense : AppColors.income;

    if (_spots.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          'Belum ada data',
          style: TextStyle(
            color: widget.isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      );
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(16, 24, 20, 12),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _maxY / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    CurrencyFormatter.formatCompact(value),
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: _maxY,
          lineBarsData: [
            LineChartBarData(
              spots: _spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: color,
                    strokeWidth: 2,
                    strokeColor: widget.isDark
                        ? AppColors.cardDark
                        : AppColors.cardLight,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) =>
                  widget.isDark ? AppColors.cardAltDark : AppColors.cardLight,
              getTooltipItems: (spots) => spots.map((spot) {
                return LineTooltipItem(
                  'Tgl ${spot.x.toInt()}\n${CurrencyFormatter.format(spot.y)}',
                  TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 500.ms);
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.cardAltDark : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? color
                : (isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ── Monthly Comparison Bar Chart ────────────────────────────
class _MonthlyComparisonChart extends StatefulWidget {
  final bool isDark;
  const _MonthlyComparisonChart({required this.isDark});

  @override
  State<_MonthlyComparisonChart> createState() =>
      _MonthlyComparisonChartState();
}

class _MonthlyComparisonChartState extends State<_MonthlyComparisonChart> {
  List<_MonthData> _data = [];
  double _maxY = 100;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<TransactionProvider>();
    final now = DateTime(provider.selectedYear, provider.selectedMonth);
    final List<_MonthData> data = [];
    double maxVal = 0;

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final income = await provider.getTotalByTypeAndMonth(
        TransactionType.income,
        month.year,
        month.month,
      );
      final expense = await provider.getTotalByTypeAndMonth(
        TransactionType.expense,
        month.year,
        month.month,
      );
      data.add(_MonthData(month: month, income: income, expense: expense));
      if (income > maxVal) maxVal = income;
      if (expense > maxVal) maxVal = expense;
    }

    if (mounted) {
      setState(() {
        _data = data;
        _maxY = maxVal > 0 ? maxVal * 1.2 : 100;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_data.isEmpty) {
      return const SizedBox(height: 200);
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(12, 24, 16, 12),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: BarChart(
        BarChartData(
          maxY: _maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) =>
                  widget.isDark ? AppColors.cardAltDark : AppColors.cardLight,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label = rodIndex == 0 ? 'Masuk' : 'Keluar';
                return BarTooltipItem(
                  '$label\n${CurrencyFormatter.formatCompact(rod.toY)}',
                  TextStyle(
                    color: rodIndex == 0 ? AppColors.income : AppColors.expense,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _maxY / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  return Text(
                    CurrencyFormatter.formatCompact(value),
                    style: TextStyle(
                      fontSize: 9,
                      color: widget.isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= _data.length) return const SizedBox();
                  final months = [
                    'Jan',
                    'Feb',
                    'Mar',
                    'Apr',
                    'Mei',
                    'Jun',
                    'Jul',
                    'Ags',
                    'Sep',
                    'Okt',
                    'Nov',
                    'Des',
                  ];
                  return Text(
                    months[_data[idx].month.month - 1],
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: _data.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.income,
                  color: AppColors.income,
                  width: 10,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: entry.value.expense,
                  color: AppColors.expense,
                  width: 10,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
              barsSpace: 4,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _MonthData {
  final DateTime month;
  final double income;
  final double expense;
  _MonthData({
    required this.month,
    required this.income,
    required this.expense,
  });
}

// ── Weekly Summary ──────────────────────────────────────────
class _WeeklySummary extends StatefulWidget {
  final bool showExpense;
  final bool isDark;
  const _WeeklySummary({required this.showExpense, required this.isDark});

  @override
  State<_WeeklySummary> createState() => _WeeklySummaryState();
}

class _WeeklySummaryState extends State<_WeeklySummary> {
  List<double> _weeklyTotals = [0, 0, 0, 0, 0];
  int _weekCount = 5;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calculate();
  }

  @override
  void didUpdateWidget(covariant _WeeklySummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showExpense != widget.showExpense) _calculate();
  }

  void _calculate() {
    final provider = context.read<TransactionProvider>();
    final daysInMonth = DateTime(provider.selectedYear, provider.selectedMonth + 1, 0).day;
    final weekCount = (daysInMonth / 7).ceil();

    final transactions = widget.showExpense
        ? provider.expenseTransactions
        : provider.incomeTransactions;

    final weekTotals = List<double>.filled(weekCount, 0);
    for (final tx in transactions) {
      final weekIndex = ((tx.date.day - 1) / 7).floor().clamp(0, weekCount - 1);
      weekTotals[weekIndex] += tx.amount;
    }

    setState(() {
      _weekCount = weekCount;
      _weeklyTotals = weekTotals;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.showExpense ? AppColors.expense : AppColors.income;
    final maxWeek = _weeklyTotals.isEmpty
        ? 0.0
        : _weeklyTotals.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: List.generate(_weekCount, (i) {
          final pct = maxWeek > 0 ? _weeklyTotals[i] / maxWeek : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    'Minggu ${i + 1}',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: color.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: Text(
                    CurrencyFormatter.formatCompact(_weeklyTotals[i]),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 500.ms);
  }
}

// ── Tag Analytics Section ─────────────────────────────────────
class _TagAnalyticsSection extends StatelessWidget {
  final List<TransactionModel> transactions;
  final bool showExpense;
  final double totalAmount;
  final bool isDark;
  final void Function(String tag, List<TransactionModel> transactions) onTapTag;

  const _TagAnalyticsSection({
    required this.transactions,
    required this.showExpense,
    required this.totalAmount,
    required this.isDark,
    required this.onTapTag,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = showExpense ? AppColors.expense : AppColors.income;

    // Group transactions by tag
    final Map<String, List<TransactionModel>> tagMap = {};
    for (final tx in transactions) {
      for (final tag in tx.tags) {
        final cleanTag = tag.trim().toLowerCase();
        if (cleanTag.isNotEmpty) {
          tagMap.putIfAbsent(cleanTag, () => []).add(tx);
        }
      }
    }

    if (tagMap.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Text('🏷️', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Belum ada tag pada transaksi bulan ini. Tambahkan #tag saat mencatat transaksi untuk melihat analisis mendalam.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 700.ms, duration: 400.ms);
    }

    // Convert to list and sort by total amount
    final tagEntries = tagMap.entries.map((e) {
      final tagTotal = e.value.fold(0.0, (sum, t) => sum + t.amount);
      return MapEntry(e.key, {'total': tagTotal, 'txs': e.value});
    }).toList()
      ..sort((a, b) => (b.value['total'] as double).compareTo(a.value['total'] as double));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: tagEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final tag = entry.value.key;
          final tagTotal = entry.value.value['total'] as double;
          final tagTxs = entry.value.value['txs'] as List<TransactionModel>;
          final pct = totalAmount > 0 ? (tagTotal / totalAmount * 100) : 0.0;

          return Padding(
            padding: EdgeInsets.only(
              bottom: index == tagEntries.length - 1 ? 0 : 12,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onTapTag(tag, tagTxs),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 4,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${tagTxs.length} tx)',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            CurrencyFormatter.format(tagTotal),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (pct / 100).clamp(0.0, 1.0),
                          backgroundColor: color.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 700.ms, duration: 400.ms);
  }
}
