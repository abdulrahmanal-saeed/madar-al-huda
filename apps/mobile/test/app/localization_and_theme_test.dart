import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/app/app_shell.dart';
import 'package:madar_al_huda/core/storage/key_value_store.dart';
import 'package:madar_al_huda/core/widgets/settings_button.dart';
import 'package:madar_al_huda/features/settings/data/settings_repository.dart';
import 'package:madar_al_huda/features/settings/domain/app_settings.dart';
import 'package:madar_al_huda/features/settings/presentation/settings_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byKey(SettingsButton.buttonKey));
  await tester.pumpAndSettle();
}

Brightness appBrightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Scaffold).first)).brightness;

void main() {
  group('Localization', () {
    testWidgets('English device → English UI, left-to-right', (tester) async {
      await pumpMadarApp(tester, deviceLocales: const [Locale('en', 'US')]);
      expect(appDirection(tester), TextDirection.ltr);
      expect(find.text('Assalamu alaikum'), findsOneWidget);
      expect(find.text('Continue reading'), findsOneWidget);
    });

    testWidgets('Arabic device → Arabic UI, right-to-left', (tester) async {
      await pumpMadarApp(tester, deviceLocales: const [Locale('ar', 'AE')]);
      expect(appDirection(tester), TextDirection.rtl);
      expect(find.text('السلام عليكم'), findsOneWidget);
      for (final label in ['اليوم', 'المصحف', 'الأذكار', 'المكتبة', 'الصلاة']) {
        expect(
          find.descendant(
            of: find.byKey(AppShell.navigationBarKey),
            matching: find.byTooltip(label),
          ),
          findsOneWidget,
          reason: label,
        );
      }
    });

    testWidgets('unsupported device language falls back to English', (
      tester,
    ) async {
      await pumpMadarApp(tester, deviceLocales: const [Locale('fr', 'FR')]);
      expect(appDirection(tester), TextDirection.ltr);
      expect(find.text('Today'), findsWidgets);
    });

    testWidgets('RTL mirrors layout: first tab sits on the right', (
      tester,
    ) async {
      await pumpMadarApp(tester, deviceLocales: const [Locale('ar')]);
      final home = tester.getCenter(find.byTooltip('اليوم'));
      final learning = tester.getCenter(find.byTooltip('الصلاة'));
      expect(home.dx, greaterThan(learning.dx));
    });

    testWidgets('LTR keeps the first tab on the left', (tester) async {
      await pumpMadarApp(tester);
      final home = tester.getCenter(find.byTooltip('Today'));
      final learning = tester.getCenter(find.byTooltip('Library'));
      expect(home.dx, lessThan(learning.dx));
    });

    testWidgets('switching language in Settings updates the UI and persists', (
      tester,
    ) async {
      final store = await pumpMadarApp(tester);
      await openSettings(tester);

      await tester.tap(
        find.byKey(SettingsScreen.languageOptionKey(AppLanguage.arabic)),
      );
      await tester.pumpAndSettle();

      expect(find.text('الإعدادات'), findsOneWidget);
      expect(appDirection(tester), TextDirection.rtl);
      expect(store.values[SettingsRepository.languageKey], 'ar');

      // Back to English explicitly.
      await tester.tap(
        find.byKey(SettingsScreen.languageOptionKey(AppLanguage.english)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      expect(appDirection(tester), TextDirection.ltr);
      expect(store.values[SettingsRepository.languageKey], 'en');
    });

    testWidgets('saved language overrides the device language on restart', (
      tester,
    ) async {
      final store = InMemoryKeyValueStore({
        SettingsRepository.languageKey: 'ar',
      });
      await pumpMadarApp(
        tester,
        store: store,
        deviceLocales: const [Locale('en', 'US')],
      );
      expect(appDirection(tester), TextDirection.rtl);
      expect(find.text('السلام عليكم'), findsOneWidget);
    });

    testWidgets('large text scale renders without layout errors', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final locale in const [Locale('ar'), Locale('en')]) {
        await pumpMadarApp(tester, deviceLocales: [locale]);
        expect(tester.takeException(), isNull, reason: '$locale');
        expect(find.byKey(AppShell.navigationBarKey), findsOneWidget);
      }
    });
  });

  group('Theme', () {
    testWidgets('follows the system brightness by default', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await pumpMadarApp(tester);
      expect(appBrightness(tester), Brightness.dark);
    });

    testWidgets('switching to dark and light in Settings applies and '
        'persists', (tester) async {
      final store = await pumpMadarApp(tester);
      expect(appBrightness(tester), Brightness.light);
      await openSettings(tester);

      await tester.tap(
        find.byKey(SettingsScreen.themeOptionKey(AppThemePreference.dark)),
      );
      await tester.pumpAndSettle();
      expect(appBrightness(tester), Brightness.dark);
      expect(store.values[SettingsRepository.themeKey], 'dark');

      await tester.tap(
        find.byKey(SettingsScreen.themeOptionKey(AppThemePreference.light)),
      );
      await tester.pumpAndSettle();
      expect(appBrightness(tester), Brightness.light);
      expect(store.values[SettingsRepository.themeKey], 'light');
    });

    testWidgets('saved dark theme is restored on start', (tester) async {
      await pumpMadarApp(
        tester,
        store: InMemoryKeyValueStore({SettingsRepository.themeKey: 'dark'}),
      );
      expect(appBrightness(tester), Brightness.dark);
    });

    testWidgets('reduce motion toggle persists and disables animations', (
      tester,
    ) async {
      final store = await pumpMadarApp(tester);
      await openSettings(tester);
      await tester.tap(find.byKey(SettingsScreen.reduceMotionKey));
      await tester.pumpAndSettle();

      expect(store.values[SettingsRepository.reduceMotionKey], isTrue);
      final context = tester.element(find.byType(Scaffold).first);
      expect(MediaQuery.disableAnimationsOf(context), isTrue);
    });
  });

  group('Settings', () {
    testWidgets('shows guest mode and no sign-in requirement', (tester) async {
      await pumpMadarApp(tester);
      await openSettings(tester);
      await tester.scrollUntilVisible(find.text('Guest mode'), 200);
      expect(find.text('Guest mode'), findsOneWidget);
      expect(
        find.textContaining(RegExp('sign in', caseSensitive: false)),
        findsNothing,
      );
    });

    testWidgets('rapid changes across settings all persist and match UI', (
      tester,
    ) async {
      final store = await pumpMadarApp(tester);
      await openSettings(tester);

      // Three taps without letting writes settle in between.
      await tester.tap(
        find.byKey(SettingsScreen.themeOptionKey(AppThemePreference.dark)),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(SettingsScreen.languageOptionKey(AppLanguage.arabic)),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(SettingsScreen.themeOptionKey(AppThemePreference.light)),
      );
      await tester.pumpAndSettle();

      expect(store.values[SettingsRepository.themeKey], 'light');
      expect(store.values[SettingsRepository.languageKey], 'ar');
      expect(appBrightness(tester), Brightness.light);
      expect(appDirection(tester), TextDirection.rtl);
    });

    testWidgets('shows a message and keeps the old value if saving fails', (
      tester,
    ) async {
      final store = _FailingStore();
      await pumpMadarApp(tester, store: store);
      await openSettings(tester);
      await tester.tap(
        find.byKey(SettingsScreen.themeOptionKey(AppThemePreference.dark)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text("Couldn't save your preference. Please try again."),
        findsOneWidget,
      );
      expect(appBrightness(tester), Brightness.light);
    });
  });
}

final class _FailingStore extends InMemoryKeyValueStore {
  @override
  Future<void> setString(String key, String value) =>
      Future.error(StateError('disk full'));
}
