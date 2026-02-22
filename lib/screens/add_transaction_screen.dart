import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../utils/formatters.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;
  final bool initialIsIncome;

  const AddTransactionScreen({
    super.key,
    this.transaction,
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

  late TransactionType _type;
  late TransactionCategory _category;
  late DateTime _date;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _isEditing = true;
      final tx = widget.transaction!;
      _titleController.text = tx.title;
      _amountController.text = tx.amount.toStringAsFixed(0);
      _noteController.text = tx.note ?? '';
      _type = tx.type;
      _category = tx.category;
      _date = tx.date;
    } else {
      _type = widget.initialIsIncome
          ? TransactionType.income
          : TransactionType.expense;
      _category = widget.initialIsIncome
          ? TransactionCategory.salary
          : TransactionCategory.food;
      _date = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
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
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
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
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Amount field
            Text('Jumlah', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                if (double.tryParse(value) == null ||
                    double.parse(value) <= 0) {
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableCategories.map((cat) {
                final selected = cat == _category;
                final accentColor = isIncome
                    ? AppColors.income
                    : AppColors.expense;

                return GestureDetector(
                  onTap: () => setState(() => _category = cat),
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
              }).toList(),
            ),
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<TransactionProvider>();
    final transaction = TransactionModel(
      id: _isEditing ? widget.transaction!.id : null,
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text),
      type: _type,
      category: _category,
      date: _date,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
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
