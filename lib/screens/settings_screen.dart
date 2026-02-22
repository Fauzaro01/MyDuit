import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../providers/theme_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/export_service.dart';
import 'budget_screen.dart';

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
                subtitle: 'Bagikan laporan keuangan (CSV)',
                trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                onTap: () => _exportData(context),
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

  Future<void> _exportData(BuildContext context) async {
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

    try {
      await ExportService.shareExport(
        transactions,
        year: provider.selectedYear,
        month: provider.selectedMonth,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
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
