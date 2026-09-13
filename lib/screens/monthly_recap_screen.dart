import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/transaction_provider.dart';
import '../providers/savings_provider.dart';
import '../services/monthly_recap_service.dart';
import '../utils/formatters.dart';

class MonthlyRecapScreen extends StatefulWidget {
  const MonthlyRecapScreen({super.key});

  @override
  State<MonthlyRecapScreen> createState() => _MonthlyRecapScreenState();
}

class _MonthlyRecapScreenState extends State<MonthlyRecapScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txProvider = context.watch<TransactionProvider>();
    final savingsProvider = Provider.of<SavingsProvider?>(context);

    final recap = MonthlyRecapService.generateRecap(
      year: _selectedMonth.year,
      month: _selectedMonth.month,
      allTransactions: txProvider.transactions,
      budgets: txProvider.budgets,
      goals: savingsProvider?.goals ?? [],
    );

    final monthNames = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Kilas Balik ${monthNames[_selectedMonth.month]} ${_selectedMonth.year}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
              });
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          // Persona Infographic Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                    : [const Color(0xFF6366F1), const Color(0xFF818CF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(recap.personalityEmoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 10),
                Text(
                  recap.personalityTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  recap.keyInsightSummary,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Cashflow Overview Row
          Row(
            children: [
              Expanded(
                child: _RecapStatBox(
                  label: 'Pemasukan',
                  amount: recap.totalIncome,
                  color: AppColors.income,
                  icon: Icons.arrow_downward_rounded,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RecapStatBox(
                  label: 'Pengeluaran',
                  amount: recap.totalExpense,
                  color: AppColors.expense,
                  icon: Icons.arrow_upward_rounded,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Net Savings & Rate Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tabungan Bersih',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(recap.netSavings),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: recap.netSavings >= 0 ? AppColors.income : AppColors.expense,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rasio Tabungan (Savings Rate)',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    Text(
                      '${recap.savingsRate.toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Highlights Section
          Text('Sorotan Utama Bulan Ini', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          _HighlightTile(
            icon: Icons.pie_chart_rounded,
            color: Colors.purple,
            title: 'Kategori Pengeluaran Terbesar',
            value: recap.topExpenseCategory,
            subtitle: '${CurrencyFormatter.format(recap.topExpenseCategoryAmount)} (${recap.topExpenseCategoryPercent.toStringAsFixed(0)}% dari total)',
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _HighlightTile(
            icon: Icons.calendar_today_rounded,
            color: Colors.amber,
            title: 'Hari Paling Banyak Belanja',
            value: 'Tanggal ${recap.mostExpensiveDayOfMonth}',
            subtitle: 'Total: ${CurrencyFormatter.format(recap.mostExpensiveDayAmount)}',
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _HighlightTile(
            icon: Icons.receipt_long_rounded,
            color: Colors.blue,
            title: 'Aktivitas Transaksi',
            value: '${recap.transactionCount} Transaksi Dicatat',
            subtitle: recap.expenseChangePercent == 0
                ? 'Belum ada data pembanding bulan lalu'
                : 'Pengeluaran ${recap.expenseChangePercent > 0 ? "naik" : "turun"} ${recap.expenseChangePercent.abs().toStringAsFixed(1)}% vs bulan lalu',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _RecapStatBox extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _RecapStatBox({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatCompact(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String subtitle;
  final bool isDark;

  const _HighlightTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
