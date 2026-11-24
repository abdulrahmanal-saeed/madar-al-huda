import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/reminder_plan.dart';

/// Shows reminders through the platform. The default does nothing, so
/// tests and unsupported platforms never touch the plugin; `main` installs
/// [LocalReminderScheduler] on Android.
final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (_) => const NoopReminderScheduler(),
);

/// Whether the user allowed what reminders need.
typedef ReminderPermissions = ({bool notifications, bool exactAlarms});

abstract interface class ReminderScheduler {
  /// Connects taps on reminders to [onOpen] and returns the route of the
  /// reminder that launched the app, if any.
  Future<String?> start(void Function(String route) onOpen);

  Future<ReminderPermissions> permissions();

  /// Asks for notification permission; returns whether it is granted.
  Future<bool> requestNotifications();

  /// Opens the system page for exact alarms; returns whether it is granted.
  Future<bool> requestExactAlarms();

  /// Replaces every scheduled reminder with [reminders].
  Future<void> replaceAll(List<PlannedReminder> reminders);
}

final class NoopReminderScheduler implements ReminderScheduler {
  const NoopReminderScheduler();

  @override
  Future<String?> start(void Function(String route) onOpen) async => null;

  @override
  Future<ReminderPermissions> permissions() async =>
      (notifications: false, exactAlarms: false);

  @override
  Future<bool> requestNotifications() async => false;

  @override
  Future<bool> requestExactAlarms() async => false;

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async {}
}

/// Android reminders through `flutter_local_notifications`.
final class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  static const _prayer = AndroidNotificationDetails(
    'madar.reminders.prayer',
    'Prayer times · مواقيت الصلاة',
    channelDescription: 'Prayer time reminders',
    importance: Importance.high,
    priority: Priority.high,
    category: AndroidNotificationCategory.reminder,
    // The verse under the title opens in full.
    styleInformation: BigTextStyleInformation(''),
  );
  static const _adhkar = AndroidNotificationDetails(
    'madar.reminders.adhkar',
    'Remembrance · الأذكار',
    channelDescription:
        'Morning, evening, after-prayer and bedtime remembrance',
    category: AndroidNotificationCategory.reminder,
  );
  static const _dua = AndroidNotificationDetails(
    'madar.reminders.dua',
    'Supplications · الأدعية',
    channelDescription: 'Supplication reminders',
    importance: Importance.low,
    priority: Priority.low,
    styleInformation: BigTextStyleInformation(''),
  );

  @override
  Future<String?> start(void Function(String route) onOpen) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final route = response.payload;
        if (route != null && route.startsWith('/')) onOpen(route);
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final route = launch?.didNotificationLaunchApp == true
        ? launch?.notificationResponse?.payload
        : null;
    return route != null && route.startsWith('/') ? route : null;
  }

  @override
  Future<ReminderPermissions> permissions() async {
    final android = _android;
    if (android == null) return (notifications: false, exactAlarms: false);
    return (
      notifications: await android.areNotificationsEnabled() ?? false,
      exactAlarms: await android.canScheduleExactNotifications() ?? false,
    );
  }

  @override
  Future<bool> requestNotifications() async =>
      await _android?.requestNotificationsPermission() ?? false;

  @override
  Future<bool> requestExactAlarms() async {
    await _android?.requestExactAlarmsPermission();
    return (await permissions()).exactAlarms;
  }

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async {
    await _plugin.cancelAllPendingNotifications();
    if (reminders.isEmpty) return;
    final exact = (await permissions()).exactAlarms;
    for (final reminder in reminders) {
      final android = switch (reminder.kind) {
        ReminderKind.adhan || ReminderKind.beforePrayer => _prayer,
        ReminderKind.dua || ReminderKind.dailyDua => _dua,
        _ => _adhkar,
      };
      try {
        await _plugin.zonedSchedule(
          id: reminder.id,
          scheduledDate: reminder.time,
          notificationDetails: NotificationDetails(android: android),
          androidScheduleMode: exact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
          title: reminder.title,
          body: reminder.body,
          payload: reminder.route,
        );
      } on Object catch (error, stack) {
        // One reminder the system refuses must not stop the others.
        FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stack),
        );
      }
    }
  }
}
