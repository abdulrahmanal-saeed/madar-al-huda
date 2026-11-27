import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../prayer/application/prayer_preferences.dart';
import '../../prayer/domain/prayer_schedule.dart';
import '../../reminders/application/reminder_settings_controller.dart';
import '../domain/worship_moment.dart';
import 'worship_location.dart';

final adhkarClockProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 15), (_) => DateTime.now());
});

final currentWorshipMomentProvider = Provider.autoDispose<WorshipMoment?>((
  ref,
) {
  final now = ref.watch(adhkarClockProvider).asData?.value ?? DateTime.now();
  final bedtime = ref.watch(reminderSettingsProvider).bedtimeMinutes;
  final place = ref.watch(prayerPlaceProvider);
  if (place != null) {
    final schedule = PrayerSchedule.calculate(
      place: place,
      now: now,
      hanafi: ref.watch(hanafiAsrProvider),
    );
    return worshipMomentAt(schedule, now, bedtimeMinutes: bedtime);
  }

  // Without a city we can suggest a daily routine, but have no prayer time.
  final minutes = now.hour * 60 + now.minute;
  if (minutes < 5 * 60 || minutes >= bedtime) return WorshipMoment.bedtime;
  if (minutes < 12 * 60) return WorshipMoment.morning;
  if (minutes >= 16 * 60) return WorshipMoment.evening;
  return null;
});
