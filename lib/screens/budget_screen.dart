import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Only expense categories for budgets
    final expenseCategories = TransactionCategory.values
        .where((c) => !c.isIncomeCategory)
        .toList();

    final budgets = provider.budgets;
    final expenseTotals = provider.expenseCategoryTotals;

    // Calculate total budget vs total spent
    double totalBudget = 0;
    double totalSpent = 0;
    for (final cat in expenseCategories) {
      final budget = budgets.firstWhere(
        (b) => b.category == cat,
        orElse: () => BudgetModel(
          category: cat,
          monthlyLimit: 0,
          year: provider.selectedYear,
          month: provider.selectedMonth,
        ),
      );
      totalBudget += budget.monthlyLimit;
      totalSpent += expenseTotals[cat] ?? 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anggaran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                children: [
                  const MonthSelector(),
                  const SizedBox(height: 20),

                  // Overall budget summary
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Terpakai',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.format(totalSpent),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color:
                                        totalBudget > 0 &&
                                            totalSpent > totalBudget
                                        ? AppColors.expense
                                        : AppColors.income,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Total Anggaran',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  totalBudget > 0
                                      ? CurrencyFormatter.format(totalBudget)
                                      : 'Belum diatur',
                                  style: theme.textTheme.titleLarge,
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (totalBudget > 0) ...[
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (totalSpent / totalBudget).clamp(0.0, 1.0),
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.05),
                              valueColor: AlwaysStoppedAnimation(
                                totalSpent > totalBudget
                                    ? AppColors.expense
                                    : AppColors.income,
                              ),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            totalSpent > totalBudget
                                ? 'Melebihi anggaran ${CurrencyFormatter.format(totalSpent - totalBudget)}'
                                : 'Sisa ${CurrencyFormatter.format(totalBudget - totalSpent)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: totalSpent > totalBudget
                                  ? AppColors.expense
                                  : AppColors.income,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Anggaran per Kategori',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: expenseCategories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final cat = expenseCategories[index];
                final spent = expenseTotals[cat] ?? 0;
                final budget = budgets.firstWhere(
                  (b) => b.category == cat,
                  orElse: () => BudgetModel(
                    category: cat,
                    monthlyLimit: 0,
                    year: provider.selectedYear,
                    month: provider.selectedMonth,
                  ),
                );

                return _BudgetCategoryTile(
                      category: cat,
                      spent: spent,
                      budget: budget,
                      isDark: isDark,
                      onSetBudget: () =>
                          _showSetBudgetDialog(context, cat, budget),
                    )
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: 60 * index),
                      duration: 400.ms,
                    )
                    .slideX(begin: 0.04, end: 0);
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tentang Anggaran'),
        content: const Text(
          'Tetapkan batas pengeluaran per kategori setiap bulan. '
          'Kamu akan melihat progress bar yang menunjukkan berapa persen '
          'anggaran yang sudah terpakai. Jika melebihi batas, indikator '
          'akan berubah menjadi merah.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  void _showSetBudgetDialog(
    BuildContext context,
    TransactionCategory category,
    BudgetModel currentBudget,
  ) {
    final controller = TextEditingController(
      text: currentBudget.monthlyLimit > 0
          ? currentBudget.monthlyLimit.toStringAsFixed(0)
          : '',
    );
    final provider = context.read<TransactionProvider>();

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Text(category.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Text('Anggaran ${category.label}'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tetapkan batas pengeluaran bulanan untuk kategori ini.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  prefixText: 'Rp ',
                  hintText: '0',
                  labelText: 'Batas Anggaran',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            if (currentBudget.monthlyLimit > 0)
              TextButton(
                onPressed: () {
                  provider.deleteBudget(currentBudget.id);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Hapus',
                  style: TextStyle(color: AppColors.expense),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                final value = double.tryParse(controller.text);
                if (value != null && value > 0) {
                  provider.setBudget(
                    BudgetModel(
                      id: currentBudget.monthlyLimit > 0
                          ? currentBudget.id
                          : null,
                      category: category,
                      monthlyLimit: value,
                      year: provider.selectedYear,
                      month: provider.selectedMonth,
                    ),
                  );
                }
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}

class _BudgetCategoryTile extends StatelessWidget {
  final TransactionCategory category;
  final double spent;
  final BudgetModel budget;
  final bool isDark;
  final VoidCallback onSetBudget;

  const _BudgetCategoryTile({
    required this.category,
    required this.spent,
    required this.budget,
    required this.isDark,
    required this.onSetBudget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasBudget = budget.monthlyLimit > 0;
    final percentage = hasBudget
        ? (spent / budget.monthlyLimit * 100).clamp(0.0, 150.0)
        : 0.0;
    final isOver = hasBudget && spent > budget.monthlyLimit;

    final barColor = isOver
        ? AppColors.expense
        : (percentage > 80 ? const Color(0xFFF59E0B) : AppColors.income);

    return InkWell(
      onTap: onSetBudget,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isOver
                        ? AppColors.expenseSoft
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.04)),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    category.icon,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasBudget
                            ? '${CurrencyFormatter.formatCompact(spent)} / ${CurrencyFormatter.formatCompact(budget.monthlyLimit)}'
                            : 'Belum diatur',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: isOver ? AppColors.expense : null,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasBudget)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: barColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: barColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    size: 22,
                  ),
              ],
            ),
            if (hasBudget) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (percentage / 100).clamp(0.0, 1.0),
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04),
                  valueColor: AlwaysStoppedAnimation(barColor),
                  minHeight: 6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
