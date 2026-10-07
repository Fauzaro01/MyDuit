import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashService {
  static bool _initialized = false;

  /// Enable collection — must be called once after Firebase.initializeApp().
  static Future<void> init() async {
    if (_initialized) return;
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      );
      _initialized = true;
    } catch (e) {
      debugPrint('CrashService init error: $e');
    }
  }

  static Future<void> recordFlutterError(FlutterErrorDetails details) async {
    try {
      await FirebaseCrashlytics.instance.recordFlutterError(details);
    } catch (e) {
      debugPrint('CrashService recordFlutterError error: $e');
    }
  }

  static Future<void> recordError(Object error, StackTrace? stack) async {
    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        fatal: true,
      );
    } catch (e) {
      debugPrint('CrashService recordError error: $e');
    }
  }
}
