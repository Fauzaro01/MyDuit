import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/import_transaction_item.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/bank_statement_parser_service.dart';
import '../utils/formatters.dart';

class DataMigrationScreen extends StatefulWidget {
  const DataMigrationScreen({super.key});

  @override
  State<DataMigrationScreen> createState() => _DataMigrationScreenState();
}

class _DataMigrationScreenState extends State<DataMigrationScreen> {
  BankPreset _selectedPreset = BankPreset.universal;
  final _textController = TextEditingController();
  List<ImportTransactionItem> _parsedItems = [];
  WalletModel? _targetWallet;
  bool _isParsed = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletProvider = Provider.of<WalletProvider?>(context, listen: false);
      if (walletProvider != null && walletProvider.wallets.isNotEmpty) {
        setState(() {
          _targetWallet = walletProvider.activeWallet ?? walletProvider.wallets.first;
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _parseData() {
    final rawText = _textController.text;
    if (rawText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tempel teks atau isi CSV terlebih dahulu')),
      );
      return;
    }

    final txProvider = Provider.of<TransactionProvider?>(context, listen: false);
    final existingTx = txProvider?.transactions ?? [];

    final results = BankStatementParserService.parse(
      rawText: rawText,
      preset: _selectedPreset,
      existingTransactions: existingTx,
    );

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada transaksi valid yang ditemukan')),
      );
      return;
    }

    setState(() {
      _parsedItems = results;
      _isParsed = true;
    });
  }

  void _executeImport() async {
    final selected = _parsedItems.where((i) => i.isSelected).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 transaksi untuk diimpor')),
      );
      return;
    }

    setState(() => _isImporting = true);

    try {
      final txProvider = Provider.of<TransactionProvider?>(context, listen: false);
      final walletProvider = Provider.of<WalletProvider?>(context, listen: false);

      int count = 0;
      if (txProvider != null) {
        for (final item in selected) {
          await txProvider.addTransaction(
            item.toTransactionModel(walletId: _targetWallet?.id),
          );
          count++;
        }
        await walletProvider?.refreshBalances();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil mengimpor $count transaksi ke MyDuit! 🎉'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final walletProvider = Provider.of<WalletProvider?>(context);
    final wallets = walletProvider?.wallets ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impor Mutasi & Data Bank'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          // Preset selector
          Text('Pilih Format Sumber Bank / CSV', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          DropdownButtonFormField<BankPreset>(
            initialValue: _selectedPreset,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: BankPreset.values.map((p) {
              return DropdownMenuItem(value: p, child: Text(p.label));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedPreset = val);
            },
          ),
          const SizedBox(height: 16),

          // Target Wallet
          Text('Simpan ke Dompet Tujuan', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          DropdownButtonFormField<WalletModel>(
            initialValue: _targetWallet,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: wallets.map((w) {
              return DropdownMenuItem(
                value: w,
                child: Text('${w.emoji} ${w.name} (${w.currencyCode})'),
              );
            }).toList(),
            onChanged: (val) => setState(() => _targetWallet = val),
          ),
          const SizedBox(height: 16),

          // Text Area Input
          Text('Teks Mutasi / Konten CSV', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _textController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Salin dan tempel baris mutasi bank atau CSV di sini...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('Proses & Tinjau Transaksi'),
              onPressed: _parseData,
            ),
          ),
          const SizedBox(height: 24),

          // Parsed Results Preview
          if (_isParsed) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pratinjau (${_parsedItems.length} transaksi)',
                  style: theme.textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () {
                    final allSelected = _parsedItems.every((i) => i.isSelected);
                    setState(() {
                      for (final i in _parsedItems) {
                        i.isSelected = !allSelected;
                      }
                    });
                  },
                  child: Text(
                    _parsedItems.every((i) => i.isSelected)
                        ? 'Batal Semua'
                        : 'Pilih Semua',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._parsedItems.map((item) {
              final isIncome = item.type == TransactionType.income;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(12),
                  border: item.isDuplicate
                      ? Border.all(color: Colors.amber, width: 1.5)
                      : null,
                ),
                child: CheckboxListTile(
                  value: item.isSelected,
                  onChanged: (val) => setState(() => item.isSelected = val ?? false),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.isDuplicate)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Duplikat',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    '${DateFormatter.shortDate(item.date)} • ${item.category.label}',
                  ),
                  secondary: Text(
                    '${isIncome ? "+" : "-"} ${CurrencyFormatter.format(item.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isIncome ? AppColors.income : AppColors.expense,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),

            // Import Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: _isImporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.file_download_done_rounded),
                label: Text(
                  _isImporting
                      ? 'Mengimpor...'
                      : 'Impor ${_parsedItems.where((i) => i.isSelected).length} Transaksi',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _isImporting ? null : _executeImport,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ],
      ),
    );
  }
}
