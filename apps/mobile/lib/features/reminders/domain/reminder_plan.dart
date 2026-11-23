import 'package:timezone/timezone.dart' as tz;

import '../../../core/localization/civil_hijri_date.dart';
import '../../../core/routing/app_routes.dart';
import '../../prayer/domain/prayer_schedule.dart';
import '../../ramadan/domain/ramadan.dart' show imsakMinutes;
import '../../worship/domain/worship_moment.dart';
import 'reminder_settings.dart';

enum ReminderKind {
  adhan,
  beforePrayer,
  afterPrayer,
  morning,
  evening,
  bedtime,
  kahf,
  dailyDua,
  dua,
  suhoor,
  iftar,
  fasting,
}

/// One notification to schedule.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.time,
    required this.kind,
    required this.title,
    required this.body,
    required this.route,
  });

  /// Stable per day and slot, so rescheduling replaces rather than duplicates.
  final int id;
  final tz.TZDateTime time;
  final ReminderKind kind;
  final String title;
  final String body;

  /// Screen opened when the notification is tapped.
  final String route;
}

/// Localized wording, supplied by the caller so planning stays testable.
abstract interface class ReminderTexts {
  String prayerName(PrayerSlot slot);
  String adhanTitle(String prayer);
  String adhanBody(String prayer);
  String beforePrayerTitle(String prayer, int minutes);
  String afterPrayerTitle(String prayer);
  String get afterPrayerBody;
  String get morningTitle;
  String get eveningTitle;
  String get bedtimeTitle;
  String get adhkarBody;
  String get kahfTitle;
  String get kahfBody;
  String get duaTitle;
  String get suhoorTitle;
  String get suhoorBody;
  String get iftarTitle;
  String get iftarBody;
  String fastingTitle(FastingDay day);
  String get fastingBody;
}

/// Why a day is a recommended day to fast.
enum FastingDay { arafah, tasua, ashura, whiteDay, monday, thursday }

/// The voluntary fast that [day] offers, or null. Days on which fasting is
/// not allowed (the two Eids and the days of tashreeq) and Ramadan never
/// qualify. Uses the civil Hijri calendar.
FastingDay? fastingDayOn(DateTime day, ReminderSettings settings) {
  final hijri = civilHijri(DateTime.utc(day.year, day.month, day.day));
  if (hijri == null || hijri.month == 9) return null;
  final month = hijri.month;
  final date = hijri.day;
  final forbidden =
      (month == 10 && date == 1) || (month == 12 && date >= 10 && date <= 13);
  if (forbidden) return null;
  if (settings.fastOccasions) {
    if (month == 12 && date == 9) return FastingDay.arafah;
    if (month == 1 && date == 9) return FastingDay.tasua;
    if (month == 1 && date == 10) return FastingDay.ashura;
  }
  if (settings.fastWhiteDays && date >= 13 && date <= 15) {
    return FastingDay.whiteDay;
  }
  if (settings.fastMonThu) {
    if (day.weekday == DateTime.monday) return FastingDay.monday;
    if (day.weekday == DateTime.thursday) return FastingDay.thursday;
  }
  return null;
}

/// A supplication used in reminders, already in its final wording.
typedef ReminderDua = ({String text, String source});

const _obligatory = [
  PrayerSlot.fajr,
  PrayerSlot.dhuhr,
  PrayerSlot.asr,
  PrayerSlot.maghrib,
  PrayerSlot.isha,
];

