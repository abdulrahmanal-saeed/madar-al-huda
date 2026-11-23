import 'package:timezone/timezone.dart' as tz;

import '../../../core/localization/civil_hijri_date.dart';
import '../../prayer/domain/prayer_schedule.dart';

/// Minutes before Fajr shown as «الإمساك» (a common precaution).
const imsakMinutes = 10;

/// One row of the imsakiya.
typedef RamadanDay = ({
  int day,
  DateTime date,
  tz.TZDateTime imsak,
  tz.TZDateTime fajr,
  tz.TZDateTime maghrib,
});

/// What to count down to right now.
enum RamadanCountdown { iftar, imsak }

typedef RamadanNow = ({
  /// Day of Ramadan (1–30) by the civil Hijri calendar.
  int day,
  RamadanCountdown target,
  tz.TZDateTime at,
});

/// The Gregorian dates of the civil-calendar Ramadan that contains [now],
/// or of the next one when [upcoming] is true. Local moon sighting can move
/// the start or end by a day; the screen says so.
List<DateTime>? ramadanDates(DateTime now, {bool upcoming = false}) {
  final today = DateTime.utc(now.year, now.month, now.day);
  DateTime? first;
  // Ramadan is at most ~355 days away.
  for (var offset = upcoming ? 0 : -30; offset <= 360; offset++) {
    final date = today.add(Duration(days: offset));
    final hijri = civilHijri(date);
    if (hijri?.month == 9 && hijri?.day == 1) {
      if (!upcoming && date.isAfter(today)) return null;
      first = date;
      break;
    }
  }
  if (first == null) return null;
  final days = <DateTime>[];
  for (var date = first; civilHijri(date)?.month == 9;) {
    days.add(date);
    date = date.add(const Duration(days: 1));
  }
  if (!upcoming && !days.contains(today)) return null;
  return days;
}

/// The imsakiya for [dates], from the prayer schedule of each day.
List<RamadanDay> imsakiya(
  List<DateTime> dates,
  PrayerSchedule Function(DateTime noon) scheduleOn,
) => [
  for (final (index, date) in dates.indexed)
    () {
      final schedule = scheduleOn(
        DateTime.utc(date.year, date.month, date.day, 9),
      );
      tz.TZDateTime at(PrayerSlot slot) =>
          schedule.today.firstWhere((event) => event.slot == slot).time;
      final fajr = at(PrayerSlot.fajr);
      return (
        day: index + 1,
        date: date,
        imsak: fajr.subtract(const Duration(minutes: imsakMinutes)),
        fajr: fajr,
        maghrib: at(PrayerSlot.maghrib),
      );
    }(),
];

/// During Ramadan: the next iftar while fasting, otherwise the next imsak.
RamadanNow? ramadanNow(List<RamadanDay> days, DateTime now) {
  for (final (index, day) in days.indexed) {
    if (now.isBefore(day.imsak)) {
      return (day: day.day, target: RamadanCountdown.imsak, at: day.imsak);
    }
    if (now.isBefore(day.maghrib)) {
      return (day: day.day, target: RamadanCountdown.iftar, at: day.maghrib);
    }
    // After iftar, count down to the next day's imsak when there is one.
    if (index + 1 < days.length && now.isBefore(days[index + 1].imsak)) {
      return (
        day: day.day,
        target: RamadanCountdown.imsak,
        at: days[index + 1].imsak,
      );
    }
  }
  return null;
}
