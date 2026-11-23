import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/localization/civil_hijri_date.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/core/storage/key_value_store.dart';
import 'package:madar_al_huda/core/storage/storage_providers.dart';
import 'package:madar_al_huda/features/prayer/domain/prayer_schedule.dart';
import 'package:madar_al_huda/features/qibla/domain/qibla_bearing.dart';
import 'package:madar_al_huda/features/quran/data/mushaf_edition.dart';
import 'package:madar_al_huda/features/ramadan/domain/ramadan.dart';
import 'package:madar_al_huda/features/ramadan/presentation/ramadan_screen.dart';
import 'package:madar_al_huda/features/reminders/domain/reminder_plan.dart';
import 'package:madar_al_huda/features/reminders/domain/reminder_settings.dart';
import 'package:madar_al_huda/features/worship/application/worship_location.dart';
import 'package:material_ui/material_ui.dart';

import '../reminders/reminder_plan_test.dart' show TestReminderTexts;

PrayerSchedule _dubai(DateTime day) => PrayerSchedule.calculate(
  location: ManualCity.dubai.center,
  country: WorshipCountry.emirates,
  now: day,
  hanafi: false,
);

void main() {
  final november = DateTime(2026, 11, 23);
  final upcoming = ramadanDates(november, upcoming: true)!;

  test('finds the next civil-calendar Ramadan', () {
    expect(ramadanDates(november), isNull);
    expect(upcoming.length, inInclusiveRange(29, 30));
    expect(civilHijri(upcoming.first)?.month, 9);
    expect(civilHijri(upcoming.first)?.day, 1);
    expect(civilHijri(upcoming.last.add(const Duration(days: 1)))?.month, 10);
    // Inside the month the current Ramadan is found too.
    expect(ramadanDates(upcoming[10]), upcoming);
  });

  test('the imsakiya puts imsak ten minutes before Fajr', () {
    final days = imsakiya(upcoming, _dubai);
    expect(days, hasLength(upcoming.length));
    for (final day in days) {
      expect(day.fajr.difference(day.imsak), const Duration(minutes: 10));
      expect(day.maghrib.isAfter(day.fajr), isTrue);
    }
    expect(days.first.day, 1);
  });

  test('counts down to iftar while fasting and to imsak at night', () {
    final days = imsakiya(upcoming, _dubai);
    final second = days[1];
    final noon = second.fajr.add(const Duration(hours: 6));
    expect(ramadanNow(days, noon), (
      day: 2,
      target: RamadanCountdown.iftar,
      at: second.maghrib,
    ));
    final night = second.maghrib.add(const Duration(hours: 3));
    expect(ramadanNow(days, night), (
      day: 2,
      target: RamadanCountdown.imsak,
      at: days[2].imsak,
    ));
    final afterLast = days.last.maghrib.add(const Duration(minutes: 1));
    expect(ramadanNow(days, afterLast), isNull);
  });

  test('suhoor and iftar reminders only fall in Ramadan', () {
    const settings = ReminderSettings(suhoor: true, iftar: true);
    List<PlannedReminder> plan(DateTime now) => planReminders(
      settings: settings,
      scheduleOn: _dubai,
      now: now,
      texts: TestReminderTexts(),
      days: 3,
    );
    expect(plan(DateTime.utc(2026, 11, 23, 3)), isEmpty);

    final inside = DateTime.utc(
      upcoming[5].year,
      upcoming[5].month,
      upcoming[5].day,
    );
    final reminders = plan(inside);
    final suhoor = reminders.where((r) => r.kind == ReminderKind.suhoor);
    final iftar = reminders.where((r) => r.kind == ReminderKind.iftar);
    expect(suhoor, isNotEmpty);
    expect(iftar, isNotEmpty);
    expect(reminders.every((r) => r.route == AppRoutes.ramadan), isTrue);
    final day = imsakiya([upcoming[6]], _dubai).single;
    expect(
      suhoor.firstWhere((r) => r.time.day == day.fajr.day).time,
      day.imsak.subtract(const Duration(minutes: 30)),
    );
  });

  Future<void> pumpScreen(WidgetTester tester, DateTime now) async {
    final edition = await tester.runAsync(() => MushafEdition.load(rootBundle));
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          keyValueStoreProvider.overrideWithValue(
            InMemoryKeyValueStore({
              WorshipLocationController.cityKey: ManualCity.dubai.id,
            }),
          ),
          mushafEditionProvider.overrideWith((_) => edition!),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocales.supported,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: RamadanScreen(clock: () => now),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('during Ramadan the page counts down and lists the month', (
    tester,
  ) async {
    final day = imsakiya([upcoming[4]], _dubai).single;
    await pumpScreen(tester, day.fajr.add(const Duration(hours: 5)).toLocal());
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.text(l10n.ramadanDay('5')), findsOneWidget);
    expect(find.text(l10n.ramadanUntilIftar), findsOneWidget);
    expect(find.byKey(const ValueKey('ramadan-countdown')), findsOneWidget);
    expect(find.text(l10n.ramadanKhatmaToday('5')), findsOneWidget);
    expect(find.byKey(const ValueKey('ramadan-imsakiya')), findsOneWidget);
  });

  testWidgets('outside Ramadan the page says when it should begin', (
    tester,
  ) async {
    await pumpScreen(tester, november);
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.byKey(const ValueKey('ramadan-countdown')), findsNothing);
    expect(find.textContaining('expected to begin'), findsOneWidget);
    expect(l10n.ramadanNotNow('x'), contains('expected'));
  });
}
