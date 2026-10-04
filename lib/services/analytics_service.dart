import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static bool _initialized = false;

  /// Enable collection — must be called once after Firebase.initializeApp().
  static Future<void> init() async {
    if (_initialized) return;
    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
      _initialized = true;
    } catch (e) {
      debugPrint('AnalyticsService init error: $e');
    }
  }

  static Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e) {
      debugPrint('AnalyticsService logScreenView error: $e');
    }
  }

  static Future<void> logTransactionAdded({required String type}) async {
    try {
      await _analytics.logEvent(
        name: 'transaction_added',
        parameters: {'type': type},
      );
    } catch (e) {
      debugPrint('AnalyticsService logTransactionAdded error: $e');
    }
  }

  static Future<void> logWalletAdded() async {
    try {
      await _analytics.logEvent(name: 'wallet_added');
    } catch (e) {
      debugPrint('AnalyticsService logWalletAdded error: $e');
    }
  }

  static Future<void> logBackupToDrive() async {
    try {
      await _analytics.logEvent(name: 'backup_to_drive');
    } catch (e) {
      debugPrint('AnalyticsService logBackupToDrive error: $e');
    }
  }
}
