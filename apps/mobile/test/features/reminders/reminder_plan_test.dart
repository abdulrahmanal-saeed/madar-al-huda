import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/features/prayer/domain/prayer_schedule.dart';
import 'package:madar_al_huda/features/qibla/domain/qibla_bearing.dart';
import 'package:madar_al_huda/features/reminders/domain/reminder_plan.dart';
import 'package:madar_al_huda/features/reminders/domain/reminder_settings.dart';
import 'package:madar_al_huda/features/worship/application/worship_location.dart';

final class TestReminderTexts implements ReminderTexts {
  @override
  String prayerName(PrayerSlot slot) => slot.name;
  @override
  String adhanTitle(String prayer) => 'adhan $prayer';
  @override
  String adhanBody(String prayer) => 'body $prayer';
  @override
  String beforePrayerTitle(String prayer, int minutes) => '$minutes $prayer';
  @override
  String afterPrayerTitle(String prayer) => 'after $prayer';
  @override
  String get afterPrayerBody => 'after';
  @override
  String get morningTitle => 'morning';
  @override
  String get eveningTitle => 'evening';
  @override
  String get bedtimeTitle => 'bedtime';
  @override
  String get adhkarBody => 'adhkar';
  @override
  String get kahfTitle => 'kahf';
  @override
  String get kahfBody => 'kahf body';
  @override
  String get duaTitle => 'dua';
  @override
  String get suhoorTitle => 'suhoor';
  @override
  String get suhoorBody => 'suhoor body';
  @override
  String get iftarTitle => 'iftar';
  @override
  String get iftarBody => 'iftar body';
}

PrayerSchedule _dubai(DateTime day) => PrayerSchedule.calculate(
  location: ManualCity.dubai.center,
  country: WorshipCountry.emirates,
  now: day,
  hanafi: false,
);

void main() {
  // Monday 23 November 2026, 07:00 in Dubai (03:00 UTC).
  final now = DateTime.utc(2026, 11, 23, 3);
  const duas = [
    (text: 'first', source: 'A'),
    (text: 'second', source: 'B'),
    (text: 'third', source: 'C'),
  ];

  List<PlannedReminder> plan(ReminderSettings settings, {int days = 7}) =>
      planReminders(
        settings: settings,
        scheduleOn: _dubai,
        now: now,
        texts: TestReminderTexts(),
        duas: duas,
        days: days,
      );

  test('nothing is planned until the user opts in', () {
    expect(plan(const ReminderSettings()), isEmpty);
  });

  test('adhan reminders fall on prayer times and skip those already past', () {
    final today = _dubai(now);
    final reminders = plan(const ReminderSettings(adhan: true), days: 1);
    // Fajr (about 05:20) has passed at 07:00; four prayers remain today.
    expect(reminders.map((r) => r.title), [
      'adhan dhuhr',
      'adhan asr',
      'adhan maghrib',
      'adhan isha',
    ]);
    final dhuhr = today.today.firstWhere((e) => e.slot == PrayerSlot.dhuhr);
    expect(reminders.first.time, dhuhr.time);
    expect(reminders.every((r) => r.route == AppRoutes.prayerTimes), isTrue);
  });

  test('ids stay unique and stable across a week', () {
    const all = ReminderSettings(
      adhan: true,
      beforePrayer: true,
      morning: true,
      evening: true,
      afterPrayer: true,
      bedtime: true,
      kahf: true,
      dailyDua: true,
      duaEveryHours: 3,
    );
    final first = plan(all);
    final ids = first.map((r) => r.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    expect(plan(all).map((r) => r.id), ids);
  });

  test('supplication reminders respect quiet hours', () {
    final reminders = plan(
      const ReminderSettings(duaEveryHours: 5),
      days: 1,
    ).where((r) => r.kind == ReminderKind.dua);
    // From 09:00 every 5 hours, before 23:00: 09:00, 14:00, 19:00.
    expect(reminders.map((r) => r.time.hour), [9, 14, 19]);
    expect(reminders.map((r) => r.route).toSet(), {AppRoutes.quranDuas});
  });

  test('remembrance reminders open their adhkar group', () {
    final routes = {
      for (final r in plan(
        const ReminderSettings(morning: true, evening: true, bedtime: true),
        days: 2,
      ))
        r.kind: r.route,
    };
    expect(routes[ReminderKind.morning], AppRoutes.adhkarGroup('morning'));
    expect(routes[ReminderKind.evening], AppRoutes.adhkarGroup('evening'));
    expect(routes[ReminderKind.bedtime], AppRoutes.adhkarGroup('bedtime'));
  });

  test('Surat Al-Kahf is reminded on Fridays only', () {
    final kahf = plan(const ReminderSettings(kahf: true))
        .where((r) => r.kind == ReminderKind.kahf)
        .toList();
    expect(kahf, hasLength(1));
    expect(kahf.single.time.weekday, DateTime.friday);
    expect(kahf.single.route, AppRoutes.verse(18, 1));
  });

  test('settings survive a round trip and reject bad values', () {
    const settings = ReminderSettings(
      adhan: true,
      duaEveryHours: 5,
      bedtimeMinutes: 23 * 60,
    );
    final decoded = ReminderSettings.decode(settings.encode());
    expect(decoded.adhan, isTrue);
    expect(decoded.duaEveryHours, 5);
    expect(decoded.bedtimeMinutes, 23 * 60);
    expect(
      ReminderSettings.decode('{"duaEveryHours": 4, "adhan": "yes"}')
          .duaEveryHours,
      0,
    );
    expect(ReminderSettings.decode('not json').anyEnabled, isFalse);
  });
}
