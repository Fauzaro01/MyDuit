import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../services/google_drive_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isSignedIn = false;
  bool _isLoading = false;
  String? _statusMessage;
  DateTime? _lastBackup;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _checkSignIn();
  }

  Future<void> _checkSignIn() async {
    final signedIn = await GoogleDriveService.isSignedIn();
    setState(() {
      _isSignedIn = signedIn;
      _userEmail = GoogleDriveService.userEmail;
    });
    if (signedIn) {
      _loadLastBackupTime();
    }
  }

  Future<void> _loadLastBackupTime() async {
    final time = await GoogleDriveService.getLastBackupTime();
    if (mounted) {
      setState(() => _lastBackup = time);
    }
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    final success = await GoogleDriveService.signIn();
    setState(() {
      _isSignedIn = success;
      _isLoading = false;
      _userEmail = GoogleDriveService.userEmail;
    });
    if (success) {
      _loadLastBackupTime();
    }
  }

  Future<void> _signOut() async {
    await GoogleDriveService.signOut();
    setState(() {
      _isSignedIn = false;
      _userEmail = null;
      _lastBackup = null;
    });
  }

  Future<void> _backup() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });
    final result = await GoogleDriveService.backup();
    setState(() {
      _isLoading = false;
      _statusMessage = result.message;
      if (result.success) {
        _lastBackup = result.timestamp;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: result.success ? AppColors.income : AppColors.expense,
        ),
      );
    }
  }

  Future<void> _restore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Data?'),
        content: const Text(
          'Data saat ini akan digantikan dengan data dari backup. '
          'Pastikan kamu sudah backup data terbaru.\n\n'
          'Aplikasi perlu di-restart setelah restore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });
    final result = await GoogleDriveService.restore();
    setState(() {
      _isLoading = false;
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
          backgroundColor: result.success ? AppColors.income : AppColors.expense,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(20),
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
                    Text(
                      'Google Drive',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (_isSignedIn && _userEmail != null) ...[
                      Text(
                        _userEmail!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _signOut,
                        child: const Text('Keluar Akun'),
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
                    ],
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.05, end: 0),
          const SizedBox(height: 20),

          if (_isSignedIn) ...[
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
                              Text(
                                _formatDate(_lastBackup!),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppColors.income,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 400.ms),
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

            if (_statusMessage != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardAltLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
                      style:
                          theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                    ),
                    Text(
                      subtitle,
                      style:
                          theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
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
