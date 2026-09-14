import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/subscription_model.dart';
import '../models/transaction_model.dart';
import '../providers/subscription_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/subscription_analyzer_service.dart';
import '../utils/formatters.dart';

enum SubscriptionFilter { all, active, dueThisMonth, highestCost }

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  SubscriptionFilter _selectedFilter = SubscriptionFilter.all;

  List<SubscriptionModel> _filterAndSort(List<SubscriptionModel> subs) {
    final today = DateTime.now();
    var list = List<SubscriptionModel>.from(subs);

    switch (_selectedFilter) {
      case SubscriptionFilter.all:
        break;
      case SubscriptionFilter.active:
        list = list.where((s) => s.isActive).toList();
        break;
      case SubscriptionFilter.dueThisMonth:
        list = list.where((s) => s.isActive && s.dueDay >= today.day).toList();
        list.sort((a, b) => a.dueDay.compareTo(b.dueDay));
        break;
      case SubscriptionFilter.highestCost:
        list.sort((a, b) => b.monthlyCost.compareTo(a.monthlyCost));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final subProvider = context.watch<SubscriptionProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalMonthly = subProvider.totalMonthlyCost;
    final totalIncome = txProvider.totalIncome;
    final fixedCostRatio = totalIncome > 0 ? (totalMonthly / totalIncome) * 100 : 0.0;
    final hikeAlerts = SubscriptionAnalyzerService.detectPriceHikes(
      subscriptions: subProvider.subscriptions,
      transactions: txProvider.transactions,
    );
    final displayedSubs = _filterAndSort(subProvider.subscriptions);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Langganan & Beban Tetap'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSubscriptionDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Langganan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (hikeAlerts.isNotEmpty) ...[
            ...hikeAlerts.map((alert) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.trending_up_rounded, color: Color(0xFFEA580C), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Deteksi Kenaikan Harga: ${alert.subscription.name}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFFEA580C),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Transaksi terakhir tercatat ${CurrencyFormatter.format(alert.newAmount)} '
                            '(Naik ${alert.percentageIncrease.toStringAsFixed(1)}% dari batas ${CurrencyFormatter.format(alert.oldAmount)}). '
                            'Beban tambahan: +${CurrencyFormatter.formatCompact(alert.annualImpact)}/thn.',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 24),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              subProvider.updateSubscription(
                                alert.subscription.copyWith(amount: alert.newAmount),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Nominal langganan diperbarui mengikuti tagihan baru'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: const Text('Perbarui Tarif Langganan', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Total Monthly Fixed Cost Summary Card
          Container(
            padding: const EdgeInsets.all(20),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL BEBAN TETAP BULANAN',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyFormatter.format(totalMonthly),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Rasio: ${fixedCostRatio.toStringAsFixed(1)}% Pemasukan',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${subProvider.activeSubscriptions.length} Langganan Aktif',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Semua (${subProvider.subscriptions.length})', SubscriptionFilter.all, isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Aktif (${subProvider.activeSubscriptions.length})', SubscriptionFilter.active, isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Sisa Bulan Ini ⏰', SubscriptionFilter.dueThisMonth, isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Biaya Tertinggi 💰', SubscriptionFilter.highestCost, isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text('Daftar Langganan', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          if (displayedSubs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  _selectedFilter == SubscriptionFilter.all
                      ? 'Belum ada langganan atau tagihan tetap.\nTekan tombol tambah di bawah!'
                      : 'Tidak ada langganan yang cocok dengan filter.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...displayedSubs.map((sub) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                        .withValues(alpha: 0.15),
                    child: Text(
                      sub.category.icon,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  title: Text(
                    sub.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: sub.isActive ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  subtitle: Text(
                    '${sub.billingCycle.label} • Setiap tgl ${sub.dueDay}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        CurrencyFormatter.format(sub.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch.adaptive(
                        value: sub.isActive,
                        onChanged: (_) => subProvider.toggleActive(sub),
                        activeTrackColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        color: AppColors.expense,
                        onPressed: () => _confirmDelete(context, sub),
                        tooltip: 'Hapus Langganan',
                      ),
                    ],
                  ),
                  onLongPress: () => _confirmDelete(context, sub),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, SubscriptionFilter filter, bool isDark) {
    final isSelected = _selectedFilter == filter;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? (isDark ? Colors.black : Colors.white)
              : null,
        ),
      ),
      selected: isSelected,
      selectedColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
      onSelected: (_) => setState(() => _selectedFilter = filter),
    );
  }

  void _confirmDelete(BuildContext context, SubscriptionModel sub) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Langganan?'),
        content: Text(
          'Yakin ingin menghapus langganan "${sub.name}" (${CurrencyFormatter.format(sub.amount)} / ${sub.billingCycle.label})?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () {
              context.read<SubscriptionProvider>().deleteSubscription(sub.id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showAddSubscriptionDialog(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    int dueDay = 1;
    BillingCycle cycle = BillingCycle.monthly;

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
                    'Tambah Langganan / Tagihan Tetap',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Layanan (e.g. Netflix, Spotify, Wifi)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nominal Biaya (Rp)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<BillingCycle>(
                          initialValue: cycle,
                          decoration: const InputDecoration(
                            labelText: 'Siklus',
                            border: OutlineInputBorder(),
                          ),
                          items: BillingCycle.values.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c.label));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => cycle = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: dueDay,
                          decoration: const InputDecoration(
                            labelText: 'Tgl Tagihan',
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(31, (i) => i + 1).map((d) {
                            return DropdownMenuItem(value: d, child: Text('Tgl $d'));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => dueDay = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        final amount = RupiahInputFormatter.parse(amountController.text);
                        if (name.isEmpty || amount <= 0) return;

                        final sub = SubscriptionModel(
                          name: name,
                          amount: amount,
                          billingCycle: cycle,
                          dueDay: dueDay,
                        );
                        context.read<SubscriptionProvider>().addSubscription(sub);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Simpan Langganan'),
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
}
