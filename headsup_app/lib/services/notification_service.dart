/// Notification service for daily reminders
library;

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  
  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;
  
  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Initialize timezone
    tz.initializeTimeZones();
    
    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    // Android settings (for future)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const initSettings = InitializationSettings(
      iOS: iosSettings,
      android: androidSettings,
    );
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    _initialized = true;
  }
  
  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    // App will open when notification is tapped
    // Could add deep linking here in the future
  }
  
  /// Request notification permissions
  Future<bool> requestPermissions() async {
    final iOS = _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    
    if (iOS != null) {
      final granted = await iOS.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return false;
  }
  
  /// Schedule daily reminder notification
  Future<void> scheduleDailyReminder({
    required TimeOfDay time,
    String title = 'Time to check your posture!',
    String body = 'Start your HeadsUp session and keep your posture healthy.',
  }) async {
    await _notifications.cancelAll(); // Clear existing reminders
    
    // Calculate next occurrence of the scheduled time
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    
    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
    
    // iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Daily Reminders',
      channelDescription: 'Daily posture tracking reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const notificationDetails = NotificationDetails(
      iOS: iosDetails,
      android: androidDetails,
    );
    
    await _notifications.zonedSchedule(
      0, // Notification ID
      title,
      body,
      tzScheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );
    
    // Save reminder settings
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminderEnabled', true);
    await prefs.setInt('reminderHour', time.hour);
    await prefs.setInt('reminderMinute', time.minute);
  }
  
  /// Cancel all scheduled reminders
  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminderEnabled', false);
  }
  
  /// Check if reminders are enabled and schedule if needed
  Future<void> restoreRemindersFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('reminderEnabled') ?? false;
    
    if (enabled) {
      final hour = prefs.getInt('reminderHour') ?? 9;
      final minute = prefs.getInt('reminderMinute') ?? 0;
      
      await scheduleDailyReminder(
        time: TimeOfDay(hour: hour, minute: minute),
      );
    }
  }
  
  /// Show immediate notification (for testing)
  Future<void> showTestNotification() async {
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const androidDetails = AndroidNotificationDetails(
      'test',
      'Test Notifications',
      channelDescription: 'Test notifications for debugging',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const notificationDetails = NotificationDetails(
      iOS: iosDetails,
      android: androidDetails,
    );
    
    await _notifications.show(
      999,
      'HeadsUp Test',
      'Notifications are working!',
      notificationDetails,
    );
  }
}
