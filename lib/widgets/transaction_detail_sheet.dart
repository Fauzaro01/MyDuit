import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../models/transaction_model.dart';
import '../utils/formatters.dart';
import '../screens/add_transaction_screen.dart';

void showTransactionDetail(
  BuildContext context,
  TransactionModel transaction, {
  VoidCallback? onDeleted,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final isIncome = transaction.type == TransactionType.income;
  final accentColor = isIncome ? AppColors.income : AppColors.expense;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Category icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              transaction.category.icon,
              style: const TextStyle(fontSize: 32),
            ),
          ).animate().scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
            duration: 400.ms,
            curve: Curves.easeOutBack,
          ),
          const SizedBox(height: 16),

          // Amount
          Text(
            '${isIncome ? '+' : '-'} ${CurrencyFormatter.format(transaction.amount)}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: accentColor,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          const SizedBox(height: 4),

          // Title
          Text(
            transaction.title,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Detail rows
          _DetailRow(
            icon: Icons.category_outlined,
            label: 'Kategori',
            value:
                '${transaction.category.icon}  ${transaction.category.label}',
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: isIncome
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            label: 'Tipe',
            value: isIncome ? 'Pemasukan' : 'Pengeluaran',
            isDark: isDark,
            valueColor: accentColor,
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.calendar_today_rounded,
            label: 'Tanggal',
            value: DateFormatter.fullDate(transaction.date),
            isDark: isDark,
          ),
          if (transaction.note != null && transaction.note!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.notes_rounded,
              label: 'Catatan',
              value: transaction.note!,
              isDark: isDark,
            ),
          ],
          const SizedBox(height: 28),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddTransactionScreen(transaction: transaction),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: const Text('Hapus Transaksi'),
                        content: const Text(
                          'Apakah kamu yakin ingin menghapus transaksi ini?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              'Hapus',
                              style: TextStyle(color: AppColors.expense),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      onDeleted?.call();
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AppColors.expense,
                  ),
                  label: const Text(
                    'Hapus',
                    style: TextStyle(color: AppColors.expense),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(
                      color: AppColors.expense.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardAltDark : AppColors.cardAltLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 13,
                color: valueColor,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
