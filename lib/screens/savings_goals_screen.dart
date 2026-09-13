import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../models/savings_goal_model.dart';
import '../models/transaction_model.dart';
import '../providers/savings_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/formatters.dart';
import '../widgets/emoji_picker_sheet.dart';
import '../services/auto_allocation_engine.dart';

class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SavingsProvider>().loadGoals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SavingsProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final active = provider.activeGoals;
    final completed = provider.completedGoals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tujuan Tabungan'),
        actions: [
          if (active.length > 1)
            IconButton(
              icon: const Icon(Icons.auto_awesome_rounded),
              tooltip: 'Alokasi Cerdas Multi-Target',
              onPressed: () => _showAutoAllocationSheet(context, active),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalSheet(context),
        backgroundColor: isDark
            ? AppColors.primaryDark
            : AppColors.primaryLight,
        foregroundColor: isDark ? Colors.black : Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : (active.isEmpty && completed.isEmpty)
          ? _buildEmpty(theme)
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Summary card
                if (active.isNotEmpty)
                  _SummaryCard(
                        isDark: isDark,
                        totalSaved: provider.totalSaved,
                        totalTarget: provider.totalTarget,
                        activeCount: active.length,
                      )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.05, end: 0),
                const SizedBox(height: 20),

                if (active.isNotEmpty) ...[
                  _SectionHeader(title: 'Sedang Berjalan'),
                  const SizedBox(height: 12),
                  ...active.asMap().entries.map(
                    (entry) =>
                        _GoalCard(
                              goal: entry.value,
                              isDark: isDark,
                              onAddAmount: () =>
                                  _showAddAmountSheet(context, entry.value),
                              onEdit: () =>
                                  _showAddGoalSheet(context, entry.value),
                              onDelete: () => _confirmDelete(
                                context,
                                provider,
                                entry.value.id,
                              ),
                            )
                            .animate()
                            .fadeIn(
                              delay: (entry.key * 80).ms,
                              duration: 400.ms,
                            )
                            .slideY(begin: 0.05, end: 0),
                  ),
                ],
                if (completed.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Tercapai 🎉 (${completed.length})'),
                  const SizedBox(height: 12),
                  ...completed.map(
                    (goal) => _GoalCard(
                      goal: goal,
                      isDark: isDark,
                      onAddAmount: null,
                      onEdit: null,
                      onDelete: () =>
                          _confirmDelete(context, provider, goal.id),
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
            Icons.savings_rounded,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text('Belum ada tujuan tabungan', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Mulai menabung untuk impianmu!',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    SavingsProvider provider,
    String id,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Tujuan?'),
        content: const Text('Tujuan tabungan ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteGoal(id);
              Navigator.pop(ctx);
            },
            child: Text('Hapus', style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }

  void _showAddGoalSheet(BuildContext context, [SavingsGoalModel? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddGoalSheet(existing: existing),
    );
  }

  void _showAutoAllocationSheet(
    BuildContext context,
    List<SavingsGoalModel> activeGoals,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AutoAllocationSheet(activeGoals: activeGoals),
    );
  }

  void _showAddAmountSheet(BuildContext context, SavingsGoalModel goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DepositSavingsSheet(goal: goal),
    );
  }
}

// ── Deposit Savings Bottom Sheet ─────────────────────────────
class _DepositSavingsSheet extends StatefulWidget {
  final SavingsGoalModel goal;
  const _DepositSavingsSheet({required this.goal});

  @override
  State<_DepositSavingsSheet> createState() => _DepositSavingsSheetState();
}

class _DepositSavingsSheetState extends State<_DepositSavingsSheet> {
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
          Text('Tambah Tabungan', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            '${widget.goal.emoji} ${widget.goal.title} · Sisa ${CurrencyFormatter.format(widget.goal.remainingAmount)}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Jumlah',
              prefixText: CurrencyInputService.isFormatted ? 'Rp ' : null,
              prefixIcon: const Icon(Icons.payments_rounded, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: CurrencyInputService.isFormatted
                ? [RupiahInputFormatter()]
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
                      'Potong dari saldo dompet',
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
              onPressed: _saveDeposit,
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
                'Simpan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveDeposit() async {
    final amount = RupiahInputFormatter.parse(_controller.text);
    if (amount <= 0) return;

    final savingsProvider = context.read<SavingsProvider>();
    final txProvider = Provider.of<TransactionProvider?>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider?>(context, listen: false);

    await savingsProvider.addAmountToGoal(widget.goal.id, amount);

    if (_syncWallet && _selectedWalletId != null) {
      if (txProvider != null) {
        await txProvider.addTransaction(
          TransactionModel(
            title: 'Tabungan: ${widget.goal.title}',
            amount: amount,
            type: TransactionType.expense,
            category: TransactionCategory.other,
            walletId: _selectedWalletId,
            date: DateTime.now(),
            note: 'Setor ke tabungan ${widget.goal.emoji} ${widget.goal.title}',
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

// ── Summary Card ────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final bool isDark;
  final double totalSaved;
  final double totalTarget;
  final int activeCount;

  const _SummaryCard({
    required this.isDark,
    required this.totalSaved,
    required this.totalTarget,
    required this.activeCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = totalTarget > 0
        ? (totalSaved / totalTarget).clamp(0.0, 1.0)
        : 0.0;

    return Container(
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
                  Text('Total Terkumpul', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(totalSaved),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.income.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$activeCount aktif',
                  style: const TextStyle(
                    color: AppColors.income,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark
                  ? AppColors.cardAltDark
                  : AppColors.cardAltLight,
              color: AppColors.income,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'Target: ${CurrencyFormatter.formatCompact(totalTarget)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Goal Card ───────────────────────────────────────────────
class _GoalCard extends StatelessWidget {
  final SavingsGoalModel goal;
  final bool isDark;
  final VoidCallback? onAddAmount;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.isDark,
    this.onAddAmount,
    this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = goal.progressPercent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(goal.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                      ),
                    ),
                    if (goal.targetDate != null)
                      Text(
                        'Target: ${DateFormatter.fullDate(goal.targetDate!)}',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
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
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: isDark
                  ? AppColors.cardAltDark
                  : AppColors.cardAltLight,
              color: goal.isCompleted
                  ? AppColors.income
                  : (isDark ? AppColors.primaryDark : AppColors.primaryLight),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${CurrencyFormatter.formatCompact(goal.currentAmount)} / '
                '${CurrencyFormatter.formatCompact(goal.targetAmount)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: goal.isCompleted
                      ? AppColors.income
                      : (isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight),
                ),
              ),
            ],
          ),
          if (!goal.isCompleted && goal.estimatedDaysRemaining != null) ...[
            const SizedBox(height: 4),
            Text(
              'Estimasi ${goal.estimatedDaysRemaining} hari lagi',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (onAddAmount != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAddAmount,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tambah Tabungan'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Add/Edit Goal Sheet ─────────────────────────────────────
class _AddGoalSheet extends StatefulWidget {
  final SavingsGoalModel? existing;
  const _AddGoalSheet({this.existing});

  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  final _currentController = TextEditingController();

  late String _emoji;
  DateTime? _targetDate;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final g = widget.existing!;
      _titleController.text = g.title;
      _targetController.text = CurrencyInputService.isFormatted
          ? RupiahInputFormatter.formatNumber(g.targetAmount)
          : g.targetAmount.toStringAsFixed(0);
      _currentController.text = CurrencyInputService.isFormatted
          ? RupiahInputFormatter.formatNumber(g.currentAmount)
          : g.currentAmount.toStringAsFixed(0);
      _emoji = g.emoji;
      _targetDate = g.targetDate;
    } else {
      _emoji = '🎯';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _currentController.dispose();
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
              _isEditing ? 'Edit Tujuan' : 'Tambah Tujuan Tabungan',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 20),

            // Emoji picker
            Text('Ikon', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SavingsGoalModel.presetEmojis.map((e) {
                final selected = e == _emoji;
                return GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? (isDark
                                    ? AppColors.primaryDark
                                    : AppColors.primaryLight)
                                .withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: selected
                          ? Border.all(
                              color: isDark
                                  ? AppColors.primaryDark
                                  : AppColors.primaryLight,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(e, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.grid_view_rounded, size: 16),
              label: const Text('Koleksi Emoji Lainnya...'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () async {
                final picked = await EmojiPickerSheet.show(
                  context,
                  initialEmoji: _emoji,
                );
                if (picked != null) {
                  setState(() => _emoji = picked);
                }
              },
            ),
            const SizedBox(height: 16),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Nama Tujuan',
                prefixIcon: const Icon(Icons.flag_rounded, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Masukkan nama' : null,
            ),
            const SizedBox(height: 12),

            // Target
            TextFormField(
              controller: _targetController,
              decoration: InputDecoration(
                labelText: 'Target',
                prefixIcon: const Icon(Icons.track_changes_rounded, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: CurrencyInputService.isFormatted
                  ? [RupiahInputFormatter()]
                  : [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Masukkan target';
                if (RupiahInputFormatter.parse(v) <= 0) {
                  return 'Target harus lebih dari 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Current amount (for editing)
            if (_isEditing) ...[
              TextFormField(
                controller: _currentController,
                decoration: InputDecoration(
                  labelText: 'Jumlah Saat Ini',
                  prefixIcon: const Icon(Icons.savings_rounded, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: CurrencyInputService.isFormatted
                    ? [RupiahInputFormatter()]
                    : [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
            ],

            // Target date
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate:
                      _targetDate ??
                      DateTime.now().add(const Duration(days: 90)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (d != null) setState(() => _targetDate = d);
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
                    const Icon(Icons.calendar_today_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _targetDate != null
                          ? 'Target: ${DateFormatter.fullDate(_targetDate!)}'
                          : 'Tanggal Target (opsional)',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    if (_targetDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _targetDate = null),
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

    final goal = SavingsGoalModel(
      id: widget.existing?.id,
      title: _titleController.text.trim(),
      emoji: _emoji,
      targetAmount: RupiahInputFormatter.parse(_targetController.text),
      currentAmount: _isEditing
          ? RupiahInputFormatter.parse(_currentController.text)
          : 0,
      createdAt: widget.existing?.createdAt,
      targetDate: _targetDate,
      isCompleted: widget.existing?.isCompleted ?? false,
    );

    final provider = context.read<SavingsProvider>();
    if (_isEditing) {
      provider.updateGoal(goal);
    } else {
      provider.addGoal(goal);
    }
    Navigator.pop(context);
  }
}

// ── Multi-Goal Auto Allocation Sheet ────────────────────────
class _AutoAllocationSheet extends StatefulWidget {
  final List<SavingsGoalModel> activeGoals;
  const _AutoAllocationSheet({required this.activeGoals});

  @override
  State<_AutoAllocationSheet> createState() => _AutoAllocationSheetState();
}

class _AutoAllocationSheetState extends State<_AutoAllocationSheet> {
  final _amountController = TextEditingController();
  AllocationStrategy _strategy = AllocationStrategy.proportional;
  String? _selectedWalletId;
  bool _syncWallet = true;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final wallets = context.watch<WalletProvider>().wallets;
    _selectedWalletId ??= wallets.isNotEmpty ? wallets.first.id : null;

    final inputAmount = RupiahInputFormatter.parse(_amountController.text);
    final allocations = AutoAllocationEngine.calculateAllocation(
      depositAmount: inputAmount,
      activeGoals: widget.activeGoals,
      strategy: _strategy,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Alokasi Tabungan Cerdas', style: theme.textTheme.titleLarge),
                      Text(
                        'Distribusikan dana ke beberapa target sekaligus',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Total Dana yang Ingin Ditabung',
                prefixText: CurrencyInputService.isFormatted ? 'Rp ' : null,
                prefixIcon: const Icon(Icons.account_balance_wallet_rounded, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: CurrencyInputService.isFormatted
                  ? [RupiahInputFormatter()]
                  : [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Text('Strategi Distribusi:', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<AllocationStrategy>(
              segments: const [
                ButtonSegment(
                  value: AllocationStrategy.proportional,
                  label: Text('Proporsional', style: TextStyle(fontSize: 11)),
                ),
                ButtonSegment(
                  value: AllocationStrategy.equal,
                  label: Text('Bagi Rata', style: TextStyle(fontSize: 11)),
                ),
                ButtonSegment(
                  value: AllocationStrategy.priorityFirst,
                  label: Text('Prioritas', style: TextStyle(fontSize: 11)),
                ),
              ],
              selected: {_strategy},
              onSelectionChanged: (set) => setState(() => _strategy = set.first),
            ),
            const SizedBox(height: 16),
            if (allocations.isNotEmpty) ...[
              Text('Pratinjau Pembagian:', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              ...allocations.map((alloc) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: alloc.willComplete
                          ? AppColors.income.withValues(alpha: 0.5)
                          : (isDark ? Colors.white10 : Colors.black12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(alloc.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alloc.goalTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'Hasil: ${CurrencyFormatter.formatCompact(alloc.newCurrentAmount)} / ${CurrencyFormatter.formatCompact(alloc.targetAmount)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '+ ${CurrencyFormatter.format(alloc.allocatedAmount)}',
                            style: const TextStyle(
                              color: AppColors.income,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          if (alloc.willComplete)
                            const Text(
                              'Target Tercapai! 🎉',
                              style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 14),
            ],
            if (wallets.isNotEmpty) ...[
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _syncWallet,
                      onChanged: (v) => setState(() => _syncWallet = v ?? false),
                      activeColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _syncWallet = !_syncWallet),
                      child: Text(
                        'Potong dari saldo dompet',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
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
                    labelText: 'Pilih Dompet Sumber',
                    prefixIcon: const Icon(Icons.account_balance_wallet_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  items: wallets.map((w) {
                    final bal = context.read<WalletProvider>().walletBalances[w.id] ?? 0.0;
                    return DropdownMenuItem(
                      value: w.id,
                      child: Text('${w.name} (${CurrencyFormatter.formatCompact(bal)})'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedWalletId = val),
                ),
              ],
              const SizedBox(height: 20),
            ],
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: inputAmount > 0 && allocations.isNotEmpty ? _applyAllocation : null,
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Terapkan Alokasi', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyAllocation() async {
    final inputAmount = RupiahInputFormatter.parse(_amountController.text);
    if (inputAmount <= 0) return;

    final allocations = AutoAllocationEngine.calculateAllocation(
      depositAmount: inputAmount,
      activeGoals: widget.activeGoals,
      strategy: _strategy,
    );

    final savingsProvider = context.read<SavingsProvider>();
    final txProvider = Provider.of<TransactionProvider?>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider?>(context, listen: false);

    for (final alloc in allocations) {
      if (alloc.allocatedAmount > 0) {
        await savingsProvider.addAmountToGoal(alloc.goalId, alloc.allocatedAmount);
      }
    }

    if (_syncWallet && _selectedWalletId != null && txProvider != null) {
      await txProvider.addTransaction(
        TransactionModel(
          title: 'Alokasi Multi-Tabungan',
          amount: inputAmount,
          type: TransactionType.expense,
          category: TransactionCategory.other,
          walletId: _selectedWalletId,
          date: DateTime.now(),
          note: 'Distribusi otomatis ke ${allocations.length} target tabungan',
        ),
      );
      await walletProvider?.refreshBalances();
    }

    if (mounted) {
      Navigator.pop(context);
    }
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
