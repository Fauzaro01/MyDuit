import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class AppLockProvider extends ChangeNotifier {
  static const _pinKey = 'app_lock_pin';
  static const _lockEnabledKey = 'app_lock_enabled';
  static const _fingerprintEnabledKey = 'fingerprint_enabled';
  static const _lockTimeoutKey = 'app_lock_timeout_seconds';
  static const _failedAttemptsKey = 'app_lock_failed_attempts';
  static const _lockoutUntilKey = 'app_lock_lockout_until';
  static const _securityQuestionKey = 'app_lock_security_question';
  static const _securityAnswerHashKey = 'app_lock_security_answer_hash';

  String? _pin;
  bool _isLockEnabled = false;
  bool _isUnlocked = false;
  bool _isFingerprintEnabled = false;
  bool _isFingerprintAvailable = false;
  int _lockTimeoutSeconds = 0; // 0 = Langsung
  DateTime? _pausedAt;
  bool _isAuthenticating = false;

  int _failedAttempts = 0;
  DateTime? _lockoutUntil;
  String? _securityQuestion;
  String? _securityAnswerHash;

  final LocalAuthentication _localAuth = LocalAuthentication();

  String _hashPin(String pin) => sha256.convert(utf8.encode(pin)).toString();

  // A legacy plaintext PIN is exactly 4 digits; a SHA-256 hash is 64 hex chars.
  bool _isLegacyPlaintext(String stored) =>
      stored.length == 4 && int.tryParse(stored) != null;

  bool get isLockEnabled => _isLockEnabled;
  bool get isUnlocked => _isUnlocked;
  bool get hasPin => _pin != null && _pin!.isNotEmpty;
  int get failedAttempts => _failedAttempts;
  bool get isLockedOut =>
      _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);
  int get remainingLockoutSeconds =>
      isLockedOut ? _lockoutUntil!.difference(DateTime.now()).inSeconds + 1 : 0;
  String? get securityQuestion => _securityQuestion;
  bool get hasSecurityQuestion =>
      _securityQuestion != null && _securityQuestion!.isNotEmpty;

  /// Derives a backup-encryption key from the app-lock PIN, domain-separated
  /// from the PIN's own stored form so the two don't share raw material.
  String? deriveBackupKey() {
    if (_pin == null) return null;
    return sha256.convert(utf8.encode('$_pin:myduit-backup')).toString();
  }

  bool get needsUnlock => _isLockEnabled && !_isUnlocked;
  bool get isFingerprintEnabled => _isFingerprintEnabled;
  bool get isFingerprintAvailable => _isFingerprintAvailable;
  int get lockTimeoutSeconds => _lockTimeoutSeconds;

  /// Fingerprint can be toggled only if PIN is set and biometric hardware exists
  bool get canEnableFingerprint => _isLockEnabled && _isFingerprintAvailable;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _pin = prefs.getString(_pinKey);
    if (_pin != null && _isLegacyPlaintext(_pin!)) {
      // Transparent one-time migration: hash a PIN stored in plaintext by
      // an older version of the app, in place.
      final hashed = _hashPin(_pin!);
      await prefs.setString(_pinKey, hashed);
      _pin = hashed;
    }
    _isLockEnabled = prefs.getBool(_lockEnabledKey) ?? false;
    _isFingerprintEnabled = prefs.getBool(_fingerprintEnabledKey) ?? false;
    _lockTimeoutSeconds = prefs.getInt(_lockTimeoutKey) ?? 0;
    _failedAttempts = prefs.getInt(_failedAttemptsKey) ?? 0;
    final lockoutMillis = prefs.getInt(_lockoutUntilKey);
    if (lockoutMillis != null) {
      _lockoutUntil = DateTime.fromMillisecondsSinceEpoch(lockoutMillis);
      if (DateTime.now().isAfter(_lockoutUntil!)) {
        _lockoutUntil = null;
      }
    }
    _securityQuestion = prefs.getString(_securityQuestionKey);
    _securityAnswerHash = prefs.getString(_securityAnswerHashKey);
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
    final hashed = _hashPin(newPin);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, hashed);
    await prefs.setBool(_lockEnabledKey, true);
    _pin = hashed;
    _isLockEnabled = true;
    _isUnlocked = true;
    _failedAttempts = 0;
    _lockoutUntil = null;
    await _persistLockoutState();
    notifyListeners();
    return true;
  }

  Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.setBool(_lockEnabledKey, false);
    await prefs.setBool(_fingerprintEnabledKey, false);
    await prefs.remove(_failedAttemptsKey);
    await prefs.remove(_lockoutUntilKey);
    await prefs.remove(_securityQuestionKey);
    await prefs.remove(_securityAnswerHashKey);
    _pin = null;
    _isLockEnabled = false;
    _isFingerprintEnabled = false;
    _isUnlocked = true;
    _failedAttempts = 0;
    _lockoutUntil = null;
    _securityQuestion = null;
    _securityAnswerHash = null;
    notifyListeners();
  }

  Future<void> setFingerprintEnabled(bool enabled) async {
    if (!_isFingerprintAvailable || !_isLockEnabled) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fingerprintEnabledKey, enabled);
    _isFingerprintEnabled = enabled;
    notifyListeners();
  }

  Future<void> setLockTimeout(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lockTimeoutKey, seconds);
    _lockTimeoutSeconds = seconds;
    notifyListeners();
  }

  void onAppPaused() {
    // The native biometric prompt itself briefly pauses the host app while it's
    // showing — that's not the user backgrounding the app, so don't re-arm the lock timer.
    if (_isAuthenticating) return;
    _pausedAt = DateTime.now();
  }

  void onAppResumed() {
    if (_isLockEnabled && _pausedAt != null) {
      final elapsed = DateTime.now().difference(_pausedAt!).inSeconds;
      if (elapsed >= _lockTimeoutSeconds) {
        lock();
      }
      _pausedAt = null;
    }
  }

  /// Authenticate using fingerprint / biometric — returns true if successful
  Future<bool> authenticateWithFingerprint() async {
    if (!_isFingerprintEnabled || !_isFingerprintAvailable) return false;
    _isAuthenticating = true;
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason:
            'Buka kunci MyDuit dengan Biometrik (Sidik Jari / Wajah)',
        biometricOnly: true,
      );
      if (authenticated) {
        _failedAttempts = 0;
        _lockoutUntil = null;
        await _persistLockoutState();
        _isUnlocked = true;
        notifyListeners();
      }
      return authenticated;
    } catch (e) {
      debugPrint('Fingerprint auth error: $e');
      return false;
    } finally {
      _isAuthenticating = false;
    }
  }

  bool verifyPin(String inputPin) {
    if (_pin == null) return false;
    if (isLockedOut) return false;

    final isCorrect = _hashPin(inputPin) == _pin;
    if (isCorrect) {
      _failedAttempts = 0;
      _lockoutUntil = null;
      _persistLockoutState();
      _isUnlocked = true;
      notifyListeners();
      return true;
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 10) {
        _lockoutUntil = DateTime.now().add(const Duration(seconds: 300));
      } else if (_failedAttempts >= 8) {
        _lockoutUntil = DateTime.now().add(const Duration(seconds: 120));
      } else if (_failedAttempts >= 5) {
        _lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
      }
      _persistLockoutState();
      notifyListeners();
      return false;
    }
  }

  Future<void> _persistLockoutState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_failedAttemptsKey, _failedAttempts);
    if (_lockoutUntil != null) {
      await prefs.setInt(
        _lockoutUntilKey,
        _lockoutUntil!.millisecondsSinceEpoch,
      );
    } else {
      await prefs.remove(_lockoutUntilKey);
    }
  }

  Future<void> setSecurityQuestion({
    required String question,
    required String answer,
  }) async {
    final cleanQ = question.trim();
    final cleanA = answer.trim().toLowerCase();
    if (cleanQ.isEmpty || cleanA.isEmpty) return;

    final hash = sha256.convert(utf8.encode(cleanA)).toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_securityQuestionKey, cleanQ);
    await prefs.setString(_securityAnswerHashKey, hash);
    _securityQuestion = cleanQ;
    _securityAnswerHash = hash;
    notifyListeners();
  }

  bool verifySecurityAnswer(String answer) {
    if (_securityAnswerHash == null) return false;
    final cleanA = answer.trim().toLowerCase();
    final hash = sha256.convert(utf8.encode(cleanA)).toString();
    final matches = hash == _securityAnswerHash;
    if (matches) {
      _failedAttempts = 0;
      _lockoutUntil = null;
      _persistLockoutState();
      notifyListeners();
    }
    return matches;
  }

  Future<bool> resetPinWithSecurityAnswer({
    required String answer,
    required String newPin,
  }) async {
    if (!verifySecurityAnswer(answer)) return false;
    return await setPin(newPin);
  }

  void resetLockout() {
    _failedAttempts = 0;
    _lockoutUntil = null;
    _persistLockoutState();
    notifyListeners();
  }

  void lock() {
    if (_isLockEnabled) {
      _isUnlocked = false;
      _pausedAt = null;
      notifyListeners();
    }
  }

  Future<bool> changePin(String oldPin, String newPin) async {
    if (!verifyPin(oldPin)) return false;
    return await setPin(newPin);
  }
}
