import 'package:flutter/services.dart';
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

  @override
  Future<String?> start(void Function(String route) onOpen) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('madar_notification_mark'),
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
    if (_android == null) return;
    // Remove old plugin alarms on upgrade, without canceling other app notifications.
    for (final previous in await _plugin.pendingNotificationRequests()) {
      if (previous.id >= 1000 && previous.id < 4000) {
        await _plugin.cancel(id: previous.id);
      }
    }
    await worshipAlarms.invokeMethod<void>('replace', [
      for (final event in reminders)
        {
          'id': event.id,
          'at': event.time.millisecondsSinceEpoch,
          'kind': event.kind.name,
          'title': event.title,
          'body': event.body,
          'route': event.route,
          if (event.sound != null) 'sound': event.sound,
          'stop': RegExp(r'[\u0600-\u06FF]').hasMatch(event.title)
              ? 'إيقاف'
              : 'Stop',
        },
    ]);
  }
}

const worshipAlarms = MethodChannel('madar/worship_alarms');
