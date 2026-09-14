import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../config/app_theme.dart';
import '../models/split_bill_model.dart';
import '../providers/split_bill_provider.dart';
import '../services/split_bill_service.dart';
import '../utils/formatters.dart';
import 'create_split_bill_screen.dart';

class SplitBillScreen extends StatefulWidget {
  const SplitBillScreen({super.key});

  @override
  State<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends State<SplitBillScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final splitProvider = context.watch<SplitBillProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bagi Tagihan (Split Bill)'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Aktif (${splitProvider.activeBills.length})'),
            Tab(text: 'Selesai (${splitProvider.settledBills.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateSplitBillScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buat Patungan'),
      ),
      body: splitProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBillList(splitProvider.activeBills, isDark),
                _buildBillList(splitProvider.settledBills, isDark),
              ],
            ),
    );
  }

  Widget _buildBillList(List<SplitBillModel> bills, bool isDark) {
    if (bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 64,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada tagihan patungan',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: bills.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final bill = bills[index];
        return _BillCard(
          bill: bill,
          isDark: isDark,
          onTap: () => _showBillDetailSheet(context, bill, isDark),
        );
      },
    );
  }

  void _showBillDetailSheet(
    BuildContext context,
    SplitBillModel bill,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer<SplitBillProvider>(
          builder: (context, provider, _) {
            // Find live bill reference
            final currentBill = provider.bills.firstWhere(
              (b) => b.id == bill.id,
              orElse: () => bill,
            );

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          currentBill.title,
                          style: Theme.of(ctx).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_rounded),
                        tooltip: 'Bagikan ke WhatsApp',
                        onPressed: () {
                          final summary =
                              SplitBillService.generateShareSummary(currentBill);
                          Share.share(summary);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded),
                        tooltip: 'Hapus Patungan',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              title: const Text('Hapus Patungan?'),
                              content: Text(
                                'Apakah kamu yakin ingin menghapus patungan "${currentBill.title}" (${CurrencyFormatter.format(currentBill.totalAmount)})?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogCtx, false),
                                  child: const Text('Batal'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.expense,
                                  ),
                                  onPressed: () => Navigator.pop(dialogCtx, true),
                                  child: const Text('Hapus'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            if (ctx.mounted) Navigator.pop(ctx);
                            provider.deleteBill(currentBill.id);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormatter.fullDate(currentBill.date)} • Total: ${CurrencyFormatter.format(currentBill.totalAmount)}',
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daftar Anggota & Status Bayar:',
                        style: Theme.of(ctx).textTheme.labelLarge,
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(
                          currentBill.isSettled
                              ? Icons.remove_done_rounded
                              : Icons.done_all_rounded,
                          size: 16,
                          color: currentBill.isSettled
                              ? Colors.grey
                              : AppColors.income,
                        ),
                        label: Text(
                          currentBill.isSettled
                              ? 'Reset Status'
                              : 'Tandai Semua Lunas',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: currentBill.isSettled
                                ? Colors.grey
                                : AppColors.income,
                          ),
                        ),
                        onPressed: () {
                          final shouldPayAll = !currentBill.isSettled;
                          provider.setAllParticipantsPaid(
                            currentBill.id,
                            shouldPayAll,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...currentBill.participants.map((p) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Checkbox(
                        value: p.isPaid,
                        onChanged: (_) {
                          provider.toggleParticipantPaid(currentBill.id, p.id);
                        },
                      ),
                      title: Text(
                        p.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          decoration: p.isPaid
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      subtitle: Text(CurrencyFormatter.format(p.amount)),
                      trailing: !p.isPaid
                          ? TextButton.icon(
                              icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                              label: const Text('Catat Piutang', style: TextStyle(fontSize: 12)),
                              onPressed: () async {
                                await provider.recordAsDebt(
                                  context,
                                  billId: currentBill.id,
                                  participant: p,
                                  billTitle: currentBill.title,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Tercatat sebagai piutang: ${p.name}'),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }
                              },
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.income.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Lunas',
                                style: TextStyle(
                                  color: AppColors.income,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Salin Rincian'),
                          onPressed: () {
                            final summary =
                                SplitBillService.generateShareSummary(currentBill);
                            Clipboard.setData(ClipboardData(text: summary));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Rincian disalin ke clipboard!'),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            provider.toggleSettleBill(currentBill.id);
                            Navigator.pop(ctx);
                          },
                          child: Text(
                            currentBill.isSettled ? 'Tandai Belum Selesai' : 'Tandai Selesai',
                          ),
                        ),
                      ),
                    ],
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

class _BillCard extends StatelessWidget {
  final SplitBillModel bill;
  final bool isDark;
  final VoidCallback onTap;

  const _BillCard({
    required this.bill,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final paidCount = bill.participants.where((p) => p.isPaid).length;
    final totalCount = bill.participants.length;
    final progress = totalCount > 0 ? paidCount / totalCount : 1.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    bill.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(bill.totalAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${DateFormatter.shortDate(bill.date)} • $paidCount dari $totalCount orang telah bayar',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  bill.isSettled ? AppColors.income : AppColors.primaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
