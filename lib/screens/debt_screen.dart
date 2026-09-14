import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../models/debt_model.dart';
import '../models/debt_payment_model.dart';
import '../models/transaction_model.dart';
import '../providers/debt_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/formatters.dart';

enum DebtSortOption { dueDate, amountDesc, nameAsc }

class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DebtSortOption _sortOption = DebtSortOption.dueDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DebtProvider>().loadDebts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<DebtModel> _sortDebts(List<DebtModel> list) {
    final sorted = List<DebtModel>.from(list);
    switch (_sortOption) {
      case DebtSortOption.dueDate:
        sorted.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case DebtSortOption.amountDesc:
        sorted.sort((a, b) => b.remainingAmount.compareTo(a.remainingAmount));
        break;
      case DebtSortOption.nameAsc:
        sorted.sort((a, b) =>
            a.personName.toLowerCase().compareTo(b.personName.toLowerCase()));
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DebtProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hutang & Piutang'),
        actions: [
          PopupMenuButton<DebtSortOption>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Urutkan',
            initialValue: _sortOption,
            onSelected: (option) => setState(() => _sortOption = option),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: DebtSortOption.dueDate,
                child: Row(
                  children: [
                    Icon(Icons.event_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Jatuh Tempo'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: DebtSortOption.amountDesc,
                child: Row(
                  children: [
                    Icon(Icons.monetization_on_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Nominal Terbesar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: DebtSortOption.nameAsc,
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Nama (A-Z)'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Hutang (${provider.myDebts.length})'),
            Tab(text: 'Piutang (${provider.myReceivables.length})'),
          ],
          labelColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          indicatorColor: isDark
              ? AppColors.primaryDark
              : AppColors.primaryLight,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDebtSheet(context),
        backgroundColor: isDark
            ? AppColors.primaryDark
            : AppColors.primaryLight,
        foregroundColor: isDark ? Colors.black : Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary
                _DebtSummary(
                  isDark: isDark,
                  totalIOwe: provider.totalIOwe,
                  totalOwedToMe: provider.totalOwedToMe,
                  overdueCount: provider.overdueDebts.length,
                ).animate().fadeIn(duration: 400.ms),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _DebtList(
                        debts: _sortDebts(provider.myDebts),
                        settled: _sortDebts(provider.settledDebts
                            .where((d) => d.type == DebtType.iOwe)
                            .toList()),
                        isDark: isDark,
                        emptyMessage: 'Tidak ada hutang 🎉',
                        onAddPayment: (debt) =>
                            _showPaymentSheet(context, debt),
                        onSettle: (debt) => _confirmSettle(context, provider, debt),
                        onEdit: (debt) => _showAddDebtSheet(context, debt),
                        onDelete: (debt) => _confirmDelete(context, provider, debt),
                      ),
                      _DebtList(
                        debts: _sortDebts(provider.myReceivables),
                        settled: _sortDebts(provider.settledDebts
                            .where((d) => d.type == DebtType.owedToMe)
                            .toList()),
                        isDark: isDark,
                        emptyMessage: 'Tidak ada piutang',
                        onAddPayment: (debt) =>
                            _showPaymentSheet(context, debt),
                        onSettle: (debt) => _confirmSettle(context, provider, debt),
                        onEdit: (debt) => _showAddDebtSheet(context, debt),
                        onDelete: (debt) => _confirmDelete(context, provider, debt),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _confirmDelete(BuildContext context, DebtProvider provider, DebtModel debt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Catatan?'),
        content: Text(
          'Apakah kamu yakin ingin menghapus catatan ${debt.type == DebtType.iOwe ? "hutang ke" : "piutang dari"} "${debt.personName}" (${CurrencyFormatter.format(debt.remainingAmount)})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteDebt(debt.id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }

  void _confirmSettle(BuildContext context, DebtProvider provider, DebtModel debt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tandai Lunas?'),
        content: Text(
          debt.type == DebtType.iOwe
              ? 'Tandai hutang ke ${debt.personName} sebagai lunas?'
              : 'Tandai piutang dari ${debt.personName} sebagai lunas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              provider.settleDebt(debt);
              Navigator.pop(ctx);
            },
            child: const Text('Lunas', style: TextStyle(color: AppColors.income)),
          ),
        ],
      ),
    );
  }

  void _showAddDebtSheet(BuildContext context, [DebtModel? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddDebtSheet(
        existing: existing,
        initialType: _tabController.index == 0
            ? DebtType.iOwe
            : DebtType.owedToMe,
      ),
    );
  }

  void _showPaymentSheet(BuildContext context, DebtModel debt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DebtPaymentSheet(debt: debt),
    );
  }
}

// ── Debt Payment Bottom Sheet ────────────────────────────────
class _DebtPaymentSheet extends StatefulWidget {
  final DebtModel debt;
  const _DebtPaymentSheet({required this.debt});

  @override
  State<_DebtPaymentSheet> createState() => _DebtPaymentSheetState();
}

class _DebtPaymentSheetState extends State<_DebtPaymentSheet> {
  final _controller = TextEditingController();
  bool _syncWallet = true;
  String? _selectedWalletId;

  @override
  void initState() {
    super.initState();
    final walletProvider = Provider.of<WalletProvider?>(context, listen: false);
    final wallets = walletProvider?.wallets ?? [];
    if (wallets.isNotEmpty) {
      _selectedWalletId = walletProvider?.activeWallet?.id ?? wallets.first.id;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final walletProvider = Provider.of<WalletProvider?>(context);
    final wallets = walletProvider?.wallets ?? [];
    final isIOwe = widget.debt.type == DebtType.iOwe;

    final bottomPadding = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.paddingOf(context).bottom +
        20;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
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
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Catat Pembayaran', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            '${widget.debt.type.emoji} ${widget.debt.personName} · '
            'Sisa ${CurrencyFormatter.format(widget.debt.remainingAmount)}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Jumlah Bayar',
              prefixText: CurrencyInputService.isFormatted ? 'Rp ' : null,
              prefixIcon: const Icon(Icons.payments_rounded, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: CurrencyInputService.isFormatted
                ? [
                    FilteringTextInputFormatter.digitsOnly,
                    RupiahInputFormatter(),
                  ]
                : [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
          ),
          if (wallets.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _syncWallet,
                    onChanged: (v) => setState(() => _syncWallet = v ?? false),
                    activeColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _syncWallet = !_syncWallet),
                    child: Text(
                      isIOwe
                          ? 'Potong dari saldo dompet'
                          : 'Tambah ke saldo dompet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_syncWallet) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedWalletId,
                decoration: InputDecoration(
                  labelText: 'Pilih Dompet',
                  prefixIcon: const Icon(Icons.account_balance_wallet_rounded, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: wallets.map((w) {
                  final bal = walletProvider?.walletBalances[w.id] ?? 0.0;
                  return DropdownMenuItem(
                    value: w.id,
                    child: Text(
                      '${w.emoji} ${w.name} (${CurrencyFormatter.formatCompact(bal)})',
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedWalletId = val),
              ),
            ],
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _savePayment,
              style: FilledButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.primaryDark
                    : AppColors.primaryLight,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Bayar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _savePayment() async {
    final amount = RupiahInputFormatter.parse(_controller.text);
    if (amount <= 0) return;

    final paymentAmount = amount.clamp(0.0, widget.debt.remainingAmount);
    final debtProvider = context.read<DebtProvider>();
    final txProvider = Provider.of<TransactionProvider?>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider?>(context, listen: false);

    await debtProvider.addPayment(widget.debt.id, paymentAmount);

    if (_syncWallet && _selectedWalletId != null) {
      final isIOwe = widget.debt.type == DebtType.iOwe;

      if (txProvider != null) {
        await txProvider.addTransaction(
          TransactionModel(
            title: isIOwe
                ? 'Bayar Hutang: ${widget.debt.personName}'
                : 'Terima Piutang: ${widget.debt.personName}',
            amount: paymentAmount,
            type: isIOwe ? TransactionType.expense : TransactionType.income,
            category: isIOwe ? TransactionCategory.bills : TransactionCategory.other,
            walletId: _selectedWalletId,
            date: DateTime.now(),
            note: isIOwe
                ? 'Pembayaran hutang ke ${widget.debt.personName}'
                : 'Penerimaan piutang dari ${widget.debt.personName}',
          ),
        );
        await walletProvider?.refreshBalances();
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}

// ── Debt Summary ────────────────────────────────────────────
class _DebtSummary extends StatelessWidget {
  final bool isDark;
  final double totalIOwe;
  final double totalOwedToMe;
  final int overdueCount;

  const _DebtSummary({
    required this.isDark,
    required this.totalIOwe,
    required this.totalOwedToMe,
    required this.overdueCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text('📤 Hutang', style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.formatCompact(totalIOwe),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.expense,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: theme.dividerColor),
          Expanded(
            child: Column(
              children: [
                Text('📥 Piutang', style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.formatCompact(totalOwedToMe),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.income,
                  ),
                ),
              ],
            ),
          ),
          if (overdueCount > 0) ...[
            Container(width: 1, height: 40, color: theme.dividerColor),
            Expanded(
              child: Column(
                children: [
                  Text('⚠️ Terlambat', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    '$overdueCount',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Debt List ───────────────────────────────────────────────
class _DebtList extends StatelessWidget {
  final List<DebtModel> debts;
  final List<DebtModel> settled;
  final bool isDark;
  final String emptyMessage;
  final void Function(DebtModel) onAddPayment;
  final void Function(DebtModel) onSettle;
  final void Function(DebtModel) onEdit;
  final void Function(DebtModel) onDelete;

  const _DebtList({
    required this.debts,
    required this.settled,
    required this.isDark,
    required this.emptyMessage,
    required this.onAddPayment,
    required this.onSettle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (debts.isEmpty && settled.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
      children: [
        ...debts.asMap().entries.map(
          (entry) =>
              _DebtTile(
                    debt: entry.value,
                    isDark: isDark,
                    onAddPayment: () => onAddPayment(entry.value),
                    onSettle: () => onSettle(entry.value),
                    onEdit: () => onEdit(entry.value),
                    onDelete: () => onDelete(entry.value),
                  )
                  .animate()
                  .fadeIn(delay: (entry.key * 60).ms, duration: 400.ms)
                  .slideX(begin: 0.05, end: 0),
        ),
        if (settled.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'LUNAS (${settled.length})',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          ...settled.map(
            (debt) => _DebtTile(
              debt: debt,
              isDark: isDark,
              onAddPayment: null,
              onSettle: null,
              onEdit: null,
              onDelete: () => onDelete(debt),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Debt Tile ───────────────────────────────────────────────
class _DebtTile extends StatelessWidget {
  final DebtModel debt;
  final bool isDark;
  final VoidCallback? onAddPayment;
  final VoidCallback? onSettle;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  const _DebtTile({
    required this.debt,
    required this.isDark,
    this.onAddPayment,
    this.onSettle,
    this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = debt.isOverdue;
    final color = debt.type == DebtType.iOwe
        ? AppColors.expense
        : AppColors.income;

    final days = debt.daysUntilDue;
    Color badgeBg;
    Color badgeFg;
    String badgeText;

    if (isOverdue) {
      badgeBg = AppColors.expense.withValues(alpha: 0.15);
      badgeFg = AppColors.expense;
      badgeText = '⚠️ Terlambat ${-(days ?? 0)}h';
    } else if (days != null && days <= 7) {
      badgeBg = Colors.orange.withValues(alpha: 0.15);
      badgeFg = Colors.orange;
      badgeText = days == 0 ? '⏰ Hari ini' : '⏰ $days hari lagi';
    } else if (days != null) {
      badgeBg = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06);
      badgeFg = isDark ? Colors.white70 : Colors.black87;
      badgeText = '📅 $days hari lagi';
    } else {
      badgeBg = Colors.transparent;
      badgeFg = Colors.transparent;
      badgeText = '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: isOverdue
            ? Border.all(
                color: AppColors.expense.withValues(alpha: 0.5),
                width: 1.5,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(debt.type.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.personName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        decoration: debt.isSettled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (debt.note != null && debt.note!.isNotEmpty)
                      Text(
                        debt.note!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatCompact(debt.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: color,
                    ),
                  ),
                  if (debt.dueDate != null && !debt.isSettled) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: badgeFg,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (!debt.isSettled && debt.paidAmount > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: debt.progressPercent,
                minHeight: 6,
                backgroundColor: isDark
                    ? AppColors.cardAltDark
                    : AppColors.cardAltLight,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Dibayar ${CurrencyFormatter.formatCompact(debt.paidAmount)} '
              'dari ${CurrencyFormatter.formatCompact(debt.amount)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (!debt.isSettled) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAddPayment,
                    icon: const Icon(Icons.payments_rounded, size: 16),
                    label: const Text('Bayar'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSettle,
                    icon: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                    ),
                    label: const Text('Lunas'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.income,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: const BorderSide(color: AppColors.income),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showPaymentHistory(context, debt, isDark),
                  icon: const Icon(Icons.history_rounded, size: 20),
                  tooltip: 'Riwayat Cicilan',
                ),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'history') _showPaymentHistory(context, debt, isDark);
                    if (val == 'edit') onEdit?.call();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'history',
                      child: Row(
                        children: [
                          Icon(Icons.history_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Riwayat Pembayaran'),
                        ],
                      ),
                    ),
                    if (onEdit != null)
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                ),
              ],
            ),
          ],
          if (debt.isSettled) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showPaymentHistory(context, debt, isDark),
                icon: const Icon(Icons.history_rounded, size: 16),
                label: const Text('Lihat Riwayat Cicilan', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static void _showPaymentHistory(
    BuildContext context,
    DebtModel debt,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DebtHistorySheet(debt: debt, isDark: isDark),
    );
  }
}

// ── Debt Payment History Sheet ──────────────────────────────
class _DebtHistorySheet extends StatelessWidget {
  final DebtModel debt;
  final bool isDark;

  const _DebtHistorySheet({required this.debt, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final debtProvider = context.watch<DebtProvider>();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(debt.type.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Riwayat: ${debt.personName}',
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Total: ${CurrencyFormatter.format(debt.amount)} · Terbayar: ${CurrencyFormatter.format(debt.paidAmount)}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<DebtPaymentModel>>(
              future: debtProvider.getPaymentsForDebt(debt.id),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final payments = snapshot.data ?? [];
                if (payments.isEmpty) {
                  return Center(
                    child: Text(
                      'Belum ada riwayat cicilan',
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: payments.length,
                  separatorBuilder: (ctx, index) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final p = payments[idx];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.income.withValues(alpha: 0.15),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: AppColors.income,
                        ),
                      ),
                      title: Text(
                        CurrencyFormatter.format(p.amount),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        p.note != null && p.note!.isNotEmpty
                            ? '${DateFormatter.fullDate(p.date)} · ${p.note}'
                            : DateFormatter.fullDate(p.date),
                        style: theme.textTheme.bodySmall,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add/Edit Debt Sheet ─────────────────────────────────────
class _AddDebtSheet extends StatefulWidget {
  final DebtModel? existing;
  final DebtType initialType;
  const _AddDebtSheet({this.existing, this.initialType = DebtType.iOwe});

  @override
  State<_AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends State<_AddDebtSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late DebtType _type;
  DateTime? _dueDate;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final d = widget.existing!;
      _nameController.text = d.personName;
      _amountController.text = CurrencyInputService.isFormatted
          ? RupiahInputFormatter.formatNumber(d.amount)
          : d.amount.toStringAsFixed(0);
      _noteController.text = d.note ?? '';
      _type = d.type;
      _dueDate = d.dueDate;
    } else {
      _type = widget.initialType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.paddingOf(context).bottom + 32,
          ),
          shrinkWrap: true,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isEditing ? 'Edit' : 'Tambah Hutang/Piutang',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 20),

            // Type toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardAltLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: DebtType.values.map((t) {
                  final selected = t == _type;
                  final color = t == DebtType.iOwe
                      ? AppColors.expense
                      : AppColors.income;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _type = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${t.emoji} ${t.label}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: selected ? color : null,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nama Orang',
                prefixIcon: const Icon(Icons.person_rounded, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Masukkan nama' : null,
            ),
            const SizedBox(height: 12),

            // Amount
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Jumlah',
                prefixIcon: const Icon(Icons.payments_rounded, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: CurrencyInputService.isFormatted
                ? [RupiahInputFormatter()]
                : [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Masukkan jumlah';
                if (RupiahInputFormatter.parse(v) <= 0) {
                  return 'Jumlah harus lebih dari 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Note
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Catatan (opsional)',
                prefixIcon: const Icon(Icons.note_rounded, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Due date
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate:
                      _dueDate ?? DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (d != null) setState(() => _dueDate = d);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _dueDate != null
                          ? 'Jatuh tempo: ${DateFormatter.fullDate(_dueDate!)}'
                          : 'Tanggal Jatuh Tempo (opsional)',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: const Icon(Icons.close_rounded, size: 18),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.primaryDark
                      : AppColors.primaryLight,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _isEditing ? 'Simpan' : 'Tambah',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final debt = DebtModel(
      id: widget.existing?.id,
      personName: _nameController.text.trim(),
      amount: RupiahInputFormatter.parse(_amountController.text),
      paidAmount: widget.existing?.paidAmount ?? 0,
      type: _type,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      createdAt: widget.existing?.createdAt,
      dueDate: _dueDate,
      isSettled: widget.existing?.isSettled ?? false,
    );

    final provider = context.read<DebtProvider>();
    if (_isEditing) {
      provider.updateDebt(debt);
    } else {
      provider.addDebt(debt);
    }
    Navigator.pop(context);
  }
}
