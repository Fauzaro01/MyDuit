import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../providers/custom_category_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/spending_velocity_service.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

class _BudgetItem {
  final TransactionCategory category;
  final String? customCategoryId;
  final String name;
  final String icon;
  final double spent;
  final BudgetModel budget;

  const _BudgetItem({
    required this.category,
    this.customCategoryId,
    required this.name,
    required this.icon,
    required this.spent,
    required this.budget,
  });
}

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final customCatProvider = Provider.of<CustomCategoryProvider?>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Standard expense categories for budgets
    final expenseCategories = TransactionCategory.values
        .where((c) => !c.isIncomeCategory)
        .toList();

    // Custom expense categories
    final customExpenseCats = customCatProvider?.expenseCategories ?? [];

    final budgets = provider.budgets;
    final expenseTotals = provider.expenseCategoryTotals;
    final customExpenseTotals = provider.expenseCustomTotals;

    final List<_BudgetItem> budgetItems = [];

    for (final cat in expenseCategories) {
      final budget = budgets.firstWhere(
        (b) => b.category == cat && b.customCategoryId == null,
        orElse: () => BudgetModel(
          category: cat,
          monthlyLimit: 0,
          year: provider.selectedYear,
          month: provider.selectedMonth,
        ),
      );
      final spent = expenseTotals[cat] ?? 0;
      budgetItems.add(_BudgetItem(
        category: cat,
        customCategoryId: null,
        name: cat.label,
        icon: cat.icon,
        spent: spent,
        budget: budget,
      ));
    }

    for (final customCat in customExpenseCats) {
      final budget = budgets.firstWhere(
        (b) => b.customCategoryId == customCat.id,
        orElse: () => BudgetModel(
          category: TransactionCategory.other,
          customCategoryId: customCat.id,
          monthlyLimit: 0,
          year: provider.selectedYear,
          month: provider.selectedMonth,
        ),
      );
      final spent = customExpenseTotals[customCat.id] ?? 0;
      budgetItems.add(_BudgetItem(
        category: TransactionCategory.other,
        customCategoryId: customCat.id,
        name: customCat.name,
        icon: customCat.emoji,
        spent: spent,
        budget: budget,
      ));
    }

    // Calculate total budget vs total spent
    double totalBudget = 0;
    double totalSpent = 0;
    for (final item in budgetItems) {
      totalBudget += item.budget.monthlyLimit;
      totalSpent += item.spent;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anggaran'),
        actions: [
          IconButton(
            tooltip: 'Alokasi Cepat 50-30-20',
            icon: const Icon(Icons.pie_chart_outline_rounded),
            onPressed: () => _showQuickSplit503020(context, provider),
          ),
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
                                  : Colors.black.withValues(alpha: 0.04),
                              valueColor: AlwaysStoppedAnimation(
                                totalSpent > totalBudget
                                    ? AppColors.expense
                                    : (totalSpent / totalBudget >= 0.9
                                        ? const Color(0xFFEA580C)
                                        : (totalSpent / totalBudget >= 0.8
                                            ? const Color(0xFFF59E0B)
                                            : AppColors.income)),
                              ),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                totalSpent > totalBudget
                                    ? 'Melebihi anggaran ${CurrencyFormatter.format(totalSpent - totalBudget)}'
                                    : 'Sisa ${CurrencyFormatter.format(totalBudget - totalSpent)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: totalSpent > totalBudget
                                      ? AppColors.expense
                                      : (totalSpent / totalBudget >= 0.9
                                          ? const Color(0xFFEA580C)
                                          : (totalSpent / totalBudget >= 0.8
                                              ? const Color(0xFFF59E0B)
                                              : AppColors.income)),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              if (totalSpent / totalBudget >= 0.8)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (totalSpent > totalBudget
                                            ? AppColors.expense
                                            : (totalSpent / totalBudget >= 0.9
                                                ? const Color(0xFFEA580C)
                                                : const Color(0xFFF59E0B)))
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    totalSpent > totalBudget
                                        ? '⛔ Melebihi Batas'
                                        : (totalSpent / totalBudget >= 0.9
                                            ? '🚨 90% Kritis'
                                            : '⚠️ 80% Waspada'),
                                    style: TextStyle(
                                      color: totalSpent > totalBudget
                                          ? AppColors.expense
                                          : (totalSpent / totalBudget >= 0.9
                                              ? const Color(0xFFEA580C)
                                              : const Color(0xFFF59E0B)),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                  if (totalBudget > 0) ...[
                    const SizedBox(height: 16),
                    _SpendingVelocityCard(
                      totalBudget: totalBudget,
                      totalSpent: totalSpent,
                      year: provider.selectedYear,
                      month: provider.selectedMonth,
                      isDark: isDark,
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                  ],
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
              itemCount: budgetItems.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = budgetItems[index];

                return _BudgetCategoryTile(
                      name: item.name,
                      icon: item.icon,
                      spent: item.spent,
                      budget: item.budget,
                      isDark: isDark,
                      onSetBudget: () => _showSetBudgetDialog(
                        context,
                        item.name,
                        item.icon,
                        item.category,
                        item.customCategoryId,
                        item.budget,
                      ),
                    )
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: 40 * index),
                      duration: 350.ms,
                    )
                    .slideX(begin: 0.04, end: 0);
              },
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100 + MediaQuery.paddingOf(context).bottom,
            ),
          ),
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

  void _showQuickSplit503020(BuildContext context, TransactionProvider provider) {
    final controller = TextEditingController(
      text: provider.totalIncome > 0
          ? (CurrencyInputService.isFormatted
              ? RupiahInputFormatter.formatNumber(provider.totalIncome)
              : provider.totalIncome.toStringAsFixed(0))
          : '',
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            24,
            20,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.income.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.pie_chart_rounded,
                      color: AppColors.income,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Alokasi Cepat 50-30-20',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Bagi anggaran otomatis berdasarkan aturan keuangan populer: '
                '50% Kebutuhan Pokok, 30% Keinginan, dan 20% Tabungan/Investasi.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: CurrencyInputService.isFormatted
                    ? [RupiahInputFormatter()]
                    : [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  labelText: 'Target Pemasukan / Dasar Anggaran',
                  hintText: 'Misal: 10.000.000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final income = RupiahInputFormatter.parse(controller.text);
                    if (income <= 0) return;

                    HapticFeedback.mediumImpact();
                    final allocations =
                        SpendingVelocityService.generate50_30_20Envelopes(income);

                    for (final entry in allocations.entries) {
                      final existing = provider.budgets.firstWhere(
                        (b) =>
                            b.category == entry.key &&
                            b.customCategoryId == null,
                        orElse: () => BudgetModel(
                          category: entry.key,
                          monthlyLimit: 0,
                          year: provider.selectedYear,
                          month: provider.selectedMonth,
                        ),
                      );

                      provider.setBudget(
                        existing.copyWith(
                          monthlyLimit: entry.value,
                          year: provider.selectedYear,
                          month: provider.selectedMonth,
                        ),
                      );
                    }

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Anggaran 50-30-20 berhasil dialokasikan! 🎯'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_fix_high_rounded),
                  label: const Text('Terapkan Alokasi Otomatis'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.income,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSetBudgetDialog(
    BuildContext context,
    String name,
    String icon,
    TransactionCategory category,
    String? customCategoryId,
    BudgetModel currentBudget,
  ) {
    final controller = TextEditingController(
      text: currentBudget.monthlyLimit > 0
          ? (CurrencyInputService.isFormatted
                ? RupiahInputFormatter.formatNumber(currentBudget.monthlyLimit)
                : currentBudget.monthlyLimit.toStringAsFixed(0))
          : '',
    );
    bool isRollover = currentBudget.isRollover;
    final provider = context.read<TransactionProvider>();

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Anggaran $name',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
                    inputFormatters: CurrencyInputService.isFormatted
                        ? [RupiahInputFormatter()]
                        : [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      prefixText: 'Rp ',
                      hintText: '0',
                      labelText: 'Batas Anggaran',
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Smart Rollover',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Bawa sisa surplus anggaran bulan lalu ke bulan ini',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: isRollover,
                    onChanged: (val) => setModalState(() => isRollover = val),
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
                    final value = RupiahInputFormatter.parse(controller.text);
                    if (value > 0) {
                      provider.setBudget(
                        BudgetModel(
                          id: currentBudget.monthlyLimit > 0
                              ? currentBudget.id
                              : null,
                          category: category,
                          customCategoryId: customCategoryId,
                          monthlyLimit: value,
                          year: provider.selectedYear,
                          month: provider.selectedMonth,
                          isRollover: isRollover,
                        ),
                      );
                    } else if (currentBudget.monthlyLimit > 0) {
                      provider.deleteBudget(currentBudget.id);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _BudgetCategoryTile extends StatelessWidget {
  final String name;
  final String icon;
  final double spent;
  final BudgetModel budget;
  final bool isDark;
  final VoidCallback onSetBudget;

  const _BudgetCategoryTile({
    required this.name,
    required this.icon,
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
        : (percentage >= 90
            ? const Color(0xFFEA580C)
            : (percentage >= 80 ? const Color(0xFFF59E0B) : AppColors.income));

    String? statusBadge;
    if (hasBudget) {
      if (isOver) {
        statusBadge = '⛔ Melebihi Batas';
      } else if (percentage >= 90) {
        statusBadge = '🚨 90% Kritis';
      } else if (percentage >= 80) {
        statusBadge = '⚠️ 80% Waspada';
      }
    }

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
                    icon,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (budget.isRollover) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Rollover',
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
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
                      ),
                      if (statusBadge != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          statusBadge,
                          style: TextStyle(
                            color: barColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
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

class _SpendingVelocityCard extends StatelessWidget {
  final double totalBudget;
  final double totalSpent;
  final int year;
  final int month;
  final bool isDark;

  const _SpendingVelocityCard({
    required this.totalBudget,
    required this.totalSpent,
    required this.year,
    required this.month,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final velocity = SpendingVelocityService.calculateVelocity(
      totalBudget: totalBudget,
      totalSpent: totalSpent,
      year: year,
      month: month,
    );

    Color statusColor;
    IconData statusIcon;
    switch (velocity.status) {
      case SpendingPaceStatus.underPace:
        statusColor = AppColors.income;
        statusIcon = Icons.speed_rounded;
        break;
      case SpendingPaceStatus.onTrack:
        statusColor = Colors.blueAccent;
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case SpendingPaceStatus.fastPace:
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.warning_amber_rounded;
        break;
      case SpendingPaceStatus.critical:
        statusColor = AppColors.expense;
        statusIcon = Icons.error_outline_rounded;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Spending Velocity & Burn Pace',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: statusColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Hari ke-${velocity.daysElapsed} / ${velocity.daysInMonth}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            velocity.statusMessage,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Batas Harian Ideal', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(
                    '${CurrencyFormatter.formatCompact(velocity.dailyBurnTarget)}/hari',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Rata-rata Terpakai', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(
                    '${CurrencyFormatter.formatCompact(velocity.actualDailyBurn)}/hari',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: velocity.actualDailyBurn > velocity.dailyBurnTarget
                          ? AppColors.expense
                          : AppColors.income,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Proyeksi Akhir Bulan', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.formatCompact(velocity.projectedMonthEndSpend),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: velocity.projectedMonthEndSpend > velocity.totalBudget
                          ? AppColors.expense
                          : AppColors.income,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
