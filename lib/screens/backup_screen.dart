import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/custom_category_provider.dart';
import '../providers/debt_provider.dart';
import '../providers/recurring_provider.dart';
import '../providers/savings_provider.dart';
import '../providers/split_bill_provider.dart';
import '../providers/tag_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/asset_provider.dart';
import '../providers/template_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/google_drive_service.dart';
import '../services/local_backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isConnected = false; // User was previously signed in (from prefs)
  bool _hasLiveSession = false; // Active Google session object
  bool _isLoading = false;
  bool _isRestoringSession = false; // Background session restore in progress
  String? _statusMessage;
  DateTime? _lastBackup;
  DriveBackupInfo? _backupInfo;
  String? _userEmail;
  BackupSchedule _schedule = BackupSchedule.none;

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  /// Page init: fast prefs check → show UI → silent restore in background
  Future<void> _initPage() async {
    // Step 1: Fast check from SharedPreferences (no network)
    final connected = await GoogleDriveService.checkConnectionStatus();
    final schedule = await GoogleDriveService.getBackupSchedule();
    if (mounted) {
      setState(() {
        _isConnected = connected;
        _userEmail = GoogleDriveService.userEmail;
        _schedule = schedule;
      });
    }

    if (!connected) return; // Not connected, show login button

    // Step 2: Try silent session restore in background
    setState(() => _isRestoringSession = true);
    final restored = await GoogleDriveService.restoreSessionSilently();
    if (mounted) {
      setState(() {
        _hasLiveSession = restored;
        _isRestoringSession = false;
      });
    }

    // Step 3: Load last backup time if we have a session
    if (restored) {
      _loadLastBackupTime();
    }
  }

  Future<void> _loadLastBackupTime() async {
    final info = await GoogleDriveService.getBackupInfo();
    if (mounted) {
      setState(() {
        _backupInfo = info;
        _lastBackup = info?.modifiedTime;
      });
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });
    final error = await GoogleDriveService.signIn();
    final success = error == null;
    final schedule = await GoogleDriveService.getBackupSchedule();
    setState(() {
      _isConnected = success;
      _hasLiveSession = success;
      _isLoading = false;
      _userEmail = GoogleDriveService.userEmail;
      _schedule = schedule;
      if (!success) {
        _statusMessage = error;
      }
    });
    if (success) {
      _loadLastBackupTime();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar Akun?'),
        content: const Text(
          'Kamu akan keluar dari akun Google. '
          'Jadwal backup otomatis juga akan dinonaktifkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await GoogleDriveService.signOut();
    setState(() {
      _isConnected = false;
      _hasLiveSession = false;
      _userEmail = null;
      _lastBackup = null;
      _schedule = BackupSchedule.none;
    });
  }

  Future<void> _backup() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });
    try {
      final result = await GoogleDriveService.backup();
      setState(() {
        _statusMessage = result.message;
        if (result.success) {
          _lastBackup = result.timestamp;
        }
      });
      if (result.success) {
        _loadLastBackupTime();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: result.success
                ? AppColors.income
                : AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restore() async {
    setState(() => _isLoading = true);
    List<DriveBackupInfo> snapshots = [];
    try {
      snapshots = await GoogleDriveService.getBackupList();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);

    if (!mounted) return;

    if (snapshots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada berkas backup yang ditemukan di Google Drive.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    String? selectedFileId;
    if (snapshots.length > 1) {
      final picked = await showModalBottomSheet<DriveBackupInfo>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => _SnapshotSelectionSheet(snapshots: snapshots),
      );
      if (picked == null) return;
      selectedFileId = picked.fileId;
    } else {
      selectedFileId = snapshots.first.fileId;
    }

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Data?'),
        content: const Text(
          'Data saat ini akan digantikan dengan data dari backup.\n\n'
          'Perlindungan Integritas Aktif: Snapshot keamanan dibuat otomatis sebelum pemulihan, dan akan di-rollback bila data korup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Pulihkan Sekarang'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });
    try {
      final result = await GoogleDriveService.restore(fileId: selectedFileId);
      if (result.success && mounted) {
        await Future.wait([
          context.read<TransactionProvider>().loadData(),
          context.read<WalletProvider>().loadWallets(),
          context.read<SavingsProvider>().loadGoals(),
          context.read<DebtProvider>().loadDebts(),
          context.read<RecurringProvider>().loadRecurringTransactions(),
          context.read<CustomCategoryProvider>().loadCategories(),
          context.read<SplitBillProvider>().loadBills(),
          context.read<TagProvider>().loadTags(),
          context.read<SubscriptionProvider>().loadSubscriptions(),
          context.read<AssetProvider>().loadAssets(),
          context.read<TemplateProvider>().loadTemplates(),
        ]);
        _loadLastBackupTime();
      }
      setState(() {
        _statusMessage = result.message;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: result.success
                ? AppColors.income
                : AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          // Google account section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_rounded,
                  size: 48,
                  color: isDark
                      ? AppColors.primaryDark
                      : AppColors.primaryLight,
                ),
                const SizedBox(height: 12),
                Text('Google Drive', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                if (_isConnected && _userEmail != null) ...[
                  Text(
                    _userEmail!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Session status indicator
                  if (_isRestoringSession)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: isDark
                                ? AppColors.primaryDark
                                : AppColors.primaryLight,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Memulihkan sesi...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _hasLiveSession
                              ? Icons.check_circle_outline_rounded
                              : Icons.sync_rounded,
                          size: 14,
                          color: _hasLiveSession
                              ? AppColors.income
                              : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _hasLiveSession
                              ? 'Terhubung'
                              : 'Sesi perlu diperbarui',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _hasLiveSession
                                ? AppColors.income
                                : Colors.orange,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Keluar Akun'),
                  ),
                ] else ...[
                  Text(
                    'Hubungkan akun Google untuk backup data keuanganmu ke cloud.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _signIn,
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Login dengan Google'),
                  ),
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.expense.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _statusMessage!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.expense,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
          const SizedBox(height: 20),

          if (_isConnected) ...[
            // 30-Day Stale Backup Warning
            if (_lastBackup != null && DateTime.now().difference(_lastBackup!).inDays >= 30)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber, width: 1.2),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber,
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Peringatan Cadangan Kadaluarsa',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sudah ${DateTime.now().difference(_lastBackup!).inDays} hari sejak backup terakhir. Amankan data keuanganmu sekarang.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),

            // Last backup info
            if (_lastBackup != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.income.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.income,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Backup terakhir',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Row(
                            children: [
                              Text(
                                _formatDate(_lastBackup!),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppColors.income,
                                  fontSize: 14,
                                ),
                              ),
                              if (_backupInfo != null && _backupInfo!.sizeBytes > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.income.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _backupInfo!.formattedSize,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.income,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
            const SizedBox(height: 20),

            // Backup schedule
            Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.schedule_rounded,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Jadwal Backup Otomatis',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 44),
                        child: Text(
                          'Backup berjalan otomatis saat membuka aplikasi.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      RadioGroup<BackupSchedule>(
                        groupValue: _schedule,
                        onChanged: (val) {
                          if (val != null) _changeSchedule(val);
                        },
                        child: Column(
                          children: [
                            _ScheduleOption(
                              title: 'Tidak Aktif',
                              subtitle: 'Backup manual saja',
                              icon: Icons.cancel_outlined,
                              value: BackupSchedule.none,
                              selected: _schedule == BackupSchedule.none,
                              onTap: () => _changeSchedule(BackupSchedule.none),
                              isDark: isDark,
                            ),
                            const SizedBox(height: 8),
                            _ScheduleOption(
                              title: 'Mingguan',
                              subtitle: 'Setiap 7 hari sekali',
                              icon: Icons.date_range_rounded,
                              value: BackupSchedule.weekly,
                              selected: _schedule == BackupSchedule.weekly,
                              onTap: () => _changeSchedule(BackupSchedule.weekly),
                              isDark: isDark,
                            ),
                            const SizedBox(height: 8),
                            _ScheduleOption(
                              title: 'Bulanan',
                              subtitle: 'Setiap 30 hari sekali',
                              icon: Icons.calendar_month_rounded,
                              value: BackupSchedule.monthly,
                              selected: _schedule == BackupSchedule.monthly,
                              onTap: () => _changeSchedule(BackupSchedule.monthly),
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: 120.ms, duration: 400.ms)
                .slideY(begin: 0.05, end: 0),
            const SizedBox(height: 20),

            // Backup button
            _ActionCard(
                  isDark: isDark,
                  icon: Icons.cloud_upload_rounded,
                  title: 'Backup Sekarang',
                  subtitle: 'Simpan data ke Google Drive',
                  color: isDark
                      ? AppColors.primaryDark
                      : AppColors.primaryLight,
                  isLoading: _isLoading,
                  onTap: _isLoading ? null : _backup,
                )
                .animate()
                .fadeIn(delay: 150.ms, duration: 400.ms)
                .slideY(begin: 0.05, end: 0),
            const SizedBox(height: 12),

            // Restore button
            _ActionCard(
                  isDark: isDark,
                  icon: Icons.cloud_download_rounded,
                  title: 'Restore Data',
                  subtitle: 'Pulihkan data dari Google Drive',
                  color: AppColors.expense,
                  isLoading: _isLoading,
                  onTap: _isLoading ? null : _restore,
                )
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms)
                .slideY(begin: 0.05, end: 0),

            // Offline Local Backup Section
            const SizedBox(height: 28),
            Text(
              'CADANGAN LOKAL & EKSPOR DATA',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            _ActionCard(
              isDark: isDark,
              icon: Icons.file_upload_outlined,
              title: 'Ekspor Cadangan Terkompresi',
              subtitle: 'Simpan file JSON (GZip) dengan proteksi password',
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              isLoading: _isLoading,
              onTap: _isLoading ? null : () => _exportOfflineBackup(context),
            )
                .animate()
                .fadeIn(delay: 220.ms, duration: 400.ms)
                .slideY(begin: 0.05, end: 0),
            const SizedBox(height: 12),
            _ActionCard(
              isDark: isDark,
              icon: Icons.storage_rounded,
              title: 'Ekspor Basis Data SQLite (.db)',
              subtitle: 'Salin file database biner langsung untuk backup mandiri',
              color: Colors.teal,
              isLoading: _isLoading,
              onTap: _isLoading ? null : () => _exportSqliteBackup(context),
            )
                .animate()
                .fadeIn(delay: 230.ms, duration: 400.ms)
                .slideY(begin: 0.05, end: 0),
            const SizedBox(height: 12),
            _ActionCard(
              isDark: isDark,
              icon: Icons.file_download_outlined,
              title: 'Impor Cadangan Offline',
              subtitle: 'Pulihkan data dari JSON dengan pratinjau data',
              color: Colors.orange,
              isLoading: _isLoading,
              onTap: _isLoading ? null : () => _importOfflineBackup(context),
            )
                .animate()
                .fadeIn(delay: 240.ms, duration: 400.ms)
                .slideY(begin: 0.05, end: 0),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _changeSchedule(BackupSchedule? newSchedule) async {
    if (newSchedule == null) return;
    await GoogleDriveService.setBackupSchedule(newSchedule);
    setState(() => _schedule = newSchedule);

    if (mounted) {
      final label = switch (newSchedule) {
        BackupSchedule.none => 'Backup otomatis dinonaktifkan',
        BackupSchedule.weekly => 'Backup otomatis setiap minggu',
        BackupSchedule.monthly => 'Backup otomatis setiap bulan',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(label),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _exportOfflineBackup(BuildContext context) async {
    final passwordController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ekspor Cadangan Terkompresi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'File cadangan akan dikompresi (GZip) untuk menghemat memori. Masukkan password enkripsi opsional:',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Password enkripsi (opsional)',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            ),
            child: const Text('Ekspor & Bagikan'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await LocalBackupService.exportAndShare(
          password: passwordController.text.trim().isEmpty ? null : passwordController.text.trim(),
          compress: true,
        );
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Gagal ekspor: $e')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportSqliteBackup(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);
    try {
      await LocalBackupService.exportDatabaseFile();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Gagal ekspor basis data: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _importOfflineBackup(BuildContext context) async {
    final jsonController = TextEditingController();
    final passwordController = TextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final txP = context.read<TransactionProvider>();
    final wP = context.read<WalletProvider>();
    final rP = context.read<RecurringProvider>();
    final sP = context.read<SavingsProvider>();
    final dP = context.read<DebtProvider>();
    final cP = context.read<CustomCategoryProvider>();
    final sbP = context.read<SplitBillProvider>();
    final tP = context.read<TagProvider>();
    final subP = context.read<SubscriptionProvider>();
    final aP = context.read<AssetProvider>();
    final tplP = context.read<TemplateProvider>();

    final inputConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Impor Cadangan Offline'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tempelkan teks JSON atau cipher cadangan:'),
              const SizedBox(height: 12),
              TextField(
                controller: jsonController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Paste teks JSON backup di sini...',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Password enkripsi (jika ada)',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Periksa Cadangan'),
          ),
        ],
      ),
    );

    if (inputConfirmed == true && jsonController.text.trim().isNotEmpty) {
      final rawText = jsonController.text.trim();
      final pwd = passwordController.text.trim().isEmpty ? null : passwordController.text.trim();

      setState(() => _isLoading = true);
      BackupPreviewInfo? preview;
      try {
        preview = await LocalBackupService.previewFromJsonString(rawText, password: pwd);
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Gagal membaca berkas: $e')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }

      if (preview == null) return;
      if (!context.mounted) return;

      // Show preview sheet before confirming overwrite
      final proceed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => _PreviewDataSheet(preview: preview!),
      );

      if (proceed != true) return;
      if (!context.mounted) return;

      setState(() => _isLoading = true);
      try {
        final success = await LocalBackupService.importFromJsonString(rawText, password: pwd);
        if (success) {
          await Future.wait([
            txP.loadData(),
            wP.loadWallets(),
            rP.loadRecurringTransactions(),
            sP.loadGoals(),
            dP.loadDebts(),
            cP.loadCategories(),
            sbP.loadBills(),
            tP.loadTags(),
            subP.loadSubscriptions(),
            aP.loadAssets(),
            tplP.loadTemplates(),
          ]);

          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Data berhasil dipulihkan dari cadangan offline! 🎉'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Gagal impor: $e')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}

class _SnapshotSelectionSheet extends StatelessWidget {
  final List<DriveBackupInfo> snapshots;

  const _SnapshotSelectionSheet({required this.snapshots});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.paddingOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.history_rounded, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Pilih Versi Cadangan Drive',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Pilih salah satu snapshot cadangan Google Drive untuk dipulihkan.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: snapshots.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (ctx, index) {
                final s = snapshots[index];
                final dateFormatted = '${s.modifiedTime.day}/${s.modifiedTime.month}/${s.modifiedTime.year} ${s.modifiedTime.hour.toString().padLeft(2, '0')}:${s.modifiedTime.minute.toString().padLeft(2, '0')}';
                return Material(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: index == 0
                          ? AppColors.income.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.15),
                      child: Icon(
                        index == 0 ? Icons.star_rounded : Icons.backup_rounded,
                        color: index == 0 ? AppColors.income : Colors.grey,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          dateFormatted,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        if (index == 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.income.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Terbaru',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.income,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      'Ukuran: ${s.formattedSize} • ${s.fileName}',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () => Navigator.pop(ctx, s),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewDataSheet extends StatelessWidget {
  final BackupPreviewInfo preview;

  const _PreviewDataSheet({required this.preview});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.paddingOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.preview_rounded, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Pratinjau Berkas Cadangan',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Periksa ringkasan data sebelum menimpa database lokal saat ini:',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _previewRow(context, 'Total Transaksi', '${preview.transactionCount} data', Icons.receipt_long_rounded),
                const Divider(height: 16),
                _previewRow(context, 'Jumlah Dompet', '${preview.walletCount} dompet', Icons.account_balance_wallet_rounded),
                const Divider(height: 16),
                _previewRow(context, 'Target Tabungan', '${preview.savingsGoalCount} target', Icons.savings_rounded),
                const Divider(height: 16),
                _previewRow(context, 'Catatan Utang/Piutang', '${preview.debtCount} data', Icons.handshake_rounded),
                const Divider(height: 16),
                _previewRow(context, 'Anggaran Bulanan', '${preview.budgetCount} kategori', Icons.pie_chart_rounded),
                const Divider(height: 16),
                _previewRow(context, 'Kompresi & Proteksi', '${preview.isCompressed ? "GZip" : "Plain"} • ${preview.isEncrypted ? "Terenkripsi" : "Publik"}', Icons.security_rounded),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
                  child: const Text('Lanjutkan Restore'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    : Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final BackupSchedule value;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _ScheduleOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Material(
      color: selected ? primary.withValues(alpha: 0.08) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: selected ? primary : Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 13,
                        color: selected ? primary : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Radio<BackupSchedule>(
                value: value,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
