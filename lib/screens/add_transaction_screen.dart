import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/receipt_data.dart';
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
  final bool isDuplicate;

  const AddTransactionScreen({
    super.key,
    this.transaction,
    this.template,
    this.initialIsIncome = true,
    this.isDuplicate = false,
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
      _isEditing = !widget.isDuplicate;
      final tx = widget.transaction!;
      _titleController.text = tx.title;
      _amountController.text = CurrencyInputService.isFormatted
          ? RupiahInputFormatter.formatNumber(tx.amount)
          : tx.amount.toStringAsFixed(0);
      _noteController.text = tx.note ?? '';
      _type = tx.type;
      _category = tx.category;
      _customCategoryId = tx.customCategoryId;
      _date = widget.isDuplicate ? DateTime.now() : tx.date;
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Jumlah', style: theme.textTheme.labelLarge),
                IconButton(
                  icon: const Icon(Icons.calculate_rounded, size: 20),
                  tooltip: 'Kalkulator Cepat',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showMiniCalculator(context, isDark),
                ),
              ],
            ),
            const SizedBox(height: 4),
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
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.percent_rounded, size: 20),
                      tooltip: 'Hitung Pajak & Layanan',
                      onPressed: () => _showTaxTipSheet(context, isDark),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calculate_outlined),
                      tooltip: 'Kalkulator',
                      onPressed: () => _showMiniCalculator(context, isDark),
                    ),
                  ],
                ),
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
            const SizedBox(height: 8),

            // Quick Preset Chips (+50k, +100k, +500k, +1M)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickPresetChip(50000, '+50rb', isDark),
                  const SizedBox(width: 8),
                  _buildQuickPresetChip(100000, '+100rb', isDark),
                  const SizedBox(width: 8),
                  _buildQuickPresetChip(500000, '+500rb', isDark),
                  const SizedBox(width: 8),
                  _buildQuickPresetChip(1000000, '+1jt', isDark),
                ],
              ),
            ),
            if (!isIncome && RupiahInputFormatter.parse(_amountController.text) >= 1000000) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFF59E0B)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Peringatan Pengeluaran Besar (≥ Rp 1.000.000)',
                        style: TextStyle(fontSize: 11, color: Color(0xFFF59E0B), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
            Builder(
              builder: (context) {
                final txProvider = Provider.of<TransactionProvider?>(context);
                if (txProvider == null || txProvider.transactions.isEmpty) {
                  return const SizedBox.shrink();
                }
                final query = _titleController.text.trim().toLowerCase();
                final suggestions = txProvider.transactions
                    .where((t) => t.type == _type)
                    .map((t) => t.title.trim())
                    .where((t) =>
                        t.isNotEmpty &&
                        (query.isEmpty ||
                            (t.toLowerCase().contains(query) &&
                                t.toLowerCase() != query)))
                    .toSet()
                    .take(5)
                    .toList();

                if (suggestions.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.history_rounded,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        ...suggestions.map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(
                                s,
                                style: const TextStyle(fontSize: 11),
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                _titleController.text = s;
                                _onTitleChanged(s);
                                setState(() {});
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
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
              onChanged: (_) => setState(() {}),
            ),
            Builder(
              builder: (context) {
                final txProvider = Provider.of<TransactionProvider?>(context);
                final recentNotes = (txProvider?.transactions ?? [])
                    .map((t) => t.note?.trim())
                    .where((n) => n != null && n.isNotEmpty)
                    .cast<String>()
                    .toSet()
                    .take(6)
                    .toList();

                if (recentNotes.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: recentNotes.map((note) {
                      return ActionChip(
                        label: Text(
                          note,
                          style: const TextStyle(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _noteController.text = note;
                          });
                        },
                      );
                    }).toList(),
                  ),
                );
              },
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
      final now = DateTime.now();
      final adjusted = DateTime(
        picked.year,
        picked.month,
        picked.day,
        now.hour,
        now.minute,
        now.second,
      );
      setState(() => _date = adjusted);
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
              'Tempel teks struk belanja (Indomaret, Alfamart, Starbucks, SPBU, resto, tagihan, dll). Mesin on-device akan mengekstrak merchant, nominal, rincian barang, pajak, diskon, dan metode pembayaran.',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Contoh:\nINDOMARET KEMANG\n12/09/2026\n2x Susu UHT Rp 14.000\n1x Roti Tawar 15.000\nDiskon Member 2.000\nPPN 11% 2.970\nTotal Rp 29.970\nTunai Rp 50.000',
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
                  label: const Text('Ekstrak & Periksa'),
                  onPressed: () {
                    final raw = textController.text;
                    if (raw.trim().isEmpty) return;

                    final parsed = ReceiptParserService.parse(raw);
                    Navigator.pop(ctx);
                    _showReceiptPreviewSheet(context, parsed, isDark);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReceiptPreviewSheet(
    BuildContext context,
    ReceiptData parsed,
    bool isDark,
  ) {
    // Try auto-matching active wallet
    WalletModel? matchedWallet;
    if (parsed.detectedWalletKeyword != null) {
      final walletProvider = context.read<WalletProvider>();
      final keyword = parsed.detectedWalletKeyword!.toLowerCase();
      try {
        matchedWallet = walletProvider.wallets.firstWhere(
          (w) => w.name.toLowerCase().contains(keyword),
        );
      } catch (_) {
        matchedWallet = null;
      }
    }

    final confidencePercent = (parsed.confidenceScore * 100).toInt();
    final Color badgeColor;
    if (parsed.confidenceScore >= 0.8) {
      badgeColor = AppColors.income;
    } else if (parsed.confidenceScore >= 0.5) {
      badgeColor = Colors.orange;
    } else {
      badgeColor = AppColors.expense;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hasil Ekstraksi Struk',
                          style: Theme.of(ctx).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Verifikasi data sebelum diterapkan ke form',
                          style: Theme.of(ctx).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          parsed.confidenceScore >= 0.8
                              ? Icons.verified_rounded
                              : Icons.info_outline_rounded,
                          size: 14,
                          color: badgeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${parsed.confidenceLabel} ($confidencePercent%)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Summary Info
              _buildReceiptRow(
                ctx,
                'Merchant / Judul',
                parsed.merchantName ?? 'Tidak terdeteksi',
                Icons.storefront_rounded,
              ),
              _buildReceiptRow(
                ctx,
                'Total Transaksi',
                CurrencyFormatter.format(parsed.totalAmount ?? 0),
                Icons.payments_rounded,
                isHighlight: true,
              ),
              if (parsed.subtotalAmount != null)
                _buildReceiptRow(
                  ctx,
                  'Subtotal',
                  CurrencyFormatter.format(parsed.subtotalAmount!),
                  Icons.receipt_rounded,
                ),
              _buildReceiptRow(
                ctx,
                'Tanggal',
                DateFormatter.fullDate(parsed.date ?? DateTime.now()),
                Icons.calendar_today_rounded,
              ),
              _buildReceiptRow(
                ctx,
                'Kategori Disarankan',
                parsed.suggestedCategory.label,
                Icons.category_rounded,
              ),
              if (parsed.paymentMethod != null)
                _buildReceiptRow(
                  ctx,
                  'Metode Pembayaran',
                  '${parsed.paymentMethod} ${matchedWallet != null ? "→ Cocok dengan ${matchedWallet.name}" : ""}',
                  Icons.account_balance_wallet_rounded,
                ),

              // Items breakdown
              if (parsed.items.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Rincian Item (${parsed.items.length}):',
                  style: Theme.of(ctx).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardAltDark : AppColors.cardAltLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: parsed.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.qty > 1
                                    ? '${item.name} (${item.qty}x)'
                                    : item.name,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(item.totalPrice),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              // Taxes and Discounts
              if (parsed.discounts.isNotEmpty || parsed.taxes.isNotEmpty) ...[
                const SizedBox(height: 12),
                if (parsed.discounts.isNotEmpty) ...[
                  Text(
                    'Diskon & Promo:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.income),
                  ),
                  const SizedBox(height: 4),
                  ...parsed.discounts.map(
                    (d) => Text(
                      '• ${d.name} (-${CurrencyFormatter.format(d.amount)})',
                      style: TextStyle(fontSize: 12, color: AppColors.income),
                    ),
                  ),
                ],
                if (parsed.taxes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Pajak & Biaya:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  ...parsed.taxes.map(
                    (t) => Text(
                      '• ${t.name} (+${CurrencyFormatter.format(t.amount)})',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: const Text('Terapkan Data'),
                      onPressed: () {
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
                          if (matchedWallet != null) {
                            _selectedWallet = matchedWallet;
                          }

                          // Build itemized note
                          final noteBuffer = StringBuffer();
                          if (parsed.items.isNotEmpty) {
                            noteBuffer.writeln('Rincian Belanja:');
                            for (final itm in parsed.items) {
                              noteBuffer.writeln('• ${itm.toString()}');
                            }
                          }
                          if (parsed.discounts.isNotEmpty) {
                            noteBuffer.writeln('\nDiskon:');
                            for (final d in parsed.discounts) {
                              noteBuffer.writeln('• ${d.name}');
                            }
                          }
                          if (parsed.taxes.isNotEmpty) {
                            noteBuffer.writeln('\nPajak & Layanan:');
                            for (final t in parsed.taxes) {
                              noteBuffer.writeln('• ${t.name}');
                            }
                          }

                          if (noteBuffer.isNotEmpty) {
                            _noteController.text = noteBuffer.toString().trim();
                          }
                        });

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Struk berhasil diterapkan: ${parsed.merchantName ?? "Transaksi"} (${CurrencyFormatter.format(parsed.totalAmount ?? 0)})',
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isHighlight ? AppColors.primaryLight : Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                color: isHighlight ? AppColors.primaryLight : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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

  Widget _buildQuickPresetChip(double addAmount, String label, bool isDark) {
    return ActionChip(
      avatar: const Icon(Icons.add_rounded, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardAltLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      onPressed: () {
        HapticFeedback.selectionClick();
        final current = RupiahInputFormatter.parse(_amountController.text);
        final newTotal = current + addAmount;
        setState(() {
          _amountController.text = CurrencyInputService.isFormatted
              ? RupiahInputFormatter.formatNumber(newTotal)
              : newTotal.toStringAsFixed(0);
        });
      },
    );
  }

  void _showTaxTipSheet(BuildContext context, bool isDark) {
    HapticFeedback.lightImpact();
    final currentAmount = RupiahInputFormatter.parse(_amountController.text);
    if (currentAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal awal terlebih dahulu.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _TaxTipSheet(
        baseAmount: currentAmount,
        isDark: isDark,
        onApply: (finalAmount) {
          setState(() {
            _amountController.text = CurrencyInputService.isFormatted
                ? RupiahInputFormatter.formatNumber(finalAmount)
                : finalAmount.toStringAsFixed(0);
          });
        },
      ),
    );
  }

  void _showMiniCalculator(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _MiniCalcSheet(
        initialValue: RupiahInputFormatter.parse(_amountController.text),
        isDark: isDark,
        onResult: (result) {
          setState(() {
            _amountController.text = CurrencyInputService.isFormatted
                ? RupiahInputFormatter.formatNumber(result)
                : result.toStringAsFixed(0);
          });
        },
      ),
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

class _MiniCalcSheet extends StatefulWidget {
  final double initialValue;
  final bool isDark;
  final ValueChanged<double> onResult;

  const _MiniCalcSheet({
    required this.initialValue,
    required this.isDark,
    required this.onResult,
  });

  @override
  State<_MiniCalcSheet> createState() => _MiniCalcSheetState();
}

class _MiniCalcSheetState extends State<_MiniCalcSheet> {
  String _expression = '';
  String _display = '0';

  @override
  void initState() {
    super.initState();
    if (widget.initialValue > 0) {
      _display = widget.initialValue.toStringAsFixed(0);
      _expression = _display;
    }
  }

  void _onPress(String val) {
    HapticFeedback.selectionClick();
    setState(() {
      if (val == 'C') {
        _expression = '';
        _display = '0';
      } else if (val == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
          _display = _expression.isEmpty ? '0' : _expression;
        }
      } else if (val == '=') {
        _evaluate();
      } else if (['+', '-', '×', '÷'].contains(val)) {
        if (_expression.isNotEmpty && !['+', '-', '×', '÷'].contains(_expression[_expression.length - 1])) {
          _expression += val;
          _display = _expression;
        }
      } else if (val == '000') {
        if (_expression.isNotEmpty && _expression != '0') {
          _expression += '000';
          _display = _expression;
        }
      } else {
        if (_expression == '0') {
          _expression = val;
        } else {
          _expression += val;
        }
        _display = _expression;
      }
    });
  }

  void _evaluate() {
    try {
      final sanitized = _expression.replaceAll('×', '*').replaceAll('÷', '/');
      final result = _computeExpression(sanitized);
      if (result != null && result >= 0) {
        setState(() {
          _display = result % 1 == 0 ? result.toInt().toString() : result.toStringAsFixed(2);
          _expression = _display;
        });
      }
    } catch (_) {}
  }

  double? _computeExpression(String expr) {
    if (expr.isEmpty) return null;
    // Simple recursive/iterative parser for +, -, *, /
    final tokens = <String>[];
    String current = '';
    for (int i = 0; i < expr.length; i++) {
      final char = expr[i];
      if (['+', '-', '*', '/'].contains(char)) {
        if (current.isNotEmpty) {
          tokens.add(current);
          current = '';
        }
        tokens.add(char);
      } else {
        current += char;
      }
    }
    if (current.isNotEmpty) tokens.add(current);
    if (tokens.isEmpty) return null;

    // Stage 1: Multiply and Divide
    final stage1 = <String>[];
    int i = 0;
    while (i < tokens.length) {
      if (tokens[i] == '*' || tokens[i] == '/') {
        final op = tokens[i];
        final prev = double.tryParse(stage1.removeLast()) ?? 0;
        final next = (i + 1 < tokens.length) ? (double.tryParse(tokens[i + 1]) ?? 1) : 1;
        final res = op == '*' ? (prev * next) : (next != 0 ? prev / next : 0.0);
        stage1.add(res.toString());
        i += 2;
      } else {
        stage1.add(tokens[i]);
        i++;
      }
    }

    // Stage 2: Add and Subtract
    if (stage1.isEmpty) return null;
    double result = double.tryParse(stage1[0]) ?? 0;
    int j = 1;
    while (j < stage1.length) {
      final op = stage1[j];
      final next = (j + 1 < stage1.length) ? (double.tryParse(stage1[j + 1]) ?? 0) : 0;
      if (op == '+') result += next;
      if (op == '-') result -= next;
      j += 2;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = widget.isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calculate_rounded, color: accentColor),
                    const SizedBox(width: 8),
                    Text('Kalkulator Cepat', style: theme.textTheme.titleMedium),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    _evaluate();
                    final val = double.tryParse(_display) ?? 0;
                    widget.onResult(val);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Gunakan'),
                  style: TextButton.styleFrom(foregroundColor: accentColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: widget.isDark ? AppColors.cardAltDark : AppColors.cardAltLight,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              child: Text(
                _display.isEmpty ? '0' : _display,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildKeypad(accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad(Color accentColor) {
    final keys = [
      ['C', '⌫', '÷', '×'],
      ['7', '8', '9', '-'],
      ['4', '5', '6', '+'],
      ['1', '2', '3', '='],
      ['0', '000', '.', '='],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: row.map((key) {
              final isOp = ['+', '-', '×', '÷', '='].contains(key);
              final isSpecial = ['C', '⌫'].contains(key);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: isOp
                        ? accentColor.withValues(alpha: 0.18)
                        : (isSpecial
                            ? AppColors.expense.withValues(alpha: 0.12)
                            : (widget.isDark ? AppColors.cardAltDark : AppColors.surfaceLight)),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => _onPress(key),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 46,
                        alignment: Alignment.center,
                        child: Text(
                          key,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isOp
                                ? accentColor
                                : (isSpecial ? AppColors.expense : null),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _TaxTipSheet extends StatefulWidget {
  final double baseAmount;
  final bool isDark;
  final ValueChanged<double> onApply;

  const _TaxTipSheet({
    required this.baseAmount,
    required this.isDark,
    required this.onApply,
  });

  @override
  State<_TaxTipSheet> createState() => _TaxTipSheetState();
}

class _TaxTipSheetState extends State<_TaxTipSheet> {
  double _taxPercent = 11.0;
  double _servicePercent = 0.0;
  bool _includeTax = true;
  bool _includeService = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = widget.isDark ? AppColors.primaryDark : AppColors.primaryLight;

    final taxAmount = _includeTax ? (widget.baseAmount * (_taxPercent / 100.0)) : 0.0;
    final serviceAmount = _includeService ? (widget.baseAmount * (_servicePercent / 100.0)) : 0.0;
    final finalTotal = widget.baseAmount + taxAmount + serviceAmount;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.percent_rounded, color: accentColor),
                const SizedBox(width: 8),
                Text('Kalkulator Pajak & Layanan', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.isDark ? AppColors.cardAltDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nominal Awal:'),
                      Text(
                        CurrencyFormatter.format(widget.baseAmount),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (_includeTax) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('PPN (${_taxPercent.toInt()}%):'),
                        Text(
                          '+ ${CurrencyFormatter.format(taxAmount)}',
                          style: const TextStyle(color: AppColors.expense, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                  if (_includeService) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Service Charge (${_servicePercent.toInt()}%):'),
                        Text(
                          '+ ${CurrencyFormatter.format(serviceAmount)}',
                          style: const TextStyle(color: AppColors.expense, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Akhir:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        CurrencyFormatter.format(finalTotal),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tax presets
            Row(
              children: [
                Checkbox(
                  value: _includeTax,
                  activeColor: accentColor,
                  onChanged: (v) => setState(() => _includeTax = v ?? false),
                ),
                const Text('Pajak PPN: '),
                Wrap(
                  spacing: 6,
                  children: [10.0, 11.0, 12.0].map((rate) {
                    final selected = _includeTax && _taxPercent == rate;
                    return ChoiceChip(
                      label: Text('${rate.toInt()}%'),
                      selected: selected,
                      onSelected: (sel) {
                        if (sel) {
                          setState(() {
                            _includeTax = true;
                            _taxPercent = rate;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            // Service presets
            Row(
              children: [
                Checkbox(
                  value: _includeService,
                  activeColor: accentColor,
                  onChanged: (v) => setState(() => _includeService = v ?? false),
                ),
                const Text('Layanan: '),
                Wrap(
                  spacing: 6,
                  children: [5.0, 7.0, 10.0].map((rate) {
                    final selected = _includeService && _servicePercent == rate;
                    return ChoiceChip(
                      label: Text('${rate.toInt()}%'),
                      selected: selected,
                      onSelected: (sel) {
                        if (sel) {
                          setState(() {
                            _includeService = true;
                            _servicePercent = rate;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                icon: const Icon(Icons.check_rounded),
                label: const Text('Terapkan Nilai Total'),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onApply(finalTotal);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

