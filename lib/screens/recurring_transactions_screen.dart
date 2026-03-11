import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../models/recurring_transaction_model.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import '../providers/recurring_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/formatters.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends State<RecurringTransactionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecurringProvider>().loadRecurringTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecurringProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final active = provider.activeRecurrings;
    final inactive = provider.inactiveRecurrings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi Berulang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context),
        backgroundColor: isDark
            ? AppColors.primaryDark
            : AppColors.primaryLight,
        foregroundColor: isDark ? Colors.black : Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : (active.isEmpty && inactive.isEmpty)
          ? _buildEmpty(theme)
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (active.isNotEmpty) ...[
                  _SectionHeader(title: 'Aktif (${active.length})'),
                  const SizedBox(height: 12),
                  ...active.asMap().entries.map(
                    (entry) =>
                        _RecurringTile(
                              recurring: entry.value,
                              isDark: isDark,
                              onTap: () =>
                                  _showAddEditDialog(context, entry.value),
                              onToggle: () =>
                                  provider.toggleActive(entry.value),
                              onDelete: () => _confirmDelete(
                                context,
                                provider,
                                entry.value.id,
                              ),
                            )
                            .animate()
                            .fadeIn(
                              delay: (entry.key * 60).ms,
                              duration: 400.ms,
                            )
                            .slideX(begin: 0.05, end: 0),
                  ),
                ],
                if (inactive.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Nonaktif (${inactive.length})'),
                  const SizedBox(height: 12),
                  ...inactive.asMap().entries.map(
                    (entry) => _RecurringTile(
                      recurring: entry.value,
                      isDark: isDark,
                      onTap: () => _showAddEditDialog(context, entry.value),
                      onToggle: () => provider.toggleActive(entry.value),
                      onDelete: () =>
                          _confirmDelete(context, provider, entry.value.id),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.repeat_rounded,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada transaksi berulang',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Otomatiskan tagihan & pemasukan rutin',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Transaksi Berulang'),
        content: const Text(
          'Fitur ini membantu mencatat transaksi yang terjadi secara '
          'berkala, seperti gaji bulanan, tagihan listrik, langganan '
          'streaming, dll.\n\n'
          'Transaksi otomatis dibuat setiap kali Anda membuka aplikasi '
          'jika sudah melewati jadwal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    RecurringProvider provider,
    String id,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus?'),
        content: const Text(
          'Transaksi berulang ini akan dihapus. Transaksi yang sudah '
          'dibuat sebelumnya tidak akan terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteRecurringTransaction(id);
              Navigator.pop(ctx);
            },
            child: Text('Hapus', style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(
    BuildContext context, [
    RecurringTransactionModel? existing,
  ]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddEditRecurringSheet(existing: existing),
    );
  }
}

// ── Add/Edit Sheet ──────────────────────────────────────────
class _AddEditRecurringSheet extends StatefulWidget {
  final RecurringTransactionModel? existing;
  const _AddEditRecurringSheet({this.existing});

  @override
  State<_AddEditRecurringSheet> createState() => _AddEditRecurringSheetState();
}

class _AddEditRecurringSheetState extends State<_AddEditRecurringSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late TransactionType _type;
  late TransactionCategory _category;
  late RecurrenceFrequency _frequency;
  late DateTime _startDate;
  DateTime? _endDate;
  WalletModel? _selectedWallet;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final r = widget.existing!;
      _titleController.text = r.title;
      _amountController.text = CurrencyInputService.isFormatted
          ? RupiahInputFormatter.formatNumber(r.amount)
          : r.amount.toStringAsFixed(0);
      _noteController.text = r.note ?? '';
      _type = r.type;
      _category = r.category;
      _frequency = r.frequency;
      _startDate = r.startDate;
      _endDate = r.endDate;
    } else {
      _type = TransactionType.expense;
      _category = TransactionCategory.bills;
      _frequency = RecurrenceFrequency.monthly;
      _startDate = DateTime.now();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wallets = context.read<WalletProvider>().wallets;
      if (widget.existing?.walletId != null) {
        final match = wallets.where((w) => w.id == widget.existing!.walletId);
        if (match.isNotEmpty) setState(() => _selectedWallet = match.first);
      } else if (wallets.isNotEmpty) {
        setState(
          () => _selectedWallet = wallets.firstWhere(
            (w) => w.isDefault,
            orElse: () => wallets.first,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final wallets = context.watch<WalletProvider>().wallets;

    final categories = _type == TransactionType.income
        ? TransactionCategory.values.where((c) => c.isIncomeCategory).toList()
        : TransactionCategory.values.where((c) => !c.isIncomeCategory).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
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
              _isEditing
                  ? 'Edit Transaksi Berulang'
                  : 'Tambah Transaksi Berulang',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 20),

            // Type toggle
            _buildTypeToggle(theme, isDark),
            const SizedBox(height: 16),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration('Judul', Icons.text_fields_rounded),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Masukkan judul' : null,
            ),
            const SizedBox(height: 12),

            // Amount
            TextFormField(
              controller: _amountController,
              decoration: _inputDecoration('Jumlah', Icons.payments_rounded),
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
              decoration: _inputDecoration(
                'Catatan (opsional)',
                Icons.note_rounded,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Frequency
            Text('Frekuensi', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: RecurrenceFrequency.values.map((f) {
                final selected = f == _frequency;
                return ChoiceChip(
                  label: Text(f.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _frequency = f),
                  selectedColor: isDark
                      ? AppColors.primaryDark
                      : AppColors.primaryLight,
                  labelStyle: TextStyle(
                    color: selected
                        ? (isDark ? Colors.black : Colors.white)
                        : null,
                    fontWeight: selected ? FontWeight.w600 : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Category
            Text('Kategori', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((c) {
                final selected = c == _category;
                return ChoiceChip(
                  avatar: Text(c.icon, style: const TextStyle(fontSize: 16)),
                  label: Text(c.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = c),
                  selectedColor: isDark
                      ? AppColors.primaryDark
                      : AppColors.primaryLight,
                  labelStyle: TextStyle(
                    color: selected
                        ? (isDark ? Colors.black : Colors.white)
                        : null,
                    fontWeight: selected ? FontWeight.w600 : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Wallet
            if (wallets.isNotEmpty) ...[
              Text('Dompet', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: wallets.map((w) {
                  final selected = w.id == _selectedWallet?.id;
                  return ChoiceChip(
                    avatar: Text(w.emoji, style: const TextStyle(fontSize: 16)),
                    label: Text(w.name),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedWallet = w),
                    selectedColor: Color(w.colorValue),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                      fontWeight: selected ? FontWeight.w600 : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Date row
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: 'Mulai',
                    date: _startDate,
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setState(() => _startDate = d);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateButton(
                    label: _endDate != null ? 'Berakhir' : 'Tanpa akhir',
                    date: _endDate,
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? _startDate,
                        firstDate: _startDate,
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setState(() => _endDate = d);
                    },
                    onClear: _endDate != null
                        ? () => setState(() => _endDate = null)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Save button
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

  Widget _buildTypeToggle(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardAltLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _typeButton('Pengeluaran', TransactionType.expense, theme, isDark),
          _typeButton('Pemasukan', TransactionType.income, theme, isDark),
        ],
      ),
    );
  }

  Widget _typeButton(
    String label,
    TransactionType type,
    ThemeData theme,
    bool isDark,
  ) {
    final selected = _type == type;
    final color = type == TransactionType.income
        ? AppColors.income
        : AppColors.expense;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _type = type;
            _category = type == TransactionType.income
                ? TransactionCategory.salary
                : TransactionCategory.food;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? color : theme.textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final recurring = RecurringTransactionModel(
      id: widget.existing?.id,
      title: _titleController.text.trim(),
      amount: RupiahInputFormatter.parse(_amountController.text),
      type: _type,
      category: _category,
      frequency: _frequency,
      startDate: _startDate,
      endDate: _endDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      walletId: _selectedWallet?.id,
      isActive: widget.existing?.isActive ?? true,
      lastGeneratedDate: widget.existing?.lastGeneratedDate,
    );

    final provider = context.read<RecurringProvider>();
    if (_isEditing) {
      provider.updateRecurringTransaction(recurring);
    } else {
      provider.addRecurringTransaction(recurring);
    }
    Navigator.pop(context);
  }
}

// ── Recurring Tile ──────────────────────────────────────────
class _RecurringTile extends StatelessWidget {
  final RecurringTransactionModel recurring;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _RecurringTile({
    required this.recurring,
    required this.isDark,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpense = recurring.type == TransactionType.expense;
    final color = isExpense ? AppColors.expense : AppColors.income;

    return Dismissible(
      key: Key(recurring.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.expense.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.expense),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    recurring.category.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recurring.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        decoration: recurring.isActive
                            ? null
                            : TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${recurring.frequency.label} · '
                      '${recurring.category.label}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isExpense ? "-" : "+"}${CurrencyFormatter.formatCompact(recurring.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Switch.adaptive(
                    value: recurring.isActive,
                    onChanged: (_) => onToggle(),
                    activeColor: isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

// ── Date Button ─────────────────────────────────────────────
class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateButton({
    required this.label,
    this.date,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                  ),
                  if (date != null)
                    Text(
                      DateFormatter.shortDate(date!),
                      style: theme.textTheme.titleSmall,
                    ),
                ],
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Section Header ──────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        letterSpacing: 1.2,
      ),
    );
  }
}
