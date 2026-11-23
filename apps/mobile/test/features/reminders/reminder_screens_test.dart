import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/core/storage/key_value_store.dart';
import 'package:madar_al_huda/core/storage/storage_providers.dart';
import 'package:madar_al_huda/features/adhkar/data/adhkar_catalog.dart';
import 'package:madar_al_huda/features/home/presentation/worship_now_card.dart';
import 'package:madar_al_huda/features/prayer/domain/prayer_schedule.dart';
import 'package:madar_al_huda/features/qibla/domain/qibla_bearing.dart';
import 'package:madar_al_huda/features/reminders/application/reminder_settings_controller.dart';
import 'package:madar_al_huda/features/reminders/data/reminder_scheduler.dart';
import 'package:madar_al_huda/features/reminders/domain/reminder_plan.dart';
import 'package:madar_al_huda/features/reminders/domain/reminder_settings.dart';
import 'package:madar_al_huda/features/worship/application/worship_location.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

final class _FakeScheduler implements ReminderScheduler {
  final plans = <List<PlannedReminder>>[];
  var permissionRequests = 0;

  @override
  Future<String?> start(void Function(String route) onOpen) async => null;

  @override
  Future<ReminderPermissions> permissions() async =>
      (notifications: true, exactAlarms: true);

  @override
  Future<bool> requestNotifications() async {
    permissionRequests++;
    return true;
  }

  @override
  Future<bool> requestExactAlarms() async => true;

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async =>
      plans.add(reminders);
}

void main() {
  final schedule = PrayerSchedule.calculate(
    location: ManualCity.dubai.center,
    country: WorshipCountry.emirates,
    now: DateTime.utc(2026, 11, 23, 8),
    hanafi: false,
  );
  DateTime at(PrayerSlot slot, Duration offset) =>
      schedule.today.firstWhere((e) => e.slot == slot).time.add(offset);

  Future<void> pumpCard(WidgetTester tester, DateTime now) async {
    final catalog = await tester.runAsync(() async {
      final source = await rootBundle.loadString('assets/adhkar/catalog.json');
      return AdhkarCatalog.fromJson(jsonDecode(source) as Map<String, Object?>);
    });
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          keyValueStoreProvider.overrideWithValue(InMemoryKeyValueStore()),
          adhkarCatalogProvider.overrideWith((_) => catalog!),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocales.supported,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: Scaffold(
            body: WorshipNowCard(schedule: schedule, now: now),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the home card follows the time of day', (tester) async {
    final l10n = lookupAppLocalizations(const Locale('en'));

    await pumpCard(tester, at(PrayerSlot.fajr, const Duration(hours: 1)));
    expect(find.byKey(const ValueKey('worship-now-morning')), findsOneWidget);
    expect(find.text(l10n.homeNowMorning), findsOneWidget);
    expect(find.text('Morning remembrance'), findsOneWidget);
    expect(find.text(l10n.homeNowStart), findsOneWidget);

    await pumpCard(tester, at(PrayerSlot.asr, const Duration(minutes: 5)));
    expect(
      find.byKey(const ValueKey('worship-now-afterPrayer')),
      findsOneWidget,
    );

    await pumpCard(tester, at(PrayerSlot.asr, const Duration(hours: 1)));
    expect(find.byKey(const ValueKey('worship-now-evening')), findsOneWidget);

    await pumpCard(tester, at(PrayerSlot.fajr, const Duration(minutes: -30)));
    expect(find.byKey(const ValueKey('worship-now-bedtime')), findsOneWidget);

    // Between Dhuhr's window and Asr there is nothing to suggest.
    await pumpCard(tester, at(PrayerSlot.dhuhr, const Duration(hours: 1)));
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('turning on reminders asks once, saves and schedules them', (
    tester,
  ) async {
    final scheduler = _FakeScheduler();
    final store = InMemoryKeyValueStore({
      WorshipLocationController.cityKey: ManualCity.dubai.id,
    });
    await pumpMadarApp(
      tester,
      store: store,
      initialLocation: AppRoutes.reminders,
      additionalOverrides: [
        reminderSchedulerProvider.overrideWithValue(scheduler),
      ],
    );
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.text(l10n.remindersTitle), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reminder-adhan')));
    await tester.pumpAndSettle();
    expect(scheduler.permissionRequests, 1);
    expect(
      ReminderSettings.decode(store.getString(ReminderSettingsController.key))
          .adhan,
      isTrue,
    );

    final every = find.text(l10n.remindersDuaHours('5'));
    await tester.ensureVisible(every);
    await tester.pumpAndSettle();
    await tester.tap(every);
    await tester.pumpAndSettle();
    expect(
      ReminderSettings.decode(store.getString(ReminderSettingsController.key))
          .duaEveryHours,
      5,
    );
    // A second reminder does not ask for permission again.
    expect(scheduler.permissionRequests, 1);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    final latest = scheduler.plans.last;
    expect(latest.where((r) => r.kind == ReminderKind.adhan), isNotEmpty);
    expect(latest.where((r) => r.kind == ReminderKind.dua), isNotEmpty);
  });
}
