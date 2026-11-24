import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/localization/civil_hijri_date.dart';
import 'package:madar_al_huda/features/prayer/domain/prayer_schedule.dart';
import 'package:madar_al_huda/features/qibla/domain/qibla_bearing.dart';
import 'package:madar_al_huda/features/reminders/domain/reminder_plan.dart';
import 'package:madar_al_huda/features/reminders/domain/reminder_settings.dart';

import '../../helpers/places.dart';
import 'reminder_plan_test.dart' show TestReminderTexts;

/// The Gregorian date of a civil Hijri date, found by scanning forward.
DateTime gregorian(int month, int day, {DateTime? from}) {
  var date = from ?? DateTime.utc(2026, 11, 1);
  for (var i = 0; i < 400; i++) {
    final hijri = civilHijri(date)!;
    if (hijri.month == month && hijri.day == day) return date;
    date = date.add(const Duration(days: 1));
  }
  throw StateError('not found');
}

void main() {
  const all = ReminderSettings(
    fastMonThu: true,
    fastWhiteDays: true,
    fastOccasions: true,
  );

  test('recognizes the recommended days', () {
    expect(fastingDayOn(gregorian(12, 9), all), FastingDay.arafah);
    expect(fastingDayOn(gregorian(1, 9), all), FastingDay.tasua);
    expect(fastingDayOn(gregorian(1, 10), all), FastingDay.ashura);
    expect(fastingDayOn(gregorian(6, 14), all), FastingDay.whiteDay);
    // 23 November 2026 is a Monday outside the white days.
    expect(fastingDayOn(DateTime.utc(2026, 11, 23), all), FastingDay.monday);
    // 26 November is 15 Jumada II (a white day); 3 December is not.
    expect(fastingDayOn(DateTime.utc(2026, 11, 26), all), FastingDay.whiteDay);
    expect(fastingDayOn(DateTime.utc(2026, 12, 3), all), FastingDay.thursday);
    // Saturday 28 November (17 Jumada II) offers nothing.
    expect(fastingDayOn(DateTime.utc(2026, 11, 28), all), isNull);
  });

  test('never suggests the Eids, tashreeq or Ramadan', () {
    for (final (month, day) in [
      (10, 1),
      (12, 10),
      (12, 11),
      (12, 12),
      (12, 13),
      (9, 14),
    ]) {
      // Even when the date is also a Monday, Thursday or white day.
      expect(
        fastingDayOn(gregorian(month, day), all),
        isNull,
        reason: '$month/$day',
      );
    }
  });

  test('only the chosen kinds are reminded', () {
    const monThuOnly = ReminderSettings(fastMonThu: true);
    expect(
      fastingDayOn(gregorian(12, 9), monThuOnly),
      anyOf(isNull, FastingDay.monday, FastingDay.thursday),
    );
    expect(
      fastingDayOn(
        gregorian(6, 14),
        const ReminderSettings(fastOccasions: true),
      ),
      isNull,
    );
  });

  test('the reminder comes at 21:00 the evening before', () {
    final reminders = planReminders(
      settings: const ReminderSettings(fastMonThu: true),
      scheduleOn: (day) => PrayerSchedule.calculate(
        place: placeOf(ManualCity.dubai),
        now: day,
        hanafi: false,
      ),
      // Saturday 21 November 2026, morning in Dubai.
      now: DateTime.utc(2026, 11, 21, 4),
      texts: TestReminderTexts(),
      days: 7,
    ).where((r) => r.kind == ReminderKind.fasting).toList();
    // Sunday evening for Monday, Wednesday evening for Thursday.
    expect(reminders.map((r) => (r.time.weekday, r.time.hour)), [
      (DateTime.sunday, 21),
      (DateTime.wednesday, 21),
    ]);
    expect(reminders.first.title, 'fast monday');
  });
}