/// Plans every enabled reminder from [now] for [days] days.
///
/// [scheduleOn] returns the prayer schedule for the local day containing the
/// given instant. Only reminders after [now] are returned, sorted by time.
List<PlannedReminder> planReminders({
  required ReminderSettings settings,
  required PrayerSchedule Function(DateTime day) scheduleOn,
  required DateTime now,
  required ReminderTexts texts,
  List<ReminderDua> duas = const [],
  int days = 7,
}) {
  final planned = <PlannedReminder>[];
  if (!settings.anyEnabled) return planned;
  var dayStart = scheduleOn(now).today.first.time;
  dayStart = tz.TZDateTime(
    dayStart.location,
    dayStart.year,
    dayStart.month,
    dayStart.day,
  );

  for (var day = 0; day < days; day++) {
    final date = tz.TZDateTime(
      dayStart.location,
      dayStart.year,
      dayStart.month,
      dayStart.day + day,
      12,
    );
    final schedule = scheduleOn(date);
    final base = (day % 30) * 100 + 1000;
    tz.TZDateTime at(PrayerSlot slot) =>
        schedule.today.firstWhere((event) => event.slot == slot).time;
    tz.TZDateTime clock(int minutes) => tz.TZDateTime(
      date.location,
      date.year,
      date.month,
      date.day,
    ).add(Duration(minutes: minutes));
    void add(
      int slot,
      tz.TZDateTime time,
      ReminderKind kind,
      String title,
      String body,
      String route,
    ) {
      if (time.isAfter(now)) {
        planned.add(
          PlannedReminder(
            id: base + slot,
            time: time,
            kind: kind,
            title: title,
            body: body,
            route: route,
          ),
        );
      }
    }

    for (var i = 0; i < _obligatory.length; i++) {
      final slot = _obligatory[i];
      final name = texts.prayerName(slot);
      final time = at(slot);
      if (settings.adhan) {
        add(
          i,
          time,
          ReminderKind.adhan,
          texts.adhanTitle(name),
          texts.adhanBody(name),
          AppRoutes.prayerTimes,
        );
      }
      if (settings.beforePrayer) {
        add(
          10 + i,
          time.subtract(Duration(minutes: settings.beforePrayerMinutes)),
          ReminderKind.beforePrayer,
          texts.beforePrayerTitle(name, settings.beforePrayerMinutes),
          texts.adhanBody(name),
          AppRoutes.prayerTimes,
        );
      }
      if (settings.afterPrayer) {
        add(
          20 + i,
          time.add(const Duration(minutes: 10)),
          ReminderKind.afterPrayer,
          texts.afterPrayerTitle(name),
          texts.afterPrayerBody,
          AppRoutes.adhkarGroup(WorshipMoment.afterPrayer.groupId),
        );
      }
    }
    if (settings.morning) {
      add(
        30,
        at(PrayerSlot.fajr).add(const Duration(minutes: 30)),
        ReminderKind.morning,
        texts.morningTitle,
        texts.adhkarBody,
        AppRoutes.adhkarGroup(WorshipMoment.morning.groupId),
      );
    }
    if (settings.evening) {
      add(
        31,
        at(PrayerSlot.asr).add(const Duration(minutes: 15)),
        ReminderKind.evening,
        texts.eveningTitle,
        texts.adhkarBody,
        AppRoutes.adhkarGroup(WorshipMoment.evening.groupId),
      );
    }
    if (settings.bedtime) {
      add(
        32,
        bedtimeFor(schedule, settings.bedtimeMinutes),
        ReminderKind.bedtime,
        texts.bedtimeTitle,
        texts.adhkarBody,
        AppRoutes.adhkarGroup(WorshipMoment.bedtime.groupId),
      );
    }
    if (settings.kahf && date.weekday == DateTime.friday) {
      add(
        33,
        clock(10 * 60),
        ReminderKind.kahf,
        texts.kahfTitle,
        texts.kahfBody,
        AppRoutes.verse(18, 1),
      );
    }
    if ((settings.suhoor || settings.iftar) &&
        civilHijri(DateTime.utc(date.year, date.month, date.day))?.month == 9) {
      if (settings.suhoor) {
        add(
          35,
          at(PrayerSlot.fajr)
              .subtract(const Duration(minutes: imsakMinutes + 30)),
          ReminderKind.suhoor,
          texts.suhoorTitle,
          texts.suhoorBody,
          AppRoutes.ramadan,
        );
      }
      if (settings.iftar) {
        add(
          36,
          at(PrayerSlot.maghrib),
          ReminderKind.iftar,
          texts.iftarTitle,
          texts.iftarBody,
          AppRoutes.ramadan,
        );
      }
    }
    if (settings.fastMonThu ||
        settings.fastWhiteDays ||
        settings.fastOccasions) {
      final tomorrow = DateTime.utc(date.year, date.month, date.day + 1);
      final fast = fastingDayOn(tomorrow, settings);
      if (fast != null) {
        add(
          37,
          clock(21 * 60),
          ReminderKind.fasting,
          texts.fastingTitle(fast),
          texts.fastingBody,
          AppRoutes.home,
        );
      }
    }
    final dayNumber = date.difference(DateTime.utc(2026)).inDays;
    if (settings.dailyDua && duas.isNotEmpty) {
      final dua = duas[dayNumber % duas.length];
      add(
        34,
        clock(8 * 60),
        ReminderKind.dailyDua,
        texts.duaTitle,
        '${dua.text} · ${dua.source}',
        AppRoutes.quranDuas,
      );
    }
    if (settings.duaEveryHours > 0 && duas.isNotEmpty) {
      var index = 0;
      for (
        var minutes = 9 * 60;
        minutes < 24 * 60 && index < 10;
        minutes += settings.duaEveryHours * 60
      ) {
        if (_quiet(minutes, settings)) continue;
        // Offset from the daily supplication so they differ on the same day.
        final dua = duas[(dayNumber * 7 + index + 1) % duas.length];
        add(
          40 + index,
          clock(minutes),
          ReminderKind.dua,
          texts.duaTitle,
          '${dua.text} · ${dua.source}',
          AppRoutes.quranDuas,
        );
        index++;
      }
    }
  }
  planned.sort((a, b) => a.time.compareTo(b.time));
  return planned;
}

bool _quiet(int minutes, ReminderSettings settings) {
  final start = settings.quietStartMinutes;
  final end = settings.quietEndMinutes;
  return start <= end
      ? minutes >= start && minutes < end
      : minutes >= start || minutes < end;
}
