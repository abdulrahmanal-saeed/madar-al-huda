import 'package:timezone/timezone.dart' as tz;

import '../../prayer/domain/prayer_schedule.dart';

/// The remembrance that fits the current time of day, used by the home
/// screen's «now» card and by the reminder scheduler.
enum WorshipMoment {
  /// From Fajr until Dhuhr: the morning remembrance.
  morning('morning'),

  /// Shortly after each obligatory prayer's time begins.
  afterPrayer('after-prayer'),

  /// From Asr until bedtime: the evening remembrance.
  evening('evening'),

  /// From bedtime until Fajr.
  bedtime('bedtime');

  const WorshipMoment(this.groupId);

  /// Id of the matching group in the adhkar catalog.
  final String groupId;
}

/// How long after a prayer's start the after-prayer remembrance is offered.
const afterPrayerWindow = Duration(minutes: 30);

/// Default bedtime, as minutes after midnight (22:30).
const defaultBedtimeMinutes = 22 * 60 + 30;

/// Bedtime on the schedule's local day: the user's chosen time, or one hour
/// after Isha when that is later (Isha is late in summer in some places).
tz.TZDateTime bedtimeFor(PrayerSchedule schedule, int bedtimeMinutes) {
  final fajr = _time(schedule, PrayerSlot.fajr);
  final chosen = tz.TZDateTime(
    fajr.location,
    fajr.year,
    fajr.month,
    fajr.day,
  ).add(Duration(minutes: bedtimeMinutes));
  final earliest = _time(
    schedule,
    PrayerSlot.isha,
  ).add(const Duration(hours: 1));
  return chosen.isBefore(earliest) ? earliest : chosen;
}

/// Picks the remembrance for [now] from today's [schedule].
///
/// Precedence: the after-prayer window, then bedtime (from [bedtimeFor]
/// until Fajr), then morning (Fajr to Dhuhr) and evening (Asr to bedtime).
/// Between Dhuhr's window and Asr nothing is suggested.
WorshipMoment? worshipMomentAt(
  PrayerSchedule schedule,
  DateTime now, {
  int bedtimeMinutes = defaultBedtimeMinutes,
}) {
  for (final event in schedule.today) {
    if (event.slot == PrayerSlot.sunrise) continue;
    if (!now.isBefore(event.time) &&
        now.isBefore(event.time.add(afterPrayerWindow))) {
      return WorshipMoment.afterPrayer;
    }
  }
  final fajr = _time(schedule, PrayerSlot.fajr);
  final bedtime = bedtimeFor(schedule, bedtimeMinutes);
  if (now.isBefore(fajr) || !now.isBefore(bedtime)) {
    return WorshipMoment.bedtime;
  }
  if (now.isBefore(_time(schedule, PrayerSlot.dhuhr))) {
    return WorshipMoment.morning;
  }
  if (!now.isBefore(_time(schedule, PrayerSlot.asr))) {
    return WorshipMoment.evening;
  }
  return null;
}

tz.TZDateTime _time(PrayerSchedule schedule, PrayerSlot slot) =>
    schedule.today.firstWhere((event) => event.slot == slot).time;
