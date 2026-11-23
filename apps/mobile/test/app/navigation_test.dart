import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/app/app_shell.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/core/routing/app_sections.dart';
import 'package:madar_al_huda/core/widgets/content_status_panel.dart';
import 'package:madar_al_huda/core/widgets/section_card.dart';
import 'package:madar_al_huda/core/widgets/settings_button.dart';
import 'package:madar_al_huda/features/prayer/presentation/prayer_times_screen.dart';
import 'package:madar_al_huda/features/qibla/presentation/qibla_screen.dart';
import 'package:madar_al_huda/features/quran/presentation/mushaf_screen.dart';
import 'package:madar_al_huda/features/worship/application/worship_location.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

Finder navTab(String label) => find.descendant(
  of: find.byKey(AppShell.navigationBarKey),
  matching: find.text(label),
);

void main() {
  testWidgets('shows the five main destinations', (tester) async {
    await pumpMadarApp(tester);
    final bar = find.byKey(AppShell.navigationBarKey);
    expect(bar, findsOneWidget);
    expect(
      find.descendant(of: bar, matching: find.byType(NavigationDestination)),
      findsNWidgets(5),
    );
    for (final label in ['Today', 'Quran', 'Adhkar', 'Prayer', 'Library']) {
      expect(navTab(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('library links to the existing content sections', (tester) async {
    await pumpMadarApp(tester);
    await tester.tap(navTab('Library'));
    await tester.pumpAndSettle();
    for (final section in [
      AppSection.hadith,
      AppSection.fiqh,
      AppSection.articles,
    ]) {
      await tester.scrollUntilVisible(
        find.byKey(SectionCard.keyFor(section)),
        160,
      );
      expect(find.byKey(SectionCard.keyFor(section)), findsOneWidget);
    }
    expect(find.text('Stories of the prophets'), findsWidgets);
    expect(find.text('Academy'), findsOneWidget);
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('[$locale] unimplemented content keeps the status panel', (
      tester,
    ) async {
      final l10n = lookupAppLocalizations(locale);
      for (final section in const [
        AppSection.fiqh,
        AppSection.articles,
        AppSection.lessons,
        AppSection.stories,
      ]) {
        await pumpMadarApp(
          tester,
          deviceLocales: [locale],
          initialLocation: section.path,
        );
        expect(
          find.byType(ContentStatusPanel),
          findsOneWidget,
          reason: '$section',
        );
        expect(find.byType(AppBar), findsOneWidget);
        // Title appears in the app bar and the header.
        expect(find.text(section.title(l10n)), findsWidgets);
        expect(find.text(section.subtitle(l10n)), findsOneWidget);
        expect(find.text(section.status.title(l10n)), findsOneWidget);
        expect(find.text(section.status.body(l10n)), findsOneWidget);
      }
    });

    testWidgets('[$locale] the dua preview opens with a topic filter', (
      tester,
    ) async {
      await pumpMadarApp(
        tester,
        deviceLocales: [locale],
        initialLocation: AppRoutes.adhkar,
      );
      final l10n = lookupAppLocalizations(locale);
      final tile = find
          .text(
            locale.languageCode == 'ar'
                ? 'الأدعية القرآنية'
                : 'Quranic supplications',
          )
          .hitTestable();
      await tester.scrollUntilVisible(tile, 140);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(find.text(l10n.duaTitle), findsOneWidget);
      expect(find.text(l10n.duaTopics), findsOneWidget);
      expect(find.byType(ExpansionTile), findsWidgets);
    });
  }

  testWidgets('legacy Quran paths all open the unified reader', (tester) async {
    for (final path in [
      AppRoutes.quran,
      AppRoutes.mushaf,
      AppRoutes.recitations,
      AppRoutes.tafsir,
    ]) {
      await pumpMadarApp(tester, initialLocation: path);
      expect(find.byType(MushafScreen), findsOneWidget);
      expect(find.byType(ContentStatusPanel), findsNothing);
    }
  });

  testWidgets('tabs keep their own navigation stack', (tester) async {
    await pumpMadarApp(tester);

    await tester.tap(navTab('Prayer'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Qibla'));
    await tester.pumpAndSettle();
    expect(find.byType(QiblaScreen), findsOneWidget);

    await tester.tap(navTab('Quran'));
    await tester.pumpAndSettle();
    expect(find.byType(MushafScreen), findsOneWidget);
    await tester.tap(navTab('Prayer'));
    await tester.pumpAndSettle();
    expect(find.byType(QiblaScreen), findsOneWidget);

    await tester.tap(navTab('Prayer'));
    await tester.pumpAndSettle();
    expect(find.byType(PrayerTimesScreen), findsOneWidget);
    expect(find.byType(QiblaScreen), findsNothing);
  });

  testWidgets('the selected city feeds Prayer and the north-up Qibla', (
    tester,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final store = await pumpMadarApp(
      tester,
      initialLocation: AppRoutes.prayerTimes,
    );
    await tester.tap(find.widgetWithText(ChoiceChip, l10n.cityDubai));
    await tester.pumpAndSettle();
    expect(find.textContaining(l10n.nextPrayer), findsOneWidget);
    expect(store.getString(WorshipLocationController.cityKey), 'dubai-ae');
    await tester.tap(find.widgetWithText(TextButton, l10n.sectionQiblaTitle));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, l10n.cityDubai))
          .selected,
      isTrue,
    );
    expect(find.text(l10n.cityBearingApproximate), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back button returns from a section to its hub', (tester) async {
    await pumpMadarApp(tester);
    await tester.tap(navTab('Library'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SectionCard.keyFor(AppSection.fiqh)));
    await tester.pumpAndSettle();
    expect(find.byType(ContentStatusPanel), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(SectionCard.keyFor(AppSection.fiqh)), findsOneWidget);
  });

  testWidgets('home quick access jumps into the right tab', (tester) async {
    await pumpMadarApp(tester);
    await tester.tap(
      find.byKey(const ValueKey('quick-access-AppSection.qibla')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(QiblaScreen), findsOneWidget);
    final bar = tester.widget<NavigationBar>(
      find.byKey(AppShell.navigationBarKey),
    );
    expect(bar.selectedIndex, 3, reason: 'Prayer tab selected');
  });

  testWidgets('settings opens above the shell and closes', (tester) async {
    await pumpMadarApp(tester);
    await tester.tap(find.byKey(SettingsButton.buttonKey));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.byKey(AppShell.navigationBarKey), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(AppShell.navigationBarKey), findsOneWidget);
  });

  testWidgets('unknown routes show a recoverable not-found page', (
    tester,
  ) async {
    await pumpMadarApp(tester, initialLocation: '/no/such/page');
    expect(find.text('Page not found'), findsOneWidget);
    await tester.tap(find.text('Back to home'));
    await tester.pumpAndSettle();
    expect(find.byKey(AppShell.navigationBarKey), findsOneWidget);
  });

  testWidgets('wide screens use a navigation rail', (tester) async {
    await pumpMadarApp(tester, size: tabletSize);
    expect(find.byKey(AppShell.navigationRailKey), findsOneWidget);
    expect(find.byKey(AppShell.navigationBarKey), findsNothing);
  });

  testWidgets('home shows no fabricated prayer times or religious text', (
    tester,
  ) async {
    await pumpMadarApp(tester);
    // No clock-like times (e.g. "04:32") anywhere on Home.
    final timeLike = RegExp(r'\b\d{1,2}:\d{2}\b');
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '');
    expect(texts.where(timeLike.hasMatch), isEmpty);
  });
}
