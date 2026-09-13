import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../models/transaction_model.dart';
import '../providers/template_provider.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import '../widgets/insights_widget.dart';
import '../widgets/transaction_detail_sheet.dart';
import 'add_transaction_screen.dart';
import 'history_screen.dart';
import 'transfer_screen.dart';
import 'wallet_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final walletProvider = context.watch<WalletProvider>();
    final theme = Theme.of(context);

    var transactions = provider.transactions;
    if (!walletProvider.showAllWallets && walletProvider.activeWallet != null) {
      transactions = transactions
          .where((t) => t.walletId == walletProvider.activeWallet!.id)
          .toList();
    }
    final recentTransactions = transactions.take(5).toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'MyDuit 💸',
                                style: theme.textTheme.headlineMedium,
                              ),
                            ],
                          ),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.search_rounded),
                            tooltip: 'Cari Transaksi',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const Scaffold(
                                    body: HistoryScreen(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: -0.05, end: 0),
                  const SizedBox(height: 20),
                  const MonthSelector(),
                  const SizedBox(height: 16),
                  // Wallet quick access
                  _WalletChipBar(),
                  const SizedBox(height: 20),
                  const BalanceCard(),
                  const SizedBox(height: 28),
                  // Quick actions
                  Row(
                        children: [
                          Expanded(
                            child: _QuickActionButton(
                              label: 'Pemasukan',
                              icon: Icons.add_rounded,
                              color: AppColors.income,
                              onTap: () =>
                                  _openAddTransaction(context, isIncome: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QuickActionButton(
                              label: 'Pengeluaran',
                              icon: Icons.remove_rounded,
                              color: AppColors.expense,
                              onTap: () =>
                                  _openAddTransaction(context, isIncome: false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QuickActionButton(
                              label: 'Transfer',
                              icon: Icons.swap_horiz_rounded,
                              color: theme.colorScheme.primary,
                              onTap: () => _openTransfer(context),
                            ),
                          ),
                        ],
                      )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 20),
                  const _QuickTemplateBar(),
                  const SizedBox(height: 24),
                  const InsightsCard(),
                  const SizedBox(height: 24),
                  Text('Transaksi Terbaru', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          if (provider.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (recentTransactions.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                message:
                    'Belum ada transaksi bulan ini.\nTambahkan transaksi pertamamu!',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: recentTransactions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final tx = recentTransactions[index];
                  return TransactionTile(
                        transaction: tx,
                        onDismissed: () {
                          provider.deleteTransaction(tx.id);
                        },
                        onTap: () {
                          showTransactionDetail(
                            context,
                            tx,
                            onDeleted: () => provider.deleteTransaction(tx.id),
                          );
                        },
                      )
                      .animate()
                      .fadeIn(
                        delay: Duration(milliseconds: 100 * index),
                        duration: 400.ms,
                      )
                      .slideX(begin: 0.05, end: 0);
                },
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  String _getGreeting() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;

    if (hour >= 4 && hour < 11) return 'Selamat Pagi 👋';
    if (hour >= 11 && hour < 15) return 'Selamat Siang 👋';
    if (hour >= 15 && (hour < 18 || (hour == 18 && minute < 30))) {
      return 'Selamat Sore 👋';
    }
    return 'Selamat Malam 👋';
  }

  void _openAddTransaction(BuildContext context, {required bool isIncome}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(initialIsIncome: isIncome),
      ),
    );
  }

  void _openTransfer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TransferScreen(),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: color.withValues(alpha: isDark ? 0.15 : 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletChipBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (walletProvider.wallets.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // "All wallets" chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _WalletChip(
              emoji: '🏦',
              label: 'Semua',
              isSelected: walletProvider.showAllWallets,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              isDark: isDark,
              onTap: () => walletProvider.showAll(),
            ),
          ),
          ...walletProvider.wallets.map((wallet) {
            final isSelected =
                !walletProvider.showAllWallets &&
                walletProvider.activeWallet?.id == wallet.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _WalletChip(
                emoji: wallet.emoji,
                label: wallet.name,
                isSelected: isSelected,
                color: Color(wallet.colorValue),
                isDark: isDark,
                onTap: () => walletProvider.setActiveWallet(wallet),
              ),
            );
          }),
          // Manage wallets
          _WalletChip(
            emoji: '⚙️',
            label: 'Kelola',
            isSelected: false,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WalletScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WalletChip extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _WalletChip({
    required this.emoji,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : (isDark ? AppColors.cardDark : AppColors.cardAltLight),
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: color, width: 1.5) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? color
                    : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickTemplateBar extends StatelessWidget {
  const _QuickTemplateBar();

  @override
  Widget build(BuildContext context) {
    final templateProvider = context.watch<TemplateProvider>();
    final templates = templateProvider.templates;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              'Catat Cepat',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: templates.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final tpl = templates[index];
              return ActionChip(
                avatar: Text(tpl.emoji, style: const TextStyle(fontSize: 15)),
                label: Text(
                  '${tpl.name} · ${CurrencyFormatter.format(tpl.amount)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor:
                    isDark ? AppColors.cardDark : AppColors.cardAltLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddTransactionScreen(
                        template: tpl,
                        initialIsIncome: tpl.type == TransactionType.income,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
