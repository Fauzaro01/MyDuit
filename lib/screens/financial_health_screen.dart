import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/debt_provider.dart';
import '../providers/recurring_provider.dart';
import '../services/financial_health_service.dart';
import '../services/cashflow_forecast_service.dart';
import '../utils/formatters.dart';

class FinancialHealthScreen extends StatefulWidget {
  const FinancialHealthScreen({super.key});

  @override
  State<FinancialHealthScreen> createState() => _FinancialHealthScreenState();
}

class _FinancialHealthScreenState extends State<FinancialHealthScreen> {
  int _forecastDays = 30;

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final walletProvider = Provider.of<WalletProvider?>(context);
    final debtProvider = Provider.of<DebtProvider?>(context);
    final recurringProvider = Provider.of<RecurringProvider?>(context);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentBalance = walletProvider?.totalBalance ?? 0.0;
    final transactions = txProvider.transactions;
    final debts = debtProvider?.debts ?? [];
    final recurrings = recurringProvider?.activeRecurrings ?? [];

    final health = FinancialHealthService.evaluate(
      transactions: transactions,
      currentTotalBalance: currentBalance,
      debts: debts,
      monthlyIncome: txProvider.totalIncome,
      monthlyExpense: txProvider.totalExpense,
    );

    final avgDailyExpense =
        txProvider.totalExpense > 0 ? (txProvider.totalExpense / 30) : 0.0;
    final forecast = CashflowForecastService.forecast(
      currentBalance: currentBalance,
      averageDailyExpense: avgDailyExpense,
      activeRecurrings: recurrings,
      days: _forecastDays,
    );

    final hasDeficitRisk = forecast.any((f) => f.isDeficit);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kesehatan Finansial & Proyeksi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Health Score Card ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [AppColors.primaryLight, const Color(0xFF0A755C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  'SKOR KESEHATAN FINANSIAL',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${health.score}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Color(health.status.colorValue).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Color(health.status.colorValue),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    health.status.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── 50/30/20 Rule Breakdown ───────────────────────────
          Text('Rasio Anggaran 50/30/20', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildRatioRow(
                  label: 'Kebutuhan (Needs)',
                  targetText: 'Target ~50%',
                  percentage: health.needsPercentage,
                  color: AppColors.income,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildRatioRow(
                  label: 'Keinginan (Wants)',
                  targetText: 'Target ~30%',
                  percentage: health.wantsPercentage,
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildRatioRow(
                  label: 'Tabungan (Savings)',
                  targetText: 'Target ~20%',
                  percentage: health.savingsPercentage,
                  color: const Color(0xFF3B82F6),
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Emergency Fund & DTI ──────────────────────────────
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Dana Darurat',
                  value:
                      '${health.emergencyFundMonths.toStringAsFixed(1)} Bulan',
                  subtitle: health.emergencyFundMonths >= 3
                      ? '✅ Aman (>= 3 bln)'
                      : '⚠️ Perlu Ditambah',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'Rasio Hutang (DTI)',
                  value: '${health.debtToIncomeRatio.toStringAsFixed(1)}%',
                  subtitle: health.debtToIncomeRatio <= 30
                      ? '✅ Sehat (<= 30%)'
                      : '⚠️ Beban Tinggi',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Actionable Recommendations ────────────────────────
          Text('Rekomendasi Pintar', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...health.recommendations.map((rec) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rec,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),

          // ── Cashflow Projection ───────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Proyeksi Arus Kas', style: theme.textTheme.titleMedium),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 30, label: Text('30H')),
                  ButtonSegment(value: 60, label: Text('60H')),
                  ButtonSegment(value: 90, label: Text('90H')),
                ],
                selected: {_forecastDays},
                onSelectionChanged: (set) {
                  setState(() => _forecastDays = set.first);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (hasDeficitRisk)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.expense.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.expense),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.expense),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Peringatan: Saldo diproyeksikan defisit (minus) dalam periode ini. Segera kurangi pos belanja sekunder.',
                      style: TextStyle(
                        color: AppColors.expense,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Proyeksi Saldo di Hari ke-$_forecastDays:',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      CurrencyFormatter.format(
                        forecast.isNotEmpty
                            ? forecast.last.projectedBalance
                            : currentBalance,
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: (forecast.isNotEmpty &&
                                forecast.last.projectedBalance >= 0)
                            ? AppColors.income
                            : AppColors.expense,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                // Show checkpoint preview every 7 days
                ...forecast
                    .asMap()
                    .entries
                    .where((e) => (e.key + 1) % 7 == 0 || e.key == forecast.length - 1)
                    .map((e) {
                  final item = e.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormatter.shortDate(item.date),
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          CurrencyFormatter.format(item.projectedBalance),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: item.projectedBalance >= 0
                                ? (isDark ? Colors.white : Colors.black87)
                                : AppColors.expense,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRatioRow({
    required String label,
    required String targetText,
    required double percentage,
    required Color color,
    required bool isDark,
  }) {
    final clampedPct = percentage.clamp(0.0, 100.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              '${percentage.toStringAsFixed(1)}% ($targetText)',
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: clampedPct / 100,
            minHeight: 8,
            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
