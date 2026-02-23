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

class _PinLockScreenState extends State<PinLockScreen> {
  String _pin = '';
  String? _confirmPin;
  String _statusText = '';
  bool _isError = false;
  bool _isConfirmStage = false;

  @override
  void initState() {
    super.initState();
    _statusText = widget.isSetup ? 'Buat PIN baru (4 digit)' : 'Masukkan PIN';
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
        // First entry — go to confirm
        setState(() {
          _confirmPin = _pin;
          _pin = '';
          _isConfirmStage = true;
          _statusText = 'Konfirmasi PIN';
        });
      } else {
        // Confirm
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
      // Verify
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

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Lock icon
            Icon(
                  Icons.lock_rounded,
                  size: 56,
                  color: isDark
                      ? AppColors.primaryDark
                      : AppColors.primaryLight,
                )
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
                        ? (_isError
                              ? AppColors.expense
                              : (isDark
                                    ? AppColors.primaryDark
                                    : AppColors.primaryLight))
                        : Colors.transparent,
                    border: Border.all(
                      color: _isError
                          ? AppColors.expense
                          : (isDark
                                ? AppColors.primaryDark
                                : AppColors.primaryLight),
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            const Spacer(flex: 1),

            // Numpad
            _NumPad(onDigit: _onDigit, onDelete: _onDelete, isDark: isDark),

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

  const _NumPad({
    required this.onDigit,
    required this.onDelete,
    required this.isDark,
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
            const SizedBox(width: 80),
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
