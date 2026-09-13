import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/asset_model.dart';
import '../providers/asset_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/debt_provider.dart';
import '../services/net_worth_service.dart';
import '../utils/formatters.dart';

class NetWorthScreen extends StatelessWidget {
  const NetWorthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final assetProvider = context.watch<AssetProvider>();
    final walletProvider = Provider.of<WalletProvider?>(context);
    final debtProvider = Provider.of<DebtProvider?>(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final snapshot = NetWorthService.calculate(
      wallets: walletProvider?.wallets ?? [],
      walletBalances: walletProvider?.walletBalances ?? {},
      assets: assetProvider.assets,
      debts: debtProvider?.debts ?? [],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kekayaan Bersih (Net Worth)'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAssetDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Aset'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Total Net Worth Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [AppColors.primaryLight, const Color(0xFF0A755C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  'TOTAL KEKAYAAN BERSIH (NET WORTH)',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  CurrencyFormatter.format(snapshot.netWorth),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSubMetric(
                      'Total Aset',
                      snapshot.grossAssets,
                      Colors.greenAccent,
                    ),
                    Container(height: 24, width: 1, color: Colors.white24),
                    _buildSubMetric(
                      'Total Hutang',
                      snapshot.totalLiabilities,
                      Colors.orangeAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Breakdown tiles
          Text('Komposisi Aset & Liabilitas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          _buildBreakdownTile(
            context: context,
            title: 'Kas & Rekening Bank',
            subtitle: '${walletProvider?.wallets.length ?? 0} Dompet',
            amount: snapshot.totalWalletBalance,
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
          const SizedBox(height: 8),

          _buildBreakdownTile(
            context: context,
            title: 'Portofolio Investasi & Aset',
            subtitle: '${assetProvider.assets.length} Item Aset',
            amount: snapshot.totalAssets,
            icon: Icons.diamond_rounded,
            color: const Color(0xFF3B82F6),
            isDark: isDark,
          ),
          const SizedBox(height: 8),

          _buildBreakdownTile(
            context: context,
            title: 'Piutang (Uang di Orang)',
            subtitle: 'Aset piutang belum tertagih',
            amount: snapshot.totalReceivables,
            icon: Icons.call_made_rounded,
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
          const SizedBox(height: 8),

          _buildBreakdownTile(
            context: context,
            title: 'Hutang & Kewajiban',
            subtitle: 'Liabilitas belum terlunasi',
            amount: snapshot.totalDebts,
            icon: Icons.call_received_rounded,
            color: const Color(0xFFEF4444),
            isDark: isDark,
            isNegative: true,
          ),
          const SizedBox(height: 24),

          // Detailed Asset Items
          Text('Rincian Aset Investasi', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          if (assetProvider.assets.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Belum ada aset investasi terdaftar.\nTekan Tambah Aset untuk mencatat emas, saham, deposito, dll.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...assetProvider.assets.map((a) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: Text(a.type.emoji, style: const TextStyle(fontSize: 24)),
                  title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(a.type.label, style: const TextStyle(fontSize: 12)),
                  trailing: Text(
                    CurrencyFormatter.format(a.amount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.income,
                    ),
                  ),
                  onTap: () => _showAssetValuationSheet(context, a, isDark),
                  onLongPress: () => _confirmDeleteAsset(context, a),
                ),
              );
            }),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildSubMetric(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.formatCompact(amount),
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildBreakdownTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required double amount,
    required IconData icon,
    required Color color,
    required bool isDark,
    bool isNegative = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Text(
            '${isNegative ? "- " : ""}${CurrencyFormatter.format(amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isNegative ? AppColors.expense : (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAsset(BuildContext context, AssetModel asset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Aset?'),
        content: Text('Yakin ingin menghapus ${asset.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              context.read<AssetProvider>().deleteAsset(asset.id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showAddAssetDialog(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    AssetType type = AssetType.gold;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
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
                  const Text(
                    'Tambah Aset / Portofolio Investasi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Aset (e.g. Antam 10gr, BBCA, Reksadana Sucorinvest)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AssetType>(
                    initialValue: type,
                    decoration: const InputDecoration(
                      labelText: 'Kategori Aset',
                      border: OutlineInputBorder(),
                    ),
                    items: AssetType.values.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text('${t.emoji} ${t.label}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => type = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Estimasi Nilai Total (Rp)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        final amount = RupiahInputFormatter.parse(amountController.text);
                        if (name.isEmpty || amount <= 0) return;

                        final asset = AssetModel(
                          name: name,
                          type: type,
                          amount: amount,
                        );
                        context.read<AssetProvider>().addAsset(asset);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Simpan Aset'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAssetValuationSheet(BuildContext context, AssetModel asset, bool isDark) {
    double annualRate = (asset.type == AssetType.other || asset.type == AssetType.cash)
        ? -10.0
        : 8.0;
    int years = 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final futureVal = asset.estimateValuation(
              years: years,
              annualRatePercent: annualRate,
            );
            final diff = futureVal - asset.amount;
            final isGain = diff >= 0;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(asset.type.emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                asset.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                'Simulasi Valuasi & Depresiasi Aset',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardAltDark : AppColors.cardAltLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Nilai Saat Ini', style: TextStyle(fontSize: 13)),
                              Text(
                                CurrencyFormatter.format(asset.amount),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Estimasi ($years Tahun Lagi)', style: const TextStyle(fontSize: 13)),
                              Text(
                                CurrencyFormatter.format(futureVal),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: isGain ? AppColors.income : AppColors.expense,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${isGain ? '+' : ''}${CurrencyFormatter.format(diff)} (${isGain ? '+' : ''}${((futureVal - asset.amount) / (asset.amount > 0 ? asset.amount : 1) * 100).toStringAsFixed(1)}%)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isGain ? AppColors.income : AppColors.expense,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Laju Perubahan Tahunan: ${annualRate >= 0 ? '+' : ''}${annualRate.toStringAsFixed(0)}% / thn', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    Slider(
                      value: annualRate,
                      min: -50.0,
                      max: 50.0,
                      divisions: 100,
                      label: '${annualRate >= 0 ? '+' : ''}${annualRate.toStringAsFixed(0)}%',
                      onChanged: (v) => setState(() => annualRate = v),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Penyusutan (-50%)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        const Text('Netral (0%)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        const Text('Apresiasi (+50%)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text('Jangka Waktu Proyeksi: $years Tahun', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    Slider(
                      value: years.toDouble(),
                      min: 1.0,
                      max: 20.0,
                      divisions: 19,
                      label: '$years Tahun',
                      onChanged: (v) => setState(() => years = v.toInt()),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
