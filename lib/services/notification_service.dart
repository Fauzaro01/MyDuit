import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import '../models/subscription_model.dart';
import '../models/debt_model.dart';
import '../utils/formatters.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'myduit_daily';
  static const _channelName = 'Pengingat Harian';
  static const _channelDesc = 'Pengingat untuk mencatat transaksi harian';

  static const _prefEnabled = 'notif_enabled';
  static const _prefHour = 'notif_hour';
  static const _prefMinute = 'notif_minute';

  /// Initialize notification system
  static Future<void> init() async {
    tzdata.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
  }

  /// Request notification permission (Android 13+)
  static Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  /// Check if notifications are enabled
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefEnabled) ?? false;
  }

  /// Get scheduled time
  static Future<TimeOfDay> getScheduledTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_prefHour) ?? 20; // default 8 PM
    final minute = prefs.getInt(_prefMinute) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Enable daily notification
  static Future<void> enable({int hour = 20, int minute = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabled, true);
    await prefs.setInt(_prefHour, hour);
    await prefs.setInt(_prefMinute, minute);
    await _scheduleDailyNotification(hour, minute);
  }

  /// Disable notifications
  static Future<void> disable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabled, false);
    await _plugin.cancelAll();
  }

  /// Update schedule time
  static Future<void> updateTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefHour, hour);
    await prefs.setInt(_prefMinute, minute);
    await _plugin.cancelAll();
    await _scheduleDailyNotification(hour, minute);
  }

  /// Reschedule if already enabled (call on app startup)
  static Future<void> rescheduleIfEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_prefEnabled) ?? false;
    if (enabled) {
      final hour = prefs.getInt(_prefHour) ?? 20;
      final minute = prefs.getInt(_prefMinute) ?? 0;
      await _scheduleDailyNotification(hour, minute);
    }
  }

  /// Schedule daily notification
  static Future<void> _scheduleDailyNotification(int hour, int minute) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final titles = [
      'Jangan lupa catat pengeluaranmu! 📝',
      'Sudah catat transaksi hari ini? 💰',
      'Yuk, update keuanganmu! 📊',
      'Waktunya catat pengeluaran harian! ✅',
      'MyDuit mengingatkanmu untuk catat transaksi! 💸',
    ];

    final bodies = [
      'Pencatatan rutin adalah kunci keuangan yang sehat.',
      'Catat sekarang sebelum lupa!',
      'Satu menit untuk kebiasaan finansial yang baik.',
      'Keuanganmu menunggu untuk diperbarui.',
      'Tetap konsisten mencatat keuanganmu!',
    ];

    final idx = DateTime.now().day % titles.length;

    await _plugin.zonedSchedule(
      id: 0,
      title: titles[idx],
      body: bodies[idx],
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Schedule upcoming subscription billing reminder
  static Future<void> scheduleSubscriptionReminder(SubscriptionModel sub) async {
    if (!sub.isActive) return;
    final notifId = 10000 + (sub.id.hashCode % 50000).abs();

    const androidDetails = AndroidNotificationDetails(
      'myduit_bills',
      'Pengingat Tagihan & Langganan',
      channelDescription: 'Pengingat tanggal jatuh tempo langganan dan tagihan',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final now = DateTime.now();
    DateTime nextDue = DateTime(now.year, now.month, sub.dueDay.clamp(1, 28));
    if (nextDue.isBefore(now)) {
      nextDue = DateTime(now.year, now.month + 1, sub.dueDay.clamp(1, 28));
    }
    final reminderDate = nextDue.subtract(Duration(days: sub.reminderDaysBefore));
    final scheduledDate = tz.TZDateTime(
      tz.local,
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      9,
      0,
    );

    if (scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
      await _plugin.zonedSchedule(
        id: notifId,
        title: 'Pengingat Langganan: ${sub.name} 🔔',
        body: 'Langganan ${sub.name} (${CurrencyFormatter.format(sub.amount)}) akan jatuh tempo dalam ${sub.reminderDaysBefore} hari.',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  /// Schedule upcoming debt due date reminder
  static Future<void> scheduleDebtReminder(DebtModel debt) async {
    if (debt.isSettled || debt.dueDate == null) return;
    final notifId = 60000 + (debt.id.hashCode % 30000).abs();

    const androidDetails = AndroidNotificationDetails(
      'myduit_debts',
      'Pengingat Hutang & Piutang',
      channelDescription: 'Pengingat jatuh tempo pembayaran hutang & piutang',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final due = debt.dueDate!;
    final reminderDate = due.subtract(const Duration(days: 1));
    final scheduledDate = tz.TZDateTime(
      tz.local,
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      9,
      0,
    );

    if (scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
      final isDebt = debt.type == DebtType.iOwe;
      final title = isDebt ? 'Pengingat Bayar Hutang 💳' : 'Pengingat Tagih Piutang 💰';
      final body = isDebt
          ? 'Hutang kepada ${debt.personName} (${CurrencyFormatter.format(debt.remainingAmount)}) jatuh tempo besok.'
          : 'Piutang dari ${debt.personName} (${CurrencyFormatter.format(debt.remainingAmount)}) jatuh tempo besok.';

      await _plugin.zonedSchedule(
        id: notifId,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
