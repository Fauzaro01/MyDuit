import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../models/wallet_model.dart';
import '../models/transfer_model.dart';
import '../providers/wallet_provider.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _adminFeeController = TextEditingController();
  final _noteController = TextEditingController();

  WalletModel? _fromWallet;
  WalletModel? _toWallet;
  DateTime _date = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wallets = context.read<WalletProvider>().wallets;
      if (wallets.length >= 2) {
        setState(() {
          _fromWallet = wallets[0];
          _toWallet = wallets[1];
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _adminFeeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Scaffold(
      appBar: AppBar(title: const Text('Transfer Antar Dompet')),
      body: walletProvider.wallets.length < 2
          ? const Center(
              child: EmptyState(
                message:
                    'Dibutuhkan minimal 2 dompet untuk melakukan transfer.\nSilakan tambah dompet baru terlebih dahulu.',
                icon: Icons.account_balance_wallet_outlined,
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  20 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
            // Transfer visualization
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _WalletSelector(
                      label: 'Dari',
                      wallet: _fromWallet,
                      wallets: walletProvider.wallets,
                      balance: _fromWallet != null
                          ? walletProvider.walletBalances[_fromWallet!.id] ??
                                0.0
                          : 0.0,
                      isDark: isDark,
                      onChanged: (w) {
                        setState(() {
                          _fromWallet = w;
                          if (_toWallet?.id == w?.id) _toWallet = null;
                        });
                      },
                      excludeId: _toWallet?.id,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: primary,
                        size: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _WalletSelector(
                      label: 'Ke',
                      wallet: _toWallet,
                      wallets: walletProvider.wallets,
                      balance: _toWallet != null
                          ? walletProvider.walletBalances[_toWallet!.id] ?? 0.0
                          : 0.0,
                      isDark: isDark,
                      onChanged: (w) {
                        setState(() {
                          _toWallet = w;
                          if (_fromWallet?.id == w?.id) {
                            _fromWallet = null;
                          }
                        });
                      },
                      excludeId: _fromWallet?.id,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, end: 0),
            const SizedBox(height: 24),

            // Swap button
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    final temp = _fromWallet;
                    _fromWallet = _toWallet;
                    _toWallet = temp;
                  });
                },
                icon: const Icon(Icons.swap_vert_rounded),
                label: const Text('Tukar'),
              ),
            ),
            const SizedBox(height: 16),

            // Amount
            Text('Jumlah Transfer', style: theme.textTheme.labelLarge),
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
                color: primary,
              ),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: primary,
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

            // Admin Fee (Optional)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Biaya Admin (opsional)', style: theme.textTheme.labelLarge),
                Row(
                  children: [
                    _buildAdminFeeChip(2500, 'BI-Fast (2.5k)', isDark),
                    const SizedBox(width: 6),
                    _buildAdminFeeChip(6500, 'Online (6.5k)', isDark),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _adminFeeController,
              keyboardType: TextInputType.number,
              inputFormatters: CurrencyInputService.isFormatted
                  ? [RupiahInputFormatter()]
                  : [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                hintText: '0 (Gratis)',
              ),
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
                      color: primary,
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
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Contoh: Pindah dana ke tabungan',
              ),
            ),
            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.swap_horiz_rounded),
                label: Text(_isSubmitting ? 'Memproses...' : 'Transfer Sekarang'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminFeeChip(double fee, String label, bool isDark) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _adminFeeController.text = CurrencyInputService.isFormatted
              ? RupiahInputFormatter.formatNumber(fee)
              : fee.toStringAsFixed(0);
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardAltDark : AppColors.cardAltLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    if (_fromWallet == null || _toWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pilih dompet asal dan tujuan'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (_fromWallet!.id == _toWallet!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Dompet asal dan tujuan harus berbeda'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final amount = RupiahInputFormatter.parse(_amountController.text);
      final adminFee = _adminFeeController.text.trim().isNotEmpty
          ? RupiahInputFormatter.parse(_adminFeeController.text)
          : 0.0;
      final transfer = TransferModel(
        fromWalletId: _fromWallet!.id,
        toWalletId: _toWallet!.id,
        amount: amount,
        adminFee: adminFee,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        date: _date,
      );

      await context.read<WalletProvider>().transferBetweenWallets(transfer);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Transfer ${CurrencyFormatter.format(amount)} berhasil!',
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: AppColors.income,
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _WalletSelector extends StatelessWidget {
  final String label;
  final WalletModel? wallet;
  final List<WalletModel> wallets;
  final double balance;
  final bool isDark;
  final ValueChanged<WalletModel?> onChanged;
  final String? excludeId;

  const _WalletSelector({
    required this.label,
    required this.wallet,
    required this.wallets,
    required this.balance,
    required this.isDark,
    required this.onChanged,
    this.excludeId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableWallets = wallets.where((w) => w.id != excludeId).toList();

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih Dompet ($label)',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ...availableWallets.map((w) {
                    final isSelected = w.id == wallet?.id;
                    return ListTile(
                      leading: Text(
                        w.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(w.name),
                      subtitle: Text(
                        CurrencyFormatter.formatCompact(
                          context.read<WalletProvider>().walletBalances[w.id] ??
                              0.0,
                        ),
                      ),
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
                        onChanged(w);
                        Navigator.pop(context);
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 8),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: wallet != null
                  ? Color(wallet!.colorValue).withValues(alpha: 0.15)
                  : (isDark ? AppColors.cardAltDark : AppColors.cardAltLight),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: wallet != null
                ? Text(wallet!.emoji, style: const TextStyle(fontSize: 28))
                : Icon(
                    Icons.add_rounded,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            wallet?.name ?? 'Pilih',
            style: theme.textTheme.titleMedium?.copyWith(fontSize: 13),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (wallet != null)
            Text(
              CurrencyFormatter.formatCompact(balance),
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
            ),
        ],
      ),
    );
  }
}
