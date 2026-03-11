import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../models/savings_goal_model.dart';
import '../providers/savings_provider.dart';
import '../utils/formatters.dart';

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
      appBar: AppBar(title: const Text('Tujuan Tabungan')),
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

  void _showAddAmountSheet(BuildContext context, SavingsGoalModel goal) {
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
            Text('Tambah Tabungan', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '${goal.emoji} ${goal.title} · Sisa ${CurrencyFormatter.format(goal.remainingAmount)}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
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
              autofocus: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () {
                  final amount = RupiahInputFormatter.parse(controller.text);
                  if (amount > 0) {
                    context.read<SavingsProvider>().addAmountToGoal(
                      goal.id,
                      amount,
                    );
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
                  'Simpan',
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
