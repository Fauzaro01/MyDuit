import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../providers/app_lock_provider.dart';

class PinLockScreen extends StatefulWidget {
  final bool isSetup;
  const PinLockScreen({super.key, this.isSetup = false});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen>
    with TickerProviderStateMixin {
  String _pin = '';
  String? _confirmPin;
  String _statusText = '';
  bool _isError = false;
  bool _isConfirmStage = false;
  bool _isFingerprintAuthenticating = false;
  Timer? _lockoutTimer;

  late AnimationController _fingerprintPulseController;
  late Animation<double> _fingerprintPulseAnimation;

  @override
  void initState() {
    super.initState();
    _statusText = widget.isSetup ? 'Buat PIN baru (4 digit)' : 'Masukkan PIN';

    _fingerprintPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fingerprintPulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _fingerprintPulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Auto-trigger fingerprint if enabled and not in setup mode
    if (!widget.isSetup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkInitialLockout();
        _tryFingerprintAuth();
      });
    }
  }

  void _checkInitialLockout() {
    final provider = context.read<AppLockProvider>();
    if (provider.isLockedOut) {
      setState(() {
        _isError = true;
        _statusText = 'Terkunci. Tunggu ${provider.remainingLockoutSeconds} detik';
      });
      _ensureLockoutTimer();
    }
  }

  void _ensureLockoutTimer() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final provider = context.read<AppLockProvider>();
      if (!provider.isLockedOut) {
        timer.cancel();
        setState(() {
          _isError = false;
          _statusText = 'Masukkan PIN';
        });
      } else {
        setState(() {
          _isError = true;
          _statusText = 'Terkunci. Tunggu ${provider.remainingLockoutSeconds} detik';
        });
      }
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _fingerprintPulseController.dispose();
    super.dispose();
  }

  Future<void> _tryFingerprintAuth() async {
    final provider = context.read<AppLockProvider>();
    if (!provider.isFingerprintEnabled || widget.isSetup) return;

    setState(() => _isFingerprintAuthenticating = true);

    final success = await provider.authenticateWithFingerprint();

    if (mounted) {
      setState(() => _isFingerprintAuthenticating = false);
      if (success) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context, true);
      }
    }
  }

  void _onDigit(String digit) {
    final lockProvider = context.read<AppLockProvider>();
    if (!widget.isSetup && lockProvider.isLockedOut) return;
    if (_pin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin += digit;
      _isError = false;
    });

    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 200), _onPinComplete);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _isError = false;
    });
  }

  Future<void> _onPinComplete() async {
    if (widget.isSetup) {
      if (!_isConfirmStage) {
        setState(() {
          _confirmPin = _pin;
          _pin = '';
          _isConfirmStage = true;
          _statusText = 'Konfirmasi PIN';
        });
      } else {
        if (_pin == _confirmPin) {
          final chosenPin = _pin;
          await context.read<AppLockProvider>().setPin(chosenPin);
          if (mounted) {
            await _promptSetupSecurityQuestion(context);
            if (mounted) {
              Navigator.pop(context, true);
              _showSnack('PIN berhasil diatur 🔒');
            }
          }
        } else {
          setState(() {
            _pin = '';
            _isError = true;
            _statusText = 'PIN tidak cocok, coba lagi';
            _isConfirmStage = false;
            _confirmPin = null;
          });
        }
      }
    } else {
      final provider = context.read<AppLockProvider>();
      if (provider.isLockedOut) {
        setState(() {
          _pin = '';
          _isError = true;
          _statusText = 'Terkunci. Tunggu ${provider.remainingLockoutSeconds} detik';
        });
        _ensureLockoutTimer();
        return;
      }

      if (provider.verifyPin(_pin)) {
        _lockoutTimer?.cancel();
        Navigator.pop(context, true);
      } else {
        setState(() {
          _pin = '';
          _isError = true;
          if (provider.isLockedOut) {
            _statusText = 'Terkunci. Tunggu ${provider.remainingLockoutSeconds} detik';
            _ensureLockoutTimer();
          } else {
            _statusText = 'PIN salah (percobaan ${provider.failedAttempts})';
          }
        });
      }
    }
  }

  Future<void> _promptSetupSecurityQuestion(BuildContext context) async {
    final provider = context.read<AppLockProvider>();
    if (provider.hasSecurityQuestion) return;

    final questions = [
      'Apa nama hewan peliharaan pertamamu?',
      'Di kota mana kamu dilahirkan?',
      'Apa makanan favorit masa kecilmu?',
      'Apa nama sekolah dasar pertamamu?',
    ];
    String selectedQuestion = questions.first;
    final answerController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Pertanyaan Pemulihan (Opsional)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Atur pertanyaan keamanan agar kamu dapat memulihkan akses jika lupa PIN.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedQuestion,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Pertanyaan',
                    border: OutlineInputBorder(),
                  ),
                  items: questions
                      .map((q) => DropdownMenuItem(
                            value: q,
                            child: Text(q, style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedQuestion = val);
                    }
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: answerController,
                  decoration: const InputDecoration(
                    labelText: 'Jawaban Kamu',
                    hintText: 'Jawaban pemulihan...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Lewati'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (answerController.text.trim().isNotEmpty) {
                  await provider.setSecurityQuestion(
                    question: selectedQuestion,
                    answer: answerController.text.trim(),
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onForgotPin(BuildContext context) async {
    final provider = context.read<AppLockProvider>();
    if (provider.hasSecurityQuestion) {
      final answerCtrl = TextEditingController();
      final newPinCtrl = TextEditingController();
      bool isAnswerVerified = false;

      await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Pemulihan PIN'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isAnswerVerified) ...[
                    const Text('Jawab pertanyaan keamanan di bawah ini untuk mengatur ulang PIN:'),
                    const SizedBox(height: 12),
                    Text(
                      provider.securityQuestion!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: answerCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Jawaban',
                        hintText: 'Ketik jawabanmu...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ] else ...[
                    const Text('Jawaban benar! Masukkan 4 digit PIN baru:'),
                    const SizedBox(height: 14),
                    TextField(
                      controller: newPinCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        labelText: 'PIN Baru (4 Digit)',
                        hintText: '1234',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              if (!isAnswerVerified)
                ElevatedButton(
                  onPressed: () {
                    if (provider.verifySecurityAnswer(answerCtrl.text)) {
                      setDialogState(() => isAnswerVerified = true);
                    } else {
                      _showSnack('Jawaban salah, coba lagi');
                    }
                  },
                  child: const Text('Verifikasi'),
                )
              else
                ElevatedButton(
                  onPressed: () async {
                    if (newPinCtrl.text.length == 4) {
                      await provider.setPin(newPinCtrl.text);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        _showSnack('PIN baru berhasil disimpan 🔓');
                      }
                    } else {
                      _showSnack('PIN harus 4 digit angka');
                    }
                  },
                  child: const Text('Simpan PIN Baru'),
                ),
            ],
          ),
        ),
      );
    } else {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Lupa PIN'),
          content: Text(
            provider.isFingerprintEnabled
                ? 'Pertanyaan keamanan belum diatur. Silakan gunakan sidik jari untuk membuka aplikasi.'
                : 'Pertanyaan keamanan belum diatur. Untuk keamanan data Anda, silakan hubungi dukungan.',
          ),
          actions: [
            if (provider.isFingerprintEnabled)
              ElevatedButton.icon(
                icon: const Icon(Icons.fingerprint_rounded),
                label: const Text('Gunakan Sidik Jari'),
                onPressed: () {
                  Navigator.pop(ctx);
                  _tryFingerprintAuth();
                },
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lockProvider = context.watch<AppLockProvider>();
    final showFingerprint =
        !widget.isSetup && lockProvider.isFingerprintEnabled;
    final accentColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Lock icon
            Icon(Icons.lock_rounded, size: 56, color: accentColor)
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1)),

            const SizedBox(height: 24),

            // Status text
            Text(
              _statusText,
              style: theme.textTheme.titleMedium?.copyWith(
                color: _isError ? AppColors.expense : null,
              ),
            ).animate(key: ValueKey(_statusText)).fadeIn(duration: 300.ms),

            const SizedBox(height: 32),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _pin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? (_isError ? AppColors.expense : accentColor)
                        : Colors.transparent,
                    border: Border.all(
                      color: _isError ? AppColors.expense : accentColor,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            const Spacer(flex: 1),

            // Numpad
            _NumPad(
              onDigit: _onDigit,
              onDelete: _onDelete,
              isDark: isDark,
              showFingerprint: showFingerprint,
              onFingerprint: _tryFingerprintAuth,
              isFingerprintAuthenticating: _isFingerprintAuthenticating,
              fingerprintPulseAnimation: _fingerprintPulseAnimation,
              accentColor: accentColor,
            ),

            if (!widget.isSetup) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _onForgotPin(context),
                child: Text(
                  'Lupa PIN?',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _NumPad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;
  final bool isDark;
  final bool showFingerprint;
  final VoidCallback onFingerprint;
  final bool isFingerprintAuthenticating;
  final Animation<double> fingerprintPulseAnimation;
  final Color accentColor;

  const _NumPad({
    required this.onDigit,
    required this.onDelete,
    required this.isDark,
    required this.showFingerprint,
    required this.onFingerprint,
    required this.isFingerprintAuthenticating,
    required this.fingerprintPulseAnimation,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['1', '2', '3'].map((d) => _numButton(d, context)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['4', '5', '6'].map((d) => _numButton(d, context)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['7', '8', '9'].map((d) => _numButton(d, context)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Fingerprint button or empty space
            showFingerprint
                ? _fingerprintButton(context)
                : const SizedBox(width: 80),
            _numButton('0', context),
            SizedBox(
              width: 80,
              height: 64,
              child: IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.backspace_outlined, size: 24),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _fingerprintButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: 64,
        height: 64,
        child: AnimatedBuilder(
          animation: fingerprintPulseAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(
                      alpha: 0.3 * fingerprintPulseAnimation.value,
                    ),
                    blurRadius: 12 * fingerprintPulseAnimation.value,
                    spreadRadius: 2 * fingerprintPulseAnimation.value,
                  ),
                ],
              ),
              child: Material(
                color: accentColor.withValues(alpha: 0.12),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: isFingerprintAuthenticating ? null : onFingerprint,
                  customBorder: const CircleBorder(),
                  child: Center(
                    child: isFingerprintAuthenticating
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: accentColor,
                            ),
                          )
                        : Icon(
                            Icons.fingerprint_rounded,
                            size: 32,
                            color: accentColor,
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _numButton(String digit, BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        width: 64,
        height: 64,
        child: Material(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(32),
          child: InkWell(
            onTap: () => onDigit(digit),
            borderRadius: BorderRadius.circular(32),
            child: Center(
              child: Text(
                digit,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
