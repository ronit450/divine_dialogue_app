import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    _initialized = true;
  }

  // Returns true if notification permission was granted.
  Future<bool> requestPermission() async {
    if (!_initialized) await init();
    if (Platform.isIOS) {
      final impl = _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      return await impl?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    if (Platform.isAndroid) {
      final impl = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      // Android 12+ requires runtime grant for exact alarms (Settings > Alarms & Reminders)
      final canExact = await impl?.canScheduleExactNotifications() ?? true;
      if (!canExact) {
        await impl?.requestExactAlarmsPermission();
      }
      return await impl?.requestNotificationsPermission() ?? true;
    }
    return true;
  }

  Future<void> schedulePlanReminder({
    required String planId,
    required String textTitle,
    required int hour,
    required int minute,
    int dayNumber = 1,
    int? durationDays,
    int unitsPerDay = 1,
    String unitLabel = 'page',
    int estimatedMins = 5,
  }) async {
    if (!_initialized) await init();

    final body = durationDays != null
        ? 'Day $dayNumber of $durationDays · $unitsPerDay $unitLabel, ≈$estimatedMins min today.'
        : 'Day $dayNumber · $unitsPerDay $unitLabel, ≈$estimatedMins min today.';

    const androidDetails = AndroidNotificationDetails(
      'divine_reading_reminders',
      'Reading Reminders',
      channelDescription: 'Daily reminders for your reading plan',
      importance: Importance.high,
      priority: Priority.defaultPriority,
      icon: '@drawable/ic_notification',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );
    const iosDetails = DarwinNotificationDetails(
      badgeNumber: 1,
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    // Use exact alarms only if permission is granted; fall back to inexact
    // (fires within a few minutes) so scheduling always succeeds.
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final canExact = Platform.isAndroid
        ? await androidImpl?.canScheduleExactNotifications() ?? false
        : true;

    Future<void> schedule(AndroidScheduleMode mode) => _plugin.zonedSchedule(
          _idFor(planId),
          'A few minutes with $textTitle?',
          body,
          _nextOccurrenceOf(hour, minute),
          details,
          androidScheduleMode: mode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );

    if (canExact) {
      try {
        await schedule(AndroidScheduleMode.exactAllowWhileIdle);
      } catch (_) {
        await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
      }
    } else {
      await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<void> cancelPlanReminder(String planId) async {
    if (!_initialized) await init();
    await _plugin.cancel(_idFor(planId));
  }

  int _idFor(String planId) => planId.hashCode.abs() % 100000;

  // Converts local wall-clock time to a UTC TZDateTime (preserving the
  // device's UTC offset), so matchDateTimeComponents repeats at the
  // correct local time each day regardless of IANA name lookup.
  tz.TZDateTime _nextOccurrenceOf(int hour, int minute) {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    if (next.isBefore(now)) next = next.add(const Duration(days: 1));
    return tz.TZDateTime.from(next, tz.UTC);
  }
}
