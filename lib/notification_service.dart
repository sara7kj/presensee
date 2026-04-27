import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// ═══════════════════════════════════════════════════════════════
///  NotificationService — Local notifications service
///
///  Uses flutter_local_notifications to schedule a local reminder
///  notification X hours after check-in (training end reminder).
///
///  Usage:
///   - Call `NotificationService.init()` once in main()
///   - Call `NotificationService.scheduleTrainingEndReminder()`
///     when the user checks in
///   - Call `NotificationService.cancelTrainingReminder()`
///     when the user checks out
/// ═══════════════════════════════════════════════════════════════

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _trainingReminderId = 1001;

  /// Required training duration (6 hours)
  /// Change to test with a short duration:
  /// e.g., Duration(minutes: 1)
  static const Duration trainingDuration = Duration(minutes: 1);

  // ────────────────────────────────────────────────────────────
  //  Initialize notifications (called once from main())
  // ────────────────────────────────────────────────────────────
  static Future<void> init() async {
    // Android settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    // Request notification permission (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ────────────────────────────────────────────────────────────
  //  Schedule the training end reminder
  //  Call this after a successful check-in
  // ────────────────────────────────────────────────────────────
  static Future<void> scheduleTrainingEndReminder({
    required DateTime checkInTime,
  }) async {
    // Notification time = check-in time + duration
    final notifyTime = checkInTime.add(trainingDuration);
    final delay = notifyTime.difference(DateTime.now());

    // If the time has passed (e.g., app opened 7 hours later), don't schedule
    if (delay.isNegative) return;

    // Cancel any old reminder before scheduling a new one
    await cancelTrainingReminder();

    const androidDetails = AndroidNotificationDetails(
      'training_reminder_channel',
      'Training Reminders',
      channelDescription: 'Reminder when training time ends',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use Future.delayed to fire the notification after the duration
    // (simple approach that works while the app is open)
    Future.delayed(delay, () async {
      await _plugin.show(
        _trainingReminderId,
        'Training Time Ended',
        'Your required training hours are complete. Please check out.',
        details,
      );
    });
  }

  // ────────────────────────────────────────────────────────────
  //  Show an instant notification (for testing)
  // ────────────────────────────────────────────────────────────
  static Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'instant_channel',
      'Instant Notifications',
      channelDescription: 'Instant notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(0, title, body, details);
  }

  // ────────────────────────────────────────────────────────────
  //  Cancel the training reminder
  //  (when user checks out before training ends)
  // ────────────────────────────────────────────────────────────
  static Future<void> cancelTrainingReminder() async {
    await _plugin.cancel(_trainingReminderId);
  }

  // ────────────────────────────────────────────────────────────
  //  Cancel all notifications
  // ────────────────────────────────────────────────────────────
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}