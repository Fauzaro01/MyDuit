import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../models/debt_model.dart';
import '../providers/debt_provider.dart';
import '../utils/formatters.dart';

class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DebtProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hutang & Piutang'),
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
                        debts: provider.myDebts,
                        settled: provider.settledDebts
                            .where((d) => d.type == DebtType.iOwe)
                            .toList(),
                        isDark: isDark,
                        emptyMessage: 'Tidak ada hutang 🎉',
                        onAddPayment: (debt) =>
                            _showPaymentSheet(context, debt),
                        onSettle: (debt) => provider.settleDebt(debt),
                        onEdit: (debt) => _showAddDebtSheet(context, debt),
                        onDelete: (id) => _confirmDelete(context, provider, id),
                      ),
                      _DebtList(
                        debts: provider.myReceivables,
                        settled: provider.settledDebts
                            .where((d) => d.type == DebtType.owedToMe)
                            .toList(),
                        isDark: isDark,
                        emptyMessage: 'Tidak ada piutang',
                        onAddPayment: (debt) =>
                            _showPaymentSheet(context, debt),
                        onSettle: (debt) => provider.settleDebt(debt),
                        onEdit: (debt) => _showAddDebtSheet(context, debt),
                        onDelete: (id) => _confirmDelete(context, provider, id),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _confirmDelete(BuildContext context, DebtProvider provider, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus?'),
        content: const Text('Data hutang/piutang ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteDebt(id);
              Navigator.pop(ctx);
            },
            child: Text('Hapus', style: TextStyle(color: AppColors.expense)),
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
    final controller = TextEditingController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
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
              '${debt.type.emoji} ${debt.personName} · '
              'Sisa ${CurrencyFormatter.format(debt.remainingAmount)}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Jumlah Bayar',
                prefixIcon: const Icon(Icons.payments_rounded, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () {
                  final amount = double.tryParse(controller.text);
                  if (amount != null && amount > 0) {
                    context.read<DebtProvider>().addPayment(debt.id, amount);
                    Navigator.pop(ctx);
                  }
                },
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
      ),
    );
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
                  style: TextStyle(
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
                  style: TextStyle(
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
                    style: TextStyle(
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
  final void Function(String) onDelete;

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
                    onDelete: () => onDelete(entry.value.id),
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
              onDelete: () => onDelete(debt.id),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: isOverdue
            ? Border.all(
                color: Colors.orange.withValues(alpha: 0.5),
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
                  if (debt.dueDate != null)
                    Text(
                      isOverdue ? 'Terlambat!' : '${debt.daysUntilDue}h lagi',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isOverdue ? Colors.orange : null,
                      ),
                    ),
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
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'edit') onEdit?.call();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    if (onEdit != null)
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                ),
              ],
            ),
          ],
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
