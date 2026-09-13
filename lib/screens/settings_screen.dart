import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';
import '../utils/formatters.dart';
import '../providers/theme_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/app_lock_provider.dart';
import '../providers/custom_category_provider.dart';
import '../services/export_service.dart';
import '../providers/currency_provider.dart';
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
import 'split_bill_screen.dart';
import 'financial_health_screen.dart';
import 'data_migration_screen.dart';
import 'financial_calendar_screen.dart';
import 'subscription_screen.dart';
import 'net_worth_screen.dart';
import 'financial_advisor_screen.dart';
import 'financial_calculator_screen.dart';
import 'badges_screen.dart';
import 'monthly_recap_screen.dart';

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
                icon: Icons.emoji_events_outlined,
                title: 'Pencapaian & Streak',
                subtitle: 'Pelacak konsistensi & koleksi medali',
                trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BadgesScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.auto_awesome_motion_rounded,
                title: 'Kilas Balik Finansial (Recap)',
                subtitle: 'Infografis performa keuangan bulanan',
                trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MonthlyRecapScreen(),
                    ),
                  );
                },
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
                icon: Icons.health_and_safety_outlined,
                title: 'Kesehatan Finansial',
                subtitle: 'Analisis skor 50/30/20 & proyeksi saldo',
                trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FinancialHealthScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.call_split_rounded,
                title: 'Bagi Tagihan (Split Bill)',
                subtitle: 'Patungan acara & pembagian rata/custom',
                trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SplitBillScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.file_upload_outlined,
                title: 'Impor Mutasi Bank & CSV',
                subtitle: 'BCA, Mandiri, BRI & Universal CSV',
                trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DataMigrationScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.calendar_month_rounded,
                title: 'Kalender Finansial & Heatmap',
                subtitle: 'Peta intensitas belanja & tanggal jatuh tempo',
                trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FinancialCalendarScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.subscriptions_rounded,
                title: 'Langganan & Beban Tetap',
                subtitle: 'Pantau tagihan rutin & rasio biaya tetap',
                trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.account_balance_rounded,
                title: 'Kekayaan Bersih (Net Worth)',
                subtitle: 'Portofolio aset investasi, kas & kewajiban',
                trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NetWorthScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.auto_awesome_rounded,
                title: 'AI Financial Advisor',
                subtitle: 'Deteksi anomali belanja & insight cerdas',
                trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FinancialAdvisorScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.calculate_rounded,
                title: 'Kalkulator Finansial',
                subtitle: 'Simulasi bunga majemuk, pinjaman KPR, dana darurat & FIRE',
                trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FinancialCalculatorScreen(),
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
                      activeTrackColor: AppColors.primaryDark,
                    ),
                  ),
                  if (themeProvider.themeMode == ThemeMode.dark) ...[
                    const Divider(height: 1, indent: 56),
                    _SettingsTile(
                      icon: Icons.brightness_2_rounded,
                      title: 'AMOLED Pure Black',
                      subtitle: themeProvider.isAmoledMode
                          ? 'Hitam murni (#000000) hemat baterai OLED'
                          : 'Warna gelap standar',
                      trailing: Switch.adaptive(
                        value: themeProvider.isAmoledMode,
                        onChanged: (_) => themeProvider.toggleAmoledMode(),
                        activeTrackColor: AppColors.primaryDark,
                      ),
                    ),
                  ],
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
                      activeTrackColor: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsTile(
                    icon: Icons.color_lens_outlined,
                    title: 'Aksen Warna Aplikasi',
                    subtitle: themeProvider.accentColor.label,
                    trailing: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isDark
                            ? themeProvider.accentColor.darkColor
                            : themeProvider.accentColor.lightColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    onTap: () => _showAccentColorPicker(context),
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsTile(
                    icon: Icons.visibility_outlined,
                    title: 'Mode Privasi (Sensor Saldo)',
                    subtitle: themeProvider.isPrivacyMode
                        ? 'Saldo disamarkan (Rp ••••••••)'
                        : 'Saldo ditampilkan normal',
                    trailing: Switch.adaptive(
                      value: themeProvider.isPrivacyMode,
                      onChanged: (_) => themeProvider.togglePrivacyMode(),
                      activeTrackColor: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsTile(
                    icon: Icons.vibration_rounded,
                    title: 'Umpan Balik Haptik (Getar)',
                    subtitle: themeProvider.isHapticsEnabled
                        ? 'Getar halus saat tap & simpan data'
                        : 'Getar dinonaktifkan',
                    trailing: Switch.adaptive(
                      value: themeProvider.isHapticsEnabled,
                      onChanged: (_) => themeProvider.toggleHaptics(),
                      activeTrackColor: isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  _CurrencyFormatTile(isDark: isDark),
                  const Divider(height: 1, indent: 56),
                  _BaseCurrencyTile(isDark: isDark),
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
                          activeTrackColor: isDark
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
                            activeTrackColor: isDark
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
                        const Divider(height: 1, indent: 56),
                        _SettingsTile(
                          icon: Icons.timer_outlined,
                          title: 'Kunci Otomatis',
                          subtitle: _getTimeoutLabel(lockProvider.lockTimeoutSeconds),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            size: 22,
                          ),
                          onTap: () => _showLockTimeoutDialog(context, lockProvider),
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
                    icon: Icons.person_rounded,
                    title: 'Developer',
                    subtitle: 'Muhamad Fauzaan',
                  ),
                  const Divider(height: 1, indent: 56),
                  _SettingsTile(
                    icon: Icons.open_in_new_rounded,
                    title: 'GitHub',
                    subtitle: 'github.com/fauzaro01',
                    trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                    onTap: () => _launchUrl('https://github.com/fauzaro01'),
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showExportDialog(BuildContext context) async {
    final provider = context.read<TransactionProvider>();
    final customCatProvider =
        Provider.of<CustomCategoryProvider?>(context, listen: false);
    final transactions = provider.transactions;

    final customCategoryNames = <String, String>{
      for (final c in customCatProvider?.categories ?? []) c.id: c.name,
    };

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
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.paddingOf(ctx).bottom + 20,
        ),
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
                    customCategoryNames: customCategoryNames,
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
                    expenseCustomTotals: provider.expenseCustomTotals,
                    customCategoryNames: customCategoryNames,
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
                    expenseCustomTotals: provider.expenseCustomTotals,
                    customCategoryNames: customCategoryNames,
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

  String _getTimeoutLabel(int seconds) {
    switch (seconds) {
      case 0:
        return 'Langsung saat keluar';
      case 60:
        return 'Setelah 1 menit';
      case 300:
        return 'Setelah 5 menit';
      case 900:
        return 'Setelah 15 menit';
      default:
        return '$seconds detik';
    }
  }

  void _showAccentColorPicker(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.primaryDark : AppColors.primaryLight).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.color_lens_rounded,
                        color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Pilih Aksen Warna',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...AppAccentColor.values.map((accent) {
                  final isSelected = themeProvider.accentColor == accent;
                  final accentColor = isDark ? accent.darkColor : accent.lightColor;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                          : null,
                    ),
                    title: Text(
                      accent.label,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? accentColor : null,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle_rounded, color: accentColor)
                        : null,
                    onTap: () {
                      themeProvider.setAccentColor(accent);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLockTimeoutDialog(BuildContext context, AppLockProvider lockProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kunci Otomatis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _timeoutOption(ctx, lockProvider, 0, 'Langsung saat keluar'),
            _timeoutOption(ctx, lockProvider, 60, 'Setelah 1 menit'),
            _timeoutOption(ctx, lockProvider, 300, 'Setelah 5 menit'),
            _timeoutOption(ctx, lockProvider, 900, 'Setelah 15 menit'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  Widget _timeoutOption(
    BuildContext ctx,
    AppLockProvider lockProvider,
    int seconds,
    String label,
  ) {
    final isSelected = lockProvider.lockTimeoutSeconds == seconds;
    return ListTile(
      title: Text(label),
      trailing: isSelected
          ? const Icon(Icons.check_rounded, color: AppColors.primaryLight)
          : null,
      onTap: () {
        lockProvider.setLockTimeout(seconds);
        Navigator.pop(ctx);
      },
    );
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
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _CurrencyFormatTile extends StatefulWidget {
  final bool isDark;
  const _CurrencyFormatTile({required this.isDark});

  @override
  State<_CurrencyFormatTile> createState() => _CurrencyFormatTileState();
}

class _CurrencyFormatTileState extends State<_CurrencyFormatTile> {
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _enabled = CurrencyInputService.isFormatted;
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: Icons.format_list_numbered_rounded,
      title: 'Format Input Rupiah',
      subtitle: _enabled
          ? 'Seperti: 1.000, 12.000, 1.200.300'
          : 'Angka biasa tanpa titik',
      trailing: Switch.adaptive(
        value: _enabled,
        onChanged: (val) async {
          await CurrencyInputService.setFormatted(val);
          setState(() => _enabled = val);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  val
                      ? 'Format Rupiah diaktifkan'
                      : 'Format Rupiah dinonaktifkan',
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        activeTrackColor: widget.isDark
            ? AppColors.primaryDark
            : AppColors.primaryLight,
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
            activeTrackColor: widget.isDark
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

class _BaseCurrencyTile extends StatelessWidget {
  final bool isDark;
  const _BaseCurrencyTile({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final currProvider = Provider.of<CurrencyProvider?>(context);
    final currentCode = currProvider?.baseCurrencyCode ?? 'IDR';
    final isStale = currProvider?.isRateStale ?? false;

    return _SettingsTile(
      icon: Icons.currency_exchange_rounded,
      title: 'Mata Uang Utama',
      subtitle: isStale
          ? '$currentCode - ${currProvider?.getSymbol(currentCode) ?? 'Rp'} ⚠️ (Kurs >24 jam)'
          : '$currentCode - ${currProvider?.getSymbol(currentCode) ?? 'Rp'}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isStale)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber,
                size: 18,
              ),
            ),
          const Icon(Icons.chevron_right_rounded, size: 22),
        ],
      ),
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) {
            final currencies = currProvider?.availableCurrencies ?? [];
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.primaryDark : AppColors.primaryLight).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.currency_exchange_rounded,
                            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Pilih Mata Uang Utama',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...currencies.map((c) {
                      final isSelected = c.code == currentCode;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardAltDark : AppColors.cardAltLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            c.symbol,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        title: Text(
                          '${c.code} - ${c.name}',
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          c.code == 'IDR'
                              ? 'Basis nilai acuan'
                              : '1 ${c.code} ≈ ${CurrencyFormatter.format(c.rateToIdr)}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.income)
                            : null,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          currProvider?.setBaseCurrency(c.code);
                          Navigator.pop(ctx);
                        },
                      );
                    }),
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
