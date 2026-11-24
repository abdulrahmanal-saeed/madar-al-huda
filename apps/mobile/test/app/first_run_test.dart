import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/app/first_run.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/core/storage/key_value_store.dart';
import 'package:madar_al_huda/features/reminders/application/reminder_settings_controller.dart';
import 'package:madar_al_huda/features/reminders/domain/reminder_settings.dart';
import 'package:madar_al_huda/features/settings/data/settings_repository.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('first launch: language, theme, permissions, then reminders', (
    tester,
  ) async {
    final store = await pumpMadarApp(
      tester,
      initialLocation: AppRoutes.home,
      showStartupSplash: true,
    );
    // The splash first, then the first-run steps.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('first-run-arabic')), findsOneWidget);

    await tester.tap(find.byKey(const Key('first-run-arabic')));
    await tester.tap(find.byKey(const Key('first-run-dark')));
    await tester.pumpAndSettle();
    final arabic = lookupAppLocalizations(AppLocales.arabic);
    expect(find.text(arabic.firstRunLookTitle), findsOneWidget);
    expect(store.getString(SettingsRepository.languageKey), 'ar');
    expect(store.getString(SettingsRepository.themeKey), 'dark');

    await tester.tap(find.byKey(const Key('first-run-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('first-run-notifications')), findsOneWidget);
    await tester.tap(find.byKey(const Key('first-run-later')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('first-run-location')), findsOneWidget);
    await tester.tap(find.byKey(const Key('first-run-later')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('first-run-reminders')), findsOneWidget);

    // Select all turns every switch on; tapping again clears them.
    await tester.tap(find.byKey(const Key('first-run-select-all')));
    await tester.pumpAndSettle();
    expect(
      tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)).every(
        (tile) => tile.value,
      ),
      isTrue,
    );
    expect(find.text(arabic.firstRunClearAll), findsOneWidget);

    await tester.tap(find.byKey(const Key('first-run-finish')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('first-run-reminders')), findsNothing);
    expect(firstRunDone(store), isTrue);
    final saved = ReminderSettings.decode(
      store.getString(ReminderSettingsController.key),
    );
    expect(saved.adhan && saved.morning && saved.kahf, isTrue);
  });

  testWidgets('returning users go straight to the app', (tester) async {
    await pumpMadarApp(
      tester,
      initialLocation: AppRoutes.home,
      showStartupSplash: true,
      store: InMemoryKeyValueStore({firstRunDoneKey: true}),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('first-run-arabic')), findsNothing);
  });
}
