import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:math';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static const String _remindersEnabledKey = 'reminders_enabled';

  Future<void> initialize() async {
    // Android settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher'
    );
    
    // Combined settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    // Initialize with callback handling
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestPermissions();
  }

  // Handle notification taps
  static void _onNotificationTapped(NotificationResponse notificationResponse) {
    // Handle notification tap if needed
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // Request notification permission (Android 13+)
        await androidImplementation.requestNotificationsPermission();
        // Request exact alarm permission
        await androidImplementation.requestExactAlarmsPermission();
      }
    }
  }

  Future<bool> areRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_remindersEnabledKey) ?? true;
  }

  Future<void> setRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_remindersEnabledKey, enabled);
  }

  int generateNotificationId() {
    return Random().nextInt(100000);
  }

  Future<void> scheduleTaskReminder({
    required int notificationId,
    required String taskContent,
    required DateTime scheduledTime,
  }) async {
    final remindersEnabled = await areRemindersEnabled();
    if (!remindersEnabled) return;

    final now = DateTime.now();
    if (scheduledTime.isBefore(now)) return;

    // Scheduling notification
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);

    // Create notification details
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for task reminders',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _notifications.zonedSchedule(
        notificationId,
        'Task Reminder',
        taskContent,
        scheduledDate,
        notificationDetails,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'task_reminder_$notificationId',
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<void> cancelNotification(int notificationId) async {
    await _notifications.cancel(notificationId);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Check permissions
  Future<bool> canScheduleExactAlarms() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        return await androidImplementation.canScheduleExactNotifications() ?? false;
      }
    }
    return false;
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        return await androidImplementation.areNotificationsEnabled() ?? false;
      }
    }
    return false;
  }
} 