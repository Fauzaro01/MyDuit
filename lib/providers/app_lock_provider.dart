import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockProvider extends ChangeNotifier {
  static const _pinKey = 'app_lock_pin';
  static const _lockEnabledKey = 'app_lock_enabled';

  String? _pin;
  bool _isLockEnabled = false;
  bool _isUnlocked = false;

  bool get isLockEnabled => _isLockEnabled;
  bool get isUnlocked => _isUnlocked;
  bool get hasPin => _pin != null && _pin!.isNotEmpty;
  bool get needsUnlock => _isLockEnabled && !_isUnlocked;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _pin = prefs.getString(_pinKey);
    _isLockEnabled = prefs.getBool(_lockEnabledKey) ?? false;
    _isUnlocked = !_isLockEnabled; // Auto-unlock if lock is disabled
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
    _pin = null;
    _isLockEnabled = false;
    _isUnlocked = true;
    notifyListeners();
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
