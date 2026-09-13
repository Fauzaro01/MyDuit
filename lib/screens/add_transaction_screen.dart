import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/transaction_model.dart';
import '../models/transaction_template_model.dart';
import '../models/wallet_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/custom_category_provider.dart';
import '../providers/tag_provider.dart';
import '../providers/template_provider.dart';
import '../services/receipt_parser_service.dart';
import '../services/auto_categorize_service.dart';
import '../utils/formatters.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;
  final TransactionTemplateModel? template;
  final bool initialIsIncome;

  const AddTransactionScreen({
    super.key,
    this.transaction,
    this.template,
    this.initialIsIncome = true,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _tagInputController = TextEditingController();

  late TransactionType _type;
  late TransactionCategory _category;
  String? _customCategoryId;
  late DateTime _date;
  bool _isEditing = false;
  WalletModel? _selectedWallet;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _isEditing = true;
      final tx = widget.transaction!;
      _titleController.text = tx.title;
      _amountController.text = CurrencyInputService.isFormatted
          ? RupiahInputFormatter.formatNumber(tx.amount)
          : tx.amount.toStringAsFixed(0);
      _noteController.text = tx.note ?? '';
      _type = tx.type;
      _category = tx.category;
      _customCategoryId = tx.customCategoryId;
      _date = tx.date;
      _tags = List<String>.from(tx.tags);
    } else if (widget.template != null) {
      final tpl = widget.template!;
      _titleController.text = tpl.title;
      _amountController.text = CurrencyInputService.isFormatted
          ? RupiahInputFormatter.formatNumber(tpl.amount)
          : tpl.amount.toStringAsFixed(0);
      _noteController.text = tpl.note ?? '';
      _type = tpl.type;
      _category = tpl.category;
      _customCategoryId = tpl.customCategoryId;
      _date = DateTime.now();
      _tags = List<String>.from(tpl.tags);
    } else {
      _type = widget.initialIsIncome
          ? TransactionType.income
          : TransactionType.expense;
      _category = widget.initialIsIncome
          ? TransactionCategory.salary
          : TransactionCategory.food;
      _customCategoryId = null;
      _date = DateTime.now();
      _tags = [];
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletProvider = context.read<WalletProvider>();
      setState(() {
        if (_isEditing && widget.transaction!.walletId != null) {
          _selectedWallet = walletProvider.getWalletById(
            widget.transaction!.walletId!,
          );
        } else if (widget.template?.walletId != null) {
          _selectedWallet = walletProvider.getWalletById(
            widget.template!.walletId!,
          );
        }
        _selectedWallet ??=
            walletProvider.activeWallet ??
            (walletProvider.wallets.isNotEmpty
                ? walletProvider.wallets.first
                : null);
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _onTitleChanged(String value) {
    if (_isEditing) return;
    final suggestion = AutoCategorizeService.suggest(value);
    if (suggestion != null) {
      setState(() {
        _type = suggestion.type;
        _category = suggestion.category;
        _customCategoryId = null;
      });
    }
  }

  List<TransactionCategory> get _availableCategories {
    if (_type == TransactionType.income) {
      return TransactionCategory.values
          .where((c) => c.isIncomeCategory)
          .toList();
    }
    return TransactionCategory.values
        .where((c) => !c.isIncomeCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isIncome = _type == TransactionType.income;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaksi' : 'Tambah Transaksi'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner_rounded),
            tooltip: 'Scan / Tempel Teks Struk',
            onPressed: () => _showReceiptScanSheet(context, isDark),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.paddingOf(context).bottom + 24,
          ),
          children: [
            // Type toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardAltLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TypeTab(
                      label: 'Pemasukan',
                      isSelected: isIncome,
                      color: AppColors.income,
                      isDark: isDark,
                      onTap: () {
                        setState(() {
                          _type = TransactionType.income;
                          _category = TransactionCategory.salary;
                          _customCategoryId = null;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: _TypeTab(
                      label: 'Pengeluaran',
                      isSelected: !isIncome,
                      color: AppColors.expense,
                      isDark: isDark,
                      onTap: () {
                        setState(() {
                          _type = TransactionType.expense;
                          _category = TransactionCategory.food;
                          _customCategoryId = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (!_isEditing) ...[
              const SizedBox(height: 16),
              _buildTemplateBar(context, isDark),
            ],
            const SizedBox(height: 24),

            // Amount field
            Text('Jumlah', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: CurrencyInputService.isFormatted
                  ? [RupiahInputFormatter()]
                  : [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: isIncome ? AppColors.income : AppColors.expense,
              ),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: isIncome ? AppColors.income : AppColors.expense,
                ),
                hintText: '0',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Masukkan jumlah';
                }
                if (RupiahInputFormatter.parse(value) <= 0) {
                  return 'Jumlah harus lebih dari 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Title
            Text('Judul', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              onChanged: _onTitleChanged,
              decoration: const InputDecoration(
                hintText: 'Contoh: Gaji Bulanan',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Masukkan judul transaksi';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Category
            Text('Kategori', style: theme.textTheme.labelLarge),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final customCategoryProvider =
                    Provider.of<CustomCategoryProvider?>(context);
                final customCats = customCategoryProvider != null
                    ? (isIncome
                        ? customCategoryProvider.incomeCategories
                        : customCategoryProvider.expenseCategories)
                    : const [];
                final accentColor = isIncome
                    ? AppColors.income
                    : AppColors.expense;

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._availableCategories.map((cat) {
                      final selected =
                          cat == _category && _customCategoryId == null;

                      return GestureDetector(
                        onTap: () => setState(() {
                          _category = cat;
                          _customCategoryId = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? accentColor.withValues(alpha: 0.15)
                                : (isDark
                                      ? AppColors.cardDark
                                      : AppColors.cardAltLight),
                            borderRadius: BorderRadius.circular(12),
                            border: selected
                                ? Border.all(color: accentColor, width: 1.5)
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(cat.icon, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 6),
                              Text(
                                cat.label,
                                style: TextStyle(
                                  color: selected
                                      ? accentColor
                                      : theme.textTheme.bodyMedium?.color,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    ...customCats.map((customCat) {
                      final selected = _customCategoryId == customCat.id;

                      return GestureDetector(
                        onTap: () => setState(() {
                          _category = TransactionCategory.other;
                          _customCategoryId = customCat.id;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? accentColor.withValues(alpha: 0.15)
                                : (isDark
                                      ? AppColors.cardDark
                                      : AppColors.cardAltLight),
                            borderRadius: BorderRadius.circular(12),
                            border: selected
                                ? Border.all(color: accentColor, width: 1.5)
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                customCat.emoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                customCat.name,
                                style: TextStyle(
                                  color: selected
                                      ? accentColor
                                      : theme.textTheme.bodyMedium?.color,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Wallet selector
            Text('Dompet', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            _buildWalletSelector(context, isDark),
            const SizedBox(height: 20),

            // Date
            Text('Tanggal', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.cardAltDark
                      : AppColors.cardAltLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormatter.fullDate(_date),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tag / Project label
            Text('Tag & Label (#Proyek/Tag)', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            _buildTagSection(context, isDark),
            const SizedBox(height: 20),

            // Note
            Text('Catatan (opsional)', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Tambahkan catatan...',
              ),
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submit,
                child: Text(
                  _isEditing ? 'Simpan Perubahan' : 'Tambah Transaksi',
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSelector(BuildContext context, bool isDark) {
    final walletProvider = context.watch<WalletProvider>();
    final wallets = walletProvider.wallets;

    if (wallets.isEmpty) return const SizedBox.shrink();

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pilih Dompet', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                ...wallets.map((w) {
                  final isSelected = w.id == _selectedWallet?.id;
                  return ListTile(
                    leading: Text(
                      w.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(w.name),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: Color(w.colorValue),
                          )
                        : null,
                    selected: isSelected,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      setState(() => _selectedWallet = w);
                      Navigator.pop(ctx);
                    },
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardAltDark : AppColors.cardAltLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (_selectedWallet != null) ...[
              Text(
                _selectedWallet!.emoji,
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedWallet!.name,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ] else ...[
              Icon(
                Icons.account_balance_wallet_rounded,
                size: 22,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pilih dompet',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
            Icon(
              Icons.chevron_right_rounded,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _showReceiptScanSheet(BuildContext context, bool isDark) {
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.document_scanner_rounded,
                  color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                ),
                const SizedBox(width: 8),
                Text(
                  'Smart Receipt Parser',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tempel atau ketik teks dari struk belanja (Indomaret, Alfamart, Starbucks, SPBU, dll). Sistem akan mengekstrak merchant, nominal, tanggal, dan kategori secara instan.',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Contoh:\nINDOMARET KEMANG\n12/09/2026\nSusu UHT 20.000\nTotal Rp 45.000',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                  label: const Text('Ekstrak & Terapkan'),
                  onPressed: () {
                    final raw = textController.text;
                    if (raw.trim().isEmpty) return;

                    final parsed = ReceiptParserService.parse(raw);
                    setState(() {
                      if (parsed.merchantName != null &&
                          parsed.merchantName!.isNotEmpty) {
                        _titleController.text = parsed.merchantName!;
                      }
                      if (parsed.totalAmount != null &&
                          parsed.totalAmount! > 0) {
                        _amountController.text = CurrencyInputService.isFormatted
                            ? RupiahInputFormatter.formatNumber(
                                parsed.totalAmount!,
                              )
                            : parsed.totalAmount!.toStringAsFixed(0);
                      }
                      if (parsed.date != null) {
                        _date = parsed.date!;
                      }
                      _type = parsed.suggestedType;
                      _category = parsed.suggestedCategory;
                      if (parsed.lineItems.isNotEmpty) {
                        _noteController.text = parsed.lineItems.join('\n');
                      }
                    });

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Struk berhasil diproses: ${parsed.merchantName ?? "Transaksi"} (${CurrencyFormatter.format(parsed.totalAmount ?? 0)})',
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagSection(BuildContext context, bool isDark) {
    final tagProvider = Provider.of<TagProvider?>(context);
    final popularTags = tagProvider?.tags.map((t) => t.name).toList() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected tags chips
        if (_tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Chip(
                label: Text('#$tag', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
                onDeleted: () => setState(() => _tags.remove(tag)),
                backgroundColor: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                    .withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              );
            }).toList(),
          ),
        if (_tags.isNotEmpty) const SizedBox(height: 8),

        // Tag text input + add button
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagInputController,
                decoration: const InputDecoration(
                  hintText: 'Tambah tag (contoh: Liburan, ProyekA)',
                  prefixText: '#',
                  isDense: true,
                ),
                onSubmitted: (val) => _addTag(val),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _addTag(_tagInputController.text),
            ),
          ],
        ),

        // Popular tag suggestions
        if (popularTags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: popularTags.where((t) => !_tags.contains(t)).map((tag) {
              return ActionChip(
                label: Text('#$tag', style: const TextStyle(fontSize: 11)),
                onPressed: () => _addTag(tag),
                padding: EdgeInsets.zero,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildTemplateBar(BuildContext context, bool isDark) {
    final templateProvider = Provider.of<TemplateProvider?>(context);
    final templates = templateProvider?.templates ?? [];
    if (templates.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.bolt_rounded,
              size: 16,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            ),
            const SizedBox(width: 6),
            Text(
              'Template Cepat',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: templates.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final tpl = templates[index];
              return ActionChip(
                avatar: Text(tpl.emoji, style: const TextStyle(fontSize: 14)),
                label: Text(
                  '${tpl.name} · ${CurrencyFormatter.format(tpl.amount)}',
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: isDark ? AppColors.cardAltDark : AppColors.cardAltLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: () => _applyTemplate(tpl),
              );
            },
          ),
        ),
      ],
    );
  }

  void _applyTemplate(TransactionTemplateModel tpl) {
    HapticFeedback.selectionClick();
    setState(() {
      _titleController.text = tpl.title;
      _amountController.text = CurrencyInputService.isFormatted
          ? RupiahInputFormatter.formatNumber(tpl.amount)
          : tpl.amount.toStringAsFixed(0);
      _noteController.text = tpl.note ?? '';
      _type = tpl.type;
      _category = tpl.category;
      _customCategoryId = tpl.customCategoryId;
      _tags = List<String>.from(tpl.tags);
      if (tpl.walletId != null) {
        final walletProvider = context.read<WalletProvider>();
        final w = walletProvider.getWalletById(tpl.walletId!);
        if (w != null) _selectedWallet = w;
      }
    });
  }

  void _addTag(String tag) {
    final clean = tag.replaceAll('#', '').trim();
    if (clean.isNotEmpty && !_tags.contains(clean)) {
      HapticFeedback.lightImpact();
      setState(() {
        _tags.add(clean);
        _tagInputController.clear();
      });
      context.read<TagProvider?>()?.addTag(clean);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();

    final provider = context.read<TransactionProvider>();
    final transaction = TransactionModel(
      id: _isEditing ? widget.transaction!.id : null,
      title: _titleController.text.trim(),
      amount: RupiahInputFormatter.parse(_amountController.text),
      type: _type,
      category: _category,
      date: _date,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      walletId: _selectedWallet?.id,
      customCategoryId: _customCategoryId,
      tags: _tags,
    );

    if (_isEditing) {
      provider.updateTransaction(transaction);
    } else {
      provider.addTransaction(transaction);
    }

    Navigator.pop(context);
  }
}

class _TypeTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _TypeTab({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.cardAltDark : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? color
                : (isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
