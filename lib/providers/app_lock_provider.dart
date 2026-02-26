import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

class AppLockProvider extends ChangeNotifier {
  static const _pinKey = 'app_lock_pin';
  static const _lockEnabledKey = 'app_lock_enabled';
  static const _fingerprintEnabledKey = 'fingerprint_enabled';

  String? _pin;
  bool _isLockEnabled = false;
  bool _isUnlocked = false;
  bool _isFingerprintEnabled = false;
  bool _isFingerprintAvailable = false;

  final LocalAuthentication _localAuth = LocalAuthentication();

  bool get isLockEnabled => _isLockEnabled;
  bool get isUnlocked => _isUnlocked;
  bool get hasPin => _pin != null && _pin!.isNotEmpty;
  bool get needsUnlock => _isLockEnabled && !_isUnlocked;
  bool get isFingerprintEnabled => _isFingerprintEnabled;
  bool get isFingerprintAvailable => _isFingerprintAvailable;

  /// Fingerprint can be toggled only if PIN is set and biometric hardware exists
  bool get canEnableFingerprint => _isLockEnabled && _isFingerprintAvailable;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _pin = prefs.getString(_pinKey);
    _isLockEnabled = prefs.getBool(_lockEnabledKey) ?? false;
    _isFingerprintEnabled = prefs.getBool(_fingerprintEnabledKey) ?? false;
    _isUnlocked = !_isLockEnabled; // Auto-unlock if lock is disabled

    // Check biometric availability
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      _isFingerprintAvailable = canCheck && isDeviceSupported;

      if (_isFingerprintAvailable) {
        final biometrics = await _localAuth.getAvailableBiometrics();
        _isFingerprintAvailable =
            biometrics.contains(BiometricType.fingerprint) ||
            biometrics.contains(BiometricType.strong) ||
            biometrics.contains(BiometricType.weak);
      }
    } catch (_) {
      _isFingerprintAvailable = false;
    }

    // Disable fingerprint if hardware not available
    if (!_isFingerprintAvailable) {
      _isFingerprintEnabled = false;
    }

    notifyListeners();
  }

  Future<bool> setPin(String newPin) async {
    if (newPin.length != 4) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, newPin);
    await prefs.setBool(_lockEnabledKey, true);
    _pin = newPin;
    _isLockEnabled = true;
    _isUnlocked = true;
    notifyListeners();
    return true;
  }

  Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.setBool(_lockEnabledKey, false);
    await prefs.setBool(_fingerprintEnabledKey, false);
    _pin = null;
    _isLockEnabled = false;
    _isFingerprintEnabled = false;
    _isUnlocked = true;
    notifyListeners();
  }

  Future<void> setFingerprintEnabled(bool enabled) async {
    if (!_isFingerprintAvailable || !_isLockEnabled) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fingerprintEnabledKey, enabled);
    _isFingerprintEnabled = enabled;
    notifyListeners();
  }

  /// Authenticate using fingerprint — returns true if successful
  Future<bool> authenticateWithFingerprint() async {
    if (!_isFingerprintEnabled || !_isFingerprintAvailable) return false;
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Buka kunci MyDuit dengan sidik jari',
        biometricOnly: true,
        sensitiveTransaction: false,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'MyDuit',
            signInHint: 'Sentuh sensor sidik jari',
            cancelButton: 'Gunakan PIN',
          ),
        ],
      );
      if (authenticated) {
        _isUnlocked = true;
        notifyListeners();
      }
      return authenticated;
    } catch (e) {
      debugPrint('Fingerprint auth error: $e');
      return false;
    }
  }

  bool verifyPin(String inputPin) {
    if (_pin == null) return false;
    final isCorrect = inputPin == _pin;
    if (isCorrect) {
      _isUnlocked = true;
      notifyListeners();
    }
    return isCorrect;
  }

  void lock() {
    if (_isLockEnabled) {
      _isUnlocked = false;
      notifyListeners();
    }
  }

  Future<bool> changePin(String oldPin, String newPin) async {
    if (!verifyPin(oldPin)) return false;
    return await setPin(newPin);
  }
}
