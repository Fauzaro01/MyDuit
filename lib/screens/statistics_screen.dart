import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _showExpense = true;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final categoryTotals = _showExpense
        ? provider.expenseCategoryTotals
        : provider.incomeCategoryTotals;

    final totalAmount = categoryTotals.values.fold(0.0, (a, b) => a + b);

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
                  if (categoryTotals.isNotEmpty) ...[
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
                              sections: _buildPieSections(
                                categoryTotals,
                                totalAmount,
                                context,
                              ),
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
                    ...categoryTotals.entries.toList().asMap().entries.map((
                      mapEntry,
                    ) {
                      final index = mapEntry.key;
                      final entry = mapEntry.value;
                      final percentage = totalAmount > 0
                          ? (entry.value / totalAmount * 100)
                          : 0.0;

                      return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _CategoryRow(
                              category: entry.key,
                              amount: entry.value,
                              percentage: percentage,
                              color: CategoryColors.getColor(
                                entry.key.index,
                                context,
                              ),
                              isDark: isDark,
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
                  if (categoryTotals.isNotEmpty) ...[
                    Text('Tren Harian', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),
                    _DailyTrendChart(showExpense: _showExpense, isDark: isDark),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
    Map<TransactionCategory, double> data,
    double total,
    BuildContext context,
  ) {
    return data.entries.map((entry) {
      final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
      final color = CategoryColors.getColor(entry.key.index, context);

      return PieChartSectionData(
        color: color,
        value: entry.value,
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
  final TransactionCategory category;
  final double amount;
  final double percentage;
  final Color color;
  final bool isDark;

  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(category.icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label,
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 6),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(color),
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
                CurrencyFormatter.formatCompact(amount),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: theme.textTheme.titleMedium?.color,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
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
      final date = DateTime.fromMillisecondsSinceEpoch(row['date'] as int);
      final total = (row['total'] as num).toDouble();
      spots.add(FlSpot(date.day.toDouble(), total));
      if (total > maxVal) maxVal = total;
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
