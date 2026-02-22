import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import '../widgets/insights_widget.dart';
import '../widgets/transaction_detail_sheet.dart';
import 'add_transaction_screen.dart';
import 'wallet_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final theme = Theme.of(context);
    final recentTransactions = provider.transactions.take(5).toList();

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
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionButton(
                              label: 'Pengeluaran',
                              icon: Icons.remove_rounded,
                              color: AppColors.expense,
                              onTap: () =>
                                  _openAddTransaction(context, isIncome: false),
                            ),
                          ),
                        ],
                      )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),
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
                separatorBuilder: (_, __) => const SizedBox(height: 8),
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
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi 👋';
    if (hour < 17) return 'Selamat Siang 👋';
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
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
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
