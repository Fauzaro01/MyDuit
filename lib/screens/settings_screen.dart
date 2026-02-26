import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../providers/theme_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/app_lock_provider.dart';
import '../services/export_service.dart';
import '../services/pdf_export_service.dart';
import '../services/notification_service.dart';
import 'budget_screen.dart';
import 'wallet_screen.dart';
import 'recurring_transactions_screen.dart';
import 'savings_goals_screen.dart';
import 'debt_screen.dart';
import 'pin_lock_screen.dart';
import 'custom_categories_screen.dart';
import 'backup_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Pengaturan', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 24),

          // Features section
          _SectionHeader(title: 'Fitur'),
          const SizedBox(height: 12),
          _SettingsCard(
            isDark: isDark,
            children: [
              _SettingsTile(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Dompet',
                subtitle: 'Kelola dompet & transfer',
                trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WalletScreen()),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.pie_chart_outline_rounded,
                title: 'Anggaran',
                subtitle: 'Atur batas pengeluaran per kategori',
                trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BudgetScreen()),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.file_download_outlined,
                title: 'Ekspor Data',
                subtitle: 'Bagikan laporan keuangan (CSV/PDF)',
                trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                onTap: () => _showExportDialog(context),
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.repeat_rounded,
                title: 'Transaksi Berulang',
                subtitle: 'Otomatiskan tagihan & pemasukan',
                trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RecurringTransactionsScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.savings_rounded,
                title: 'Tujuan Tabungan',
                subtitle: 'Menabung untuk impianmu',
                trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SavingsGoalsScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.receipt_long_rounded,
                title: 'Hutang & Piutang',
                subtitle: 'Catat & lacak hutang piutang',
                trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DebtScreen()),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.category_rounded,
                title: 'Kategori Kustom',
                subtitle: 'Buat kategori sesuai kebutuhanmu',
                trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CustomCategoriesScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.cloud_rounded,
                title: 'Backup & Restore',
                subtitle: 'Simpan data ke Google Drive',
                trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BackupScreen()),
                  );
                },
              ),
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),

          const SizedBox(height: 24),

          // Appearance section
          _SectionHeader(title: 'Tampilan'),
          const SizedBox(height: 12),
          _SettingsCard(
                isDark: isDark,
                children: [
                  _SettingsTile(
                    icon: Icons.dark_mode_rounded,
                    title: 'Mode Gelap',
                    subtitle: _getThemeModeLabel(themeProvider.themeMode),
                    trailing: Switch.adaptive(
                      value: themeProvider.themeMode == ThemeMode.dark,
                      onChanged: (_) => themeProvider.toggleTheme(),
                      activeColor: AppColors.primaryDark,
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsTile(
                    icon: Icons.palette_outlined,
                    title: 'Tema Sistem',
                    subtitle: 'Ikuti pengaturan perangkat',
                    trailing: Switch.adaptive(
                      value: themeProvider.themeMode == ThemeMode.system,
                      onChanged: (val) {
                        if (val) {
                          themeProvider.setThemeMode(ThemeMode.system);
                        } else {
                          themeProvider.setThemeMode(
                            isDark ? ThemeMode.dark : ThemeMode.light,
                          );
                        }
                      },
                      activeColor: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                    ),
                  ),
                ],
              )
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms)
              .slideY(begin: 0.05, end: 0),

          const SizedBox(height: 24),

          // Notifications section
          _SectionHeader(title: 'Notifikasi'),
          const SizedBox(height: 12),
          _NotificationCard(isDark: isDark)
              .animate()
              .fadeIn(delay: 120.ms, duration: 400.ms)
              .slideY(begin: 0.05, end: 0),

          const SizedBox(height: 24),

          // Security section
          _SectionHeader(title: 'Keamanan'),
          const SizedBox(height: 12),
          Builder(
                builder: (context) {
                  final lockProvider = context.watch<AppLockProvider>();
                  return _SettingsCard(
                    isDark: isDark,
                    children: [
                      _SettingsTile(
                        icon: Icons.lock_rounded,
                        title: 'Kunci PIN',
                        subtitle: lockProvider.isLockEnabled
                            ? 'Aktif'
                            : 'Lindungi data keuanganmu',
                        trailing: Switch.adaptive(
                          value: lockProvider.isLockEnabled,
                          onChanged: (val) async {
                            if (val) {
                              await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const PinLockScreen(isSetup: true),
                                ),
                              );
                            } else {
                              lockProvider.removePin();
                            }
                          },
                          activeColor: isDark
                              ? AppColors.primaryDark
                              : AppColors.primaryLight,
                        ),
                      ),
                      if (lockProvider.isLockEnabled) ...[
                        const Divider(height: 1, indent: 56),
                        _SettingsTile(
                          icon: Icons.fingerprint_rounded,
                          title: 'Sidik Jari',
                          subtitle: lockProvider.isFingerprintEnabled
                              ? 'Aktif'
                              : lockProvider.isFingerprintAvailable
                              ? 'Buka kunci dengan sidik jari'
                              : 'Perangkat tidak mendukung',
                          trailing: Switch.adaptive(
                            value: lockProvider.isFingerprintEnabled,
                            onChanged: lockProvider.canEnableFingerprint
                                ? (val) async {
                                    if (val) {
                                      // Verify PIN first before enabling fingerprint
                                      final verified =
                                          await Navigator.push<bool>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const PinLockScreen(),
                                            ),
                                          );
                                      if (verified == true && context.mounted) {
                                        await lockProvider
                                            .setFingerprintEnabled(true);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                'Sidik jari berhasil diaktifkan 🔓',
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    } else {
                                      await lockProvider.setFingerprintEnabled(
                                        false,
                                      );
                                    }
                                  }
                                : null,
                            activeColor: isDark
                                ? AppColors.primaryDark
                                : AppColors.primaryLight,
                          ),
                        ),
                        const Divider(height: 1, indent: 56),
                        _SettingsTile(
                          icon: Icons.password_rounded,
                          title: 'Ubah PIN',
                          subtitle: 'Ganti PIN saat ini',
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            size: 22,
                          ),
                          onTap: () async {
                            // First verify current PIN
                            final verified = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PinLockScreen(),
                              ),
                            );
                            if (verified == true && context.mounted) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const PinLockScreen(isSetup: true),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ],
                  );
                },
              )
              .animate()
              .fadeIn(delay: 150.ms, duration: 400.ms)
              .slideY(begin: 0.05, end: 0),

          const SizedBox(height: 24),

          // About section
          _SectionHeader(title: 'Tentang'),
          const SizedBox(height: 12),
          _SettingsCard(
                isDark: isDark,
                children: [
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: 'MyDuit',
                    subtitle: 'Versi 1.0.0',
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsTile(
                    icon: Icons.code_rounded,
                    title: 'Dibuat dengan',
                    subtitle: 'Flutter & ❤️',
                  ),
                ],
              )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.05, end: 0),

          const SizedBox(height: 24),

          // Tips
          Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:
                      (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            (isDark
                                    ? AppColors.primaryDark
                                    : AppColors.primaryLight)
                                .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        color: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tips 💡', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            'Geser transaksi ke kiri untuk menghapusnya dengan cepat!',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(delay: 300.ms, duration: 400.ms)
              .slideY(begin: 0.05, end: 0),
        ],
      ),
    );
  }

  Future<void> _showExportDialog(BuildContext context) async {
    final provider = context.read<TransactionProvider>();
    final transactions = provider.transactions;

    if (transactions.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tidak ada transaksi untuk diekspor.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            Text('Ekspor Data', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '${transactions.length} transaksi',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.income.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.table_chart_rounded,
                  color: AppColors.income,
                ),
              ),
              title: const Text('Export CSV'),
              subtitle: const Text('Spreadsheet sederhana'),
              trailing: const Icon(Icons.chevron_right_rounded),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await ExportService.shareExport(
                    transactions,
                    year: provider.selectedYear,
                    month: provider.selectedMonth,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                  }
                }
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.expense.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColors.expense,
                ),
              ),
              title: const Text('Export PDF'),
              subtitle: const Text('Laporan lengkap profesional'),
              trailing: const Icon(Icons.chevron_right_rounded),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await PdfExportService.exportAndShare(
                    transactions,
                    year: provider.selectedYear,
                    month: provider.selectedMonth,
                    totalIncome: provider.totalIncome,
                    totalExpense: provider.totalExpense,
                    expenseCategoryTotals: provider.expenseCategoryTotals,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                  }
                }
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                          .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.print_rounded,
                  color: isDark
                      ? AppColors.primaryDark
                      : AppColors.primaryLight,
                ),
              ),
              title: const Text('Cetak PDF'),
              subtitle: const Text('Print langsung'),
              trailing: const Icon(Icons.chevron_right_rounded),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await PdfExportService.printReport(
                    transactions,
                    year: provider.selectedYear,
                    month: provider.selectedMonth,
                    totalIncome: provider.totalIncome,
                    totalExpense: provider.totalExpense,
                    expenseCategoryTotals: provider.expenseCategoryTotals,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                  }
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Mengikuti sistem';
      case ThemeMode.light:
        return 'Mode terang';
      case ThemeMode.dark:
        return 'Mode gelap';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _SettingsCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatefulWidget {
  final bool isDark;
  const _NotificationCard({required this.isDark});

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  bool _enabled = false;
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await NotificationService.isEnabled();
    final time = await NotificationService.getScheduledTime();
    if (mounted) {
      setState(() {
        _enabled = enabled;
        _time = time;
      });
    }
  }

  Future<void> _toggleNotification(bool value) async {
    if (value) {
      final granted = await NotificationService.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Izin notifikasi ditolak'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }
      await NotificationService.enable(hour: _time.hour, minute: _time.minute);
    } else {
      await NotificationService.disable();
    }
    setState(() => _enabled = value);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() => _time = picked);
      if (_enabled) {
        await NotificationService.updateTime(picked.hour, picked.minute);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      isDark: widget.isDark,
      children: [
        _SettingsTile(
          icon: Icons.notifications_rounded,
          title: 'Pengingat Harian',
          subtitle: _enabled
              ? 'Aktif pukul ${_time.format(context)}'
              : 'Ingatkan untuk mencatat keuangan',
          trailing: Switch.adaptive(
            value: _enabled,
            onChanged: _toggleNotification,
            activeColor: widget.isDark
                ? AppColors.primaryDark
                : AppColors.primaryLight,
          ),
        ),
        if (_enabled) ...[
          const Divider(height: 1, indent: 56),
          _SettingsTile(
            icon: Icons.access_time_rounded,
            title: 'Waktu Pengingat',
            subtitle: _time.format(context),
            trailing: const Icon(Icons.chevron_right_rounded, size: 22),
            onTap: _pickTime,
          ),
        ],
      ],
    );
  }
}
