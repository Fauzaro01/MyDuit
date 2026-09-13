import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/transaction_model.dart';
import '../providers/custom_category_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/currency_provider.dart';
import '../utils/formatters.dart';
import '../screens/add_transaction_screen.dart';
import '../services/single_receipt_export_service.dart';

void showTransactionDetail(
  BuildContext context,
  TransactionModel transaction, {
  VoidCallback? onDeleted,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final isIncome = transaction.type == TransactionType.income;
  final accentColor = isIncome ? AppColors.income : AppColors.expense;
  final customCatProvider =
      Provider.of<CustomCategoryProvider?>(context, listen: false);
  final customCat = (transaction.customCategoryId != null &&
          customCatProvider != null)
      ? customCatProvider.getCategoryById(transaction.customCategoryId!)
      : null;
  final iconText = customCat?.emoji ?? transaction.category.icon;
  final categoryLabel = customCat?.name ?? transaction.category.label;

  final walletProvider =
      Provider.of<WalletProvider?>(context, listen: false);
  final wallet = transaction.walletId != null
      ? walletProvider?.getWalletById(transaction.walletId!)
      : null;

  final bottomPadding = MediaQuery.paddingOf(context).bottom;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomPadding),
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
              iconText,
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
          InkWell(
            onTap: () {
              Clipboard.setData(
                ClipboardData(
                  text:
                      '${transaction.title}: ${CurrencyFormatter.format(transaction.amount)} (${DateFormatter.fullDate(transaction.date)})',
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Detail transaksi disalin ke clipboard 📋'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                '${isIncome ? '+' : '-'} ${CurrencyFormatter.format(transaction.amount)}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          // Multi-Currency Preview
          Builder(
            builder: (context) {
              final currProvider = Provider.of<CurrencyProvider?>(context);
              if (currProvider == null) return const SizedBox.shrink();
              final usd = currProvider.convert(transaction.amount, fromCurrency: 'IDR', toCurrency: 'USD');
              final sgd = currProvider.convert(transaction.amount, fromCurrency: 'IDR', toCurrency: 'SGD');
              final jpy = currProvider.convert(transaction.amount, fromCurrency: 'IDR', toCurrency: 'JPY');
              final eur = currProvider.convert(transaction.amount, fromCurrency: 'IDR', toCurrency: 'EUR');

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardAltDark : AppColors.cardAltLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('🇺🇸 \$${usd.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    Text('🇸🇬 S\$${sgd.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    Text('🇪🇺 €${eur.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    Text('🇯🇵 ¥${jpy.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            },
          ),
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
            value: '$iconText  $categoryLabel',
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
          if (wallet != null) ...[
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Dompet',
              value: '${wallet.emoji}  ${wallet.name}',
              isDark: isDark,
            ),
          ],
          if (transaction.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardAltDark : AppColors.cardAltLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.tag_rounded,
                    size: 20,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Tag',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.end,
                      children: transaction.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: (isDark
                                    ? AppColors.primaryDark
                                    : AppColors.primaryLight)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.primaryDark
                                  : AppColors.primaryLight,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (transaction.note != null && transaction.note!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.notes_rounded,
              label: 'Catatan',
              value: transaction.note!,
              isDark: isDark,
            ),
          ],
          const SizedBox(height: 16),

          // Share receipt slip button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                SingleReceiptExportService.exportAndShareReceipt(
                  transaction,
                  walletName: wallet?.name,
                  categoryName: categoryLabel,
                );
              },
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('Bagikan Struk Transaksi (PDF)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              IconButton.outlined(
                tooltip: transaction.isPinned ? 'Lepas Pin' : 'Sematkan (Pin)',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.read<TransactionProvider>().togglePin(transaction.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        transaction.isPinned
                            ? 'Pin transaksi dilepas'
                            : 'Transaksi disematkan di atas 📌',
                      ),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: Icon(
                  transaction.isPinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  size: 20,
                  color: transaction.isPinned
                      ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                      : null,
                ),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(14),
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
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
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
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddTransactionScreen(
                          transaction: transaction,
                          isDuplicate: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Duplikat'),
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
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: 'Hapus Transaksi',
                onPressed: () async {
                  HapticFeedback.lightImpact();
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
                  size: 20,
                  color: AppColors.expense,
                ),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: BorderSide(
                    color: AppColors.expense.withValues(alpha: 0.3),
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
            color: isDark ? Colors.white60 : Colors.black54,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w600,
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
