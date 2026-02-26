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
        _tryFingerprintAuth();
      });
    }
  }

  @override
  void dispose() {
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

  void _onPinComplete() {
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
          context.read<AppLockProvider>().setPin(_pin);
          Navigator.pop(context, true);
          _showSnack('PIN berhasil diatur 🔒');
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
      if (provider.verifyPin(_pin)) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _pin = '';
          _isError = true;
          _statusText = 'PIN salah, coba lagi';
        });
      }
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

            const SizedBox(height: 40),
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
