import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/transaction_model.dart';
import '../models/transaction_template_model.dart';
import '../providers/custom_category_provider.dart';
import '../providers/template_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/formatters.dart';
import '../widgets/emoji_picker_sheet.dart';

class QuickTemplatesScreen extends StatelessWidget {
  const QuickTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final templateProvider = context.watch<TemplateProvider>();
    final templates = templateProvider.templates;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atur Catat Cepat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore_rounded),
            tooltip: 'Pulihkan Template Bawaan',
            onPressed: () => _confirmResetDefaults(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTemplateEditor(context, isDark: isDark),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Pintasan'),
      ),
      body: templateProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : templates.isEmpty
              ? _buildEmptyState(context, isDark)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 88),
                  itemCount: templates.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final tpl = templates[index];
                    return _TemplateCard(
                      template: tpl,
                      isDark: isDark,
                      onEdit: () => _showTemplateEditor(
                        context,
                        isDark: isDark,
                        template: tpl,
                      ),
                      onDelete: () => _confirmDeleteTemplate(context, tpl),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bolt_rounded,
              size: 64,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada pintasan Catat Cepat',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Buat template untuk mencatat transaksi harian seperti kopi, bensin, atau makan siang hanya dalam satu ketukan.',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _confirmResetDefaults(context),
                  icon: const Icon(Icons.restore_rounded, size: 18),
                  label: const Text('Muat Bawaan'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showTemplateEditor(context, isDark: isDark),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Buat Baru'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTemplate(
    BuildContext context,
    TransactionTemplateModel tpl,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hapus Pintasan?'),
        content: Text(
          'Apakah kamu yakin ingin menghapus "${tpl.name}" (${CurrencyFormatter.format(tpl.amount)}) dari Catat Cepat?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<TemplateProvider>().deleteTemplate(tpl.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Pintasan "${tpl.name}" dihapus')),
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _confirmResetDefaults(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Pulihkan Template Bawaan?'),
        content: const Text(
          'Ini akan menambahkan kembali set pintasan bawaan (Kopi, Makan Siang, Bensin, Parkir) ke Catat Cepat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final provider = context.read<TemplateProvider>();
              for (final def in TransactionTemplateModel.defaultTemplates) {
                if (!provider.templates.any((t) => t.id == def.id)) {
                  await provider.addTemplate(def);
                }
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Template bawaan berhasil dipulihkan')),
                );
              }
            },
            child: const Text('Pulihkan'),
          ),
        ],
      ),
    );
  }

  void _showTemplateEditor(
    BuildContext context, {
    required bool isDark,
    TransactionTemplateModel? template,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _TemplateEditorSheet(template: template, isDark: isDark),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final TransactionTemplateModel template;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TemplateCard({
    required this.template,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final customCatProvider = context.watch<CustomCategoryProvider>();

    final wallet = template.walletId != null
        ? walletProvider.getWalletById(template.walletId!)
        : null;

    final isExpense = template.type == TransactionType.expense;

    String categoryName = template.category.label;
    if (template.customCategoryId != null) {
      final custom = customCatProvider.getCategoryById(template.customCategoryId!);
      if (custom != null) {
        categoryName = '${custom.emoji} ${custom.name}';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardAltDark : AppColors.cardAltLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  template.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      template.title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '${isExpense ? '-' : '+'} ${CurrencyFormatter.format(template.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isExpense ? AppColors.expense : AppColors.income,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isExpense ? AppColors.expense : AppColors.income)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isExpense ? 'Pengeluaran' : 'Pemasukan',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isExpense ? AppColors.expense : AppColors.income,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardAltDark : AppColors.cardAltLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  categoryName,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ),
              if (wallet != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardAltDark : AppColors.cardAltLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        wallet.name,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                visualDensity: VisualDensity.compact,
                tooltip: 'Edit',
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                visualDensity: VisualDensity.compact,
                color: AppColors.expense,
                tooltip: 'Hapus',
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TemplateEditorSheet extends StatefulWidget {
  final TransactionTemplateModel? template;
  final bool isDark;

  const _TemplateEditorSheet({
    this.template,
    required this.isDark,
  });

  @override
  State<_TemplateEditorSheet> createState() => _TemplateEditorSheetState();
}

class _TemplateEditorSheetState extends State<_TemplateEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  late String _emoji;
  late TransactionType _type;
  late TransactionCategory _category;
  String? _customCategoryId;
  String? _walletId;

  @override
  void initState() {
    super.initState();
    final tpl = widget.template;
    _nameController = TextEditingController(text: tpl?.name ?? '');
    _titleController = TextEditingController(text: tpl?.title ?? '');
    _amountController = TextEditingController(
      text: tpl != null
          ? (CurrencyInputService.isFormatted
              ? RupiahInputFormatter.formatNumber(tpl.amount)
              : tpl.amount.toStringAsFixed(0))
          : '',
    );
    _noteController = TextEditingController(text: tpl?.note ?? '');
    _emoji = tpl?.emoji ?? '⚡';
    _type = tpl?.type ?? TransactionType.expense;
    _category = tpl?.category ?? TransactionCategory.food;
    _customCategoryId = tpl?.customCategoryId;
    _walletId = tpl?.walletId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isEditing = widget.template != null;
    final walletProvider = context.watch<WalletProvider>();
    final customCatProvider = context.watch<CustomCategoryProvider>();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Pintasan' : 'Pintasan Baru',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Emoji & Nama Cepat
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final selected = await EmojiPickerSheet.show(
                        context,
                        initialEmoji: _emoji,
                      );
                      if (selected != null) {
                        setState(() => _emoji = selected);
                      }
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardAltDark : AppColors.cardAltLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(_emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Label Singkat *',
                        hintText: 'Misal: Kopi Pagi',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Label wajib diisi';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Judul Transaksi Riil
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Transaksi Lengkap *',
                  hintText: 'Misal: Beli Kopi Susu Aren',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Judul transaksi wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Nominal
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: CurrencyInputService.isFormatted
                    ? [RupiahInputFormatter()]
                    : [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Nominal *',
                  prefixText: 'Rp ',
                  prefixStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _type == TransactionType.expense
                        ? AppColors.expense
                        : AppColors.income,
                  ),
                ),
                validator: (val) {
                  final amount = RupiahInputFormatter.parse(val ?? '');
                  if (amount <= 0) return 'Nominal harus lebih dari 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tipe: Pemasukan / Pengeluaran
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Pengeluaran')),
                      selected: _type == TransactionType.expense,
                      selectedColor: AppColors.expense.withValues(alpha: 0.18),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _type == TransactionType.expense
                            ? AppColors.expense
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _type = TransactionType.expense;
                            _category = TransactionCategory.food;
                            _customCategoryId = null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Pemasukan')),
                      selected: _type == TransactionType.income,
                      selectedColor: AppColors.income.withValues(alpha: 0.18),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _type == TransactionType.income
                            ? AppColors.income
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _type = TransactionType.income;
                            _category = TransactionCategory.salary;
                            _customCategoryId = null;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Kategori
              DropdownButtonFormField<String>(
                value: _customCategoryId != null
                    ? 'custom:$_customCategoryId'
                    : 'std:${_category.name}',
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: [
                  ...TransactionCategory.values
                      .where((c) => _type == TransactionType.income ? c.isIncomeCategory : !c.isIncomeCategory)
                      .map((cat) => DropdownMenuItem(
                            value: 'std:${cat.name}',
                            child: Text(cat.label),
                          )),
                  ...customCatProvider.categories
                      .where((c) =>
                          (_type == TransactionType.income && c.isIncome) ||
                          (_type == TransactionType.expense && !c.isIncome))
                      .map((cat) => DropdownMenuItem(
                            value: 'custom:${cat.id}',
                            child: Text('${cat.emoji} ${cat.name}'),
                          )),
                ],
                onChanged: (val) {
                  if (val == null) return;
                  if (val.startsWith('custom:')) {
                    setState(() {
                      _customCategoryId = val.substring(7);
                    });
                  } else {
                    final catName = val.substring(4);
                    setState(() {
                      _customCategoryId = null;
                      _category = TransactionCategory.values.firstWhere(
                        (c) => c.name == catName,
                        orElse: () => _category,
                      );
                    });
                  }
                },
              ),
              const SizedBox(height: 14),

              // Dompet (Opsional)
              DropdownButtonFormField<String?>(
                value: _walletId,
                decoration: const InputDecoration(
                  labelText: 'Dompet Tertaut (Opsional)',
                  helperText: 'Kosongkan jika ingin pakai dompet aktif saat mencatat',
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Gunakan Dompet Aktif'),
                  ),
                  ...walletProvider.wallets.map((w) => DropdownMenuItem(
                        value: w.id,
                        child: Text('${w.name} (${w.currencyCode})'),
                      )),
                ],
                onChanged: (val) => setState(() => _walletId = val),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saveTemplate,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(isEditing ? 'Simpan Perubahan' : 'Buat Pintasan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveTemplate() {
    if (!_formKey.currentState!.validate()) return;

    final amount = RupiahInputFormatter.parse(_amountController.text);
    final provider = context.read<TemplateProvider>();

    if (widget.template != null) {
      final updated = widget.template!.copyWith(
        name: _nameController.text.trim(),
        title: _titleController.text.trim(),
        amount: amount,
        type: _type,
        category: _category,
        customCategoryId: _customCategoryId,
        walletId: _walletId,
        emoji: _emoji,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      provider.updateTemplate(updated);
    } else {
      final newTpl = TransactionTemplateModel(
        name: _nameController.text.trim(),
        title: _titleController.text.trim(),
        amount: amount,
        type: _type,
        category: _category,
        customCategoryId: _customCategoryId,
        walletId: _walletId,
        emoji: _emoji,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      provider.addTemplate(newTpl);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.template != null
              ? 'Pintasan berhasil diperbarui'
              : 'Pintasan baru berhasil dibuat',
        ),
      ),
    );
  }
}
