import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../models/wallet_model.dart';
import '../providers/wallet_provider.dart';
import '../utils/formatters.dart';
import 'transfer_screen.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dompet'),
        actions: [
          if (walletProvider.wallets.length > 1)
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TransferScreen()),
                );
              },
              icon: const Icon(Icons.swap_horiz_rounded),
              tooltip: 'Transfer',
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWalletDialog(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: walletProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Total balance card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: _TotalBalanceCard(
                      totalBalance: walletProvider.totalBalance,
                      walletCount: walletProvider.wallets.length,
                      isDark: isDark,
                    ).animate().fadeIn(duration: 400.ms),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daftar Dompet',
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          '${walletProvider.wallets.length} dompet',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                // Wallet list
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: walletProvider.wallets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final wallet = walletProvider.wallets[index];
                      final balance =
                          walletProvider.walletBalances[wallet.id] ?? 0.0;
                      return _WalletCard(
                            wallet: wallet,
                            balance: balance,
                            isDark: isDark,
                            isActive:
                                walletProvider.activeWallet?.id == wallet.id,
                            onTap: () => walletProvider.setActiveWallet(wallet),
                            onEdit: () =>
                                _showEditWalletDialog(context, wallet),
                            onDelete: wallet.isDefault
                                ? null
                                : () => _confirmDeleteWallet(context, wallet),
                          )
                          .animate()
                          .fadeIn(
                            delay: Duration(milliseconds: 60 * index),
                            duration: 400.ms,
                          )
                          .slideX(begin: 0.04, end: 0);
                    },
                  ),
                ),
                // Transfer history section
                if (walletProvider.transfers.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                      child: Text(
                        'Riwayat Transfer',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.separated(
                      itemCount: walletProvider.transfers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final transfer = walletProvider.transfers[index];
                        final fromWallet = walletProvider.getWalletById(
                          transfer.fromWalletId,
                        );
                        final toWallet = walletProvider.getWalletById(
                          transfer.toWalletId,
                        );
                        return _TransferTile(
                          fromName: fromWallet?.name ?? 'Dihapus',
                          fromEmoji: fromWallet?.emoji ?? '❓',
                          toName: toWallet?.name ?? 'Dihapus',
                          toEmoji: toWallet?.emoji ?? '❓',
                          amount: transfer.amount,
                          date: transfer.date,
                          note: transfer.note,
                          isDark: isDark,
                          onDelete: () {
                            walletProvider.deleteTransfer(transfer.id);
                          },
                        );
                      },
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }

  void _showAddWalletDialog(BuildContext context) {
    _showWalletFormDialog(context, null);
  }

  void _showEditWalletDialog(BuildContext context, WalletModel wallet) {
    _showWalletFormDialog(context, wallet);
  }

  void _showWalletFormDialog(BuildContext context, WalletModel? wallet) {
    final isEdit = wallet != null;
    final nameController = TextEditingController(
      text: isEdit ? wallet.name : '',
    );
    String selectedEmoji = isEdit ? wallet.emoji : '💰';
    int selectedColor = isEdit
        ? wallet.colorValue
        : WalletModel.presetColors[0];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(isEdit ? 'Edit Dompet' : 'Dompet Baru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Nama Dompet',
                        hintText: 'Contoh: Tabungan',
                      ),
                      autofocus: !isEdit,
                    ),
                    const SizedBox(height: 20),

                    // Emoji selector
                    Text('Ikon', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: WalletModel.presetEmojis.map((emoji) {
                        final isSelected = emoji == selectedEmoji;
                        return GestureDetector(
                          onTap: () => setState(() => selectedEmoji = emoji),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(selectedColor).withValues(alpha: 0.15)
                                  : (isDark
                                        ? AppColors.cardAltDark
                                        : AppColors.cardAltLight),
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(
                                      color: Color(selectedColor),
                                      width: 2,
                                    )
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Color selector
                    Text('Warna', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: WalletModel.presetColors.map((color) {
                        final isSelected = color == selectedColor;
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = color),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(color),
                              borderRadius: BorderRadius.circular(10),
                              border: isSelected
                                  ? Border.all(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                      width: 3,
                                    )
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final provider = context.read<WalletProvider>();
                    if (isEdit) {
                      provider.updateWallet(
                        wallet.copyWith(
                          name: name,
                          emoji: selectedEmoji,
                          colorValue: selectedColor,
                        ),
                      );
                    } else {
                      provider.addWallet(
                        WalletModel(
                          name: name,
                          emoji: selectedEmoji,
                          colorValue: selectedColor,
                        ),
                      );
                    }
                    Navigator.pop(context);
                  },
                  child: Text(isEdit ? 'Simpan' : 'Tambah'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteWallet(BuildContext context, WalletModel wallet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Dompet'),
        content: Text(
          'Apakah kamu yakin ingin menghapus dompet "${wallet.name}"? '
          'Semua transaksi akan dipindahkan ke Dompet Utama.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              context.read<WalletProvider>().deleteWallet(wallet.id);
              Navigator.pop(context);
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalBalanceCard extends StatelessWidget {
  final double totalBalance;
  final int walletCount;
  final bool isDark;

  const _TotalBalanceCard({
    required this.totalBalance,
    required this.walletCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Semua Dompet',
            style: TextStyle(
              color: isDark
                  ? AppColors.surfaceDark.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(totalBalance),
            style: TextStyle(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$walletCount dompet aktif',
              style: TextStyle(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  final WalletModel wallet;
  final double balance;
  final bool isDark;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _WalletCard({
    required this.wallet,
    required this.balance,
    required this.isDark,
    required this.isActive,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletColor = Color(wallet.colorValue);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: isActive ? Border.all(color: walletColor, width: 2) : null,
        ),
        child: Row(
          children: [
            // Emoji avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: walletColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(15),
              ),
              alignment: Alignment.center,
              child: Text(wallet.emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          wallet.name,
                          style: theme.textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (wallet.isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: walletColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Utama',
                            style: TextStyle(
                              color: walletColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(balance),
                    style: TextStyle(
                      color: balance >= 0
                          ? AppColors.income
                          : AppColors.expense,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            // Menu
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete?.call();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                if (onDelete != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppColors.expense,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Hapus',
                          style: TextStyle(color: AppColors.expense),
                        ),
                      ],
                    ),
                  ),
              ],
              icon: Icon(
                Icons.more_vert_rounded,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferTile extends StatelessWidget {
  final String fromName;
  final String fromEmoji;
  final String toName;
  final String toEmoji;
  final double amount;
  final DateTime date;
  final String? note;
  final bool isDark;
  final VoidCallback onDelete;

  const _TransferTile({
    required this.fromName,
    required this.fromEmoji,
    required this.toName,
    required this.toEmoji,
    required this.amount,
    required this.date,
    required this.note,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Transfer icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.swap_horiz_rounded,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(fromEmoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        fromName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward, size: 14),
                    ),
                    Text(toEmoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        toName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormatter.relative(date)}${note != null && note!.isNotEmpty ? ' · $note' : ''}',
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.formatCompact(amount),
                style: TextStyle(
                  color: isDark
                      ? AppColors.primaryDark
                      : AppColors.primaryLight,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
