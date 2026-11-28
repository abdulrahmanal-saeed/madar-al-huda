import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/app/app_shell.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/core/routing/app_sections.dart';
import 'package:madar_al_huda/core/widgets/content_status_panel.dart';
import 'package:madar_al_huda/core/widgets/section_card.dart';
import 'package:madar_al_huda/core/widgets/settings_button.dart';
import 'package:madar_al_huda/features/fiqh/data/fiqh_catalog.dart';
import 'package:madar_al_huda/features/fiqh/presentation/fiqh_screen.dart';
import 'package:madar_al_huda/features/home/data/daily_duas.dart';
import 'package:madar_al_huda/features/home/presentation/listening_duas.dart';
import 'package:madar_al_huda/features/learning/data/learning_catalog.dart';
import 'package:madar_al_huda/features/learning/data/learning_files.dart';
import 'package:madar_al_huda/features/learning/data/prophet_stories.dart';
import 'package:madar_al_huda/features/prayer/presentation/prayer_times_screen.dart';
import 'package:madar_al_huda/features/qibla/presentation/qibla_screen.dart';
import 'package:madar_al_huda/features/quran/presentation/mushaf_screen.dart';
import 'package:madar_al_huda/features/worship/application/worship_location.dart';
import 'package:madar_al_huda/features/worship/presentation/worship_hub_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

Finder navTab(String label) => find.descendant(
  of: find.byKey(AppShell.navigationBarKey),
  matching: find.byTooltip(label),
);

void main() {
  testWidgets('shows the five main destinations', (tester) async {
    await pumpMadarApp(tester);
    final bar = find.byKey(AppShell.navigationBarKey);
    expect(bar, findsOneWidget);
    expect(
      find.descendant(of: bar, matching: find.byType(Tooltip)),
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
    for (final section in [AppSection.stories, AppSection.lessons]) {
      await tester.scrollUntilVisible(
        find.byKey(SectionCard.keyFor(section)),
        160,
      );
    }
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

  testWidgets('prophet stories open the audio and video episode lists', (
    tester,
  ) async {
    final catalog = await tester.runAsync(
      () async => parseLearningSeries(
        await rootBundle.loadString('assets/learning/prophet_stories.json'),
      ),
    );
    await pumpMadarApp(
      tester,
      initialLocation: AppRoutes.stories,
      additionalOverrides: [
        prophetStoriesProvider.overrideWith((_) => catalog!),
        lessonSavedProvider.overrideWith((_, _) => false),
      ],
    );
    expect(find.byType(ContentStatusPanel), findsNothing);
    expect(find.text('Idris, peace be upon him'), findsOneWidget);
    await tester.tap(find.text('Adam, peace be upon him'));
    await tester.pumpAndSettle();
    final formats = find.byKey(const Key('episode-format'));
    expect(
      find.descendant(of: formats, matching: find.text('Audio')),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(of: formats, matching: find.text('Video')),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<SegmentedButton<LessonFormat>>(formats).selected, {
      LessonFormat.video,
    });
    expect(find.text('Episode 1'), findsOneWidget);
    expect(find.text('Episode 6'), findsOneWidget);
  });

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
    await tester.tap(find.text('Qibla'));
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
    expect(find.byType(WorshipHubScreen), findsOneWidget);
    expect(find.byType(QiblaScreen), findsNothing);
  });

  testWidgets('Prayer home puts the full-width daily reading above two tiles', (
    tester,
  ) async {
    await pumpMadarApp(tester);
    await tester.tap(navTab('Prayer'));
    await tester.pumpAndSettle();
    final daily = tester.getRect(
      find.widgetWithText(Card, 'Daily Quran reading'),
    );
    final times = tester.getRect(find.widgetWithText(Card, 'Prayer Times'));
    final qibla = tester.getRect(find.widgetWithText(Card, 'Qibla'));
    expect(daily.bottom, lessThan(times.top));
    expect(times.top, qibla.top);
    expect(daily.left, times.left);
    expect(daily.right, qibla.right);
    expect(
      find.descendant(
        of: find.byType(WorshipHubScreen),
        matching: find.byType(Card),
      ),
      findsNWidgets(3),
    );
    await tester.tap(find.text('Prayer Times'));
    await tester.pumpAndSettle();
    expect(find.byType(PrayerTimesScreen), findsOneWidget);
  });

  testWidgets('the selected city feeds Prayer and the north-up Qibla', (
    tester,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final store = await pumpMadarApp(
      tester,
      initialLocation: AppRoutes.prayerTimes,
    );
    expect(find.text(l10n.locationChooseTitle), findsOneWidget);
    await tester.tap(find.byKey(const Key('worship-location')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('city-search')), 'دبي');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('city-292223')));
    await tester.pumpAndSettle();
    expect(find.textContaining(l10n.nextPrayer), findsOneWidget);
    expect(
      store.getString(WorshipLocationController.placeKey),
      contains('Asia/Dubai'),
    );
    expect(
      find.text('Dubai, UAE · ${l10n.locationChosenCity}'),
      findsOneWidget,
    );
    // One location only: no list of other cities on the screen.
    expect(find.text('Cairo'), findsNothing);
    await tester.tap(find.byTooltip(l10n.sectionQiblaTitle));
    await tester.pumpAndSettle();
    expect(
      find.text('Dubai, UAE · ${l10n.locationChosenCity}'),
      findsOneWidget,
    );
    expect(find.text(l10n.cityBearingApproximate), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty published fiqh feed is authoritative', (tester) async {
    await pumpMadarApp(
      tester,
      initialLocation: AppSection.fiqh.path,
      fiqhCatalog: FiqhCatalog.decode({
        'schemaVersion': 1,
        'kind': 'published_fiqh',
        'disclaimer': {'ar': 'اختبار فقط', 'en': 'Synthetic only'},
        'categories': <Object?>[],
        'issues': <Object?>[],
      }),
    );
    expect(find.byType(FiqhCatalogScreen), findsOneWidget);
    expect(find.byType(ContentStatusPanel), findsNothing);
    expect(find.text('No matching published issues.'), findsOneWidget);
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
    final tab = tester.widget<Semantics>(
      find.ancestor(
        of: navTab('Prayer'),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.label == 'Prayer',
        ),
      ),
    );
    expect(tab.properties.selected, isTrue, reason: 'Prayer tab selected');
  });

  testWidgets('settings keeps the dock and returns to the previous page', (
    tester,
  ) async {
    await pumpMadarApp(tester);
    await tester.tap(find.byKey(SettingsButton.buttonKey));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.byKey(AppShell.navigationBarKey), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(AppShell.navigationBarKey), findsOneWidget);
    expect(find.text('Settings'), findsNothing);
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

  testWidgets('the Home dua card keeps the text without a library shortcut', (
    tester,
  ) async {
    await pumpMadarApp(tester);
    final title = find.text('Dua of the day');
    await tester.scrollUntilVisible(
      title,
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final card = find.ancestor(of: title, matching: find.byType(Card)).first;
    final dua = dailyDuaForCivilDay(DateTime.now(), bundledDailyDuas);
    expect(
      find.descendant(of: card, matching: find.text(dua.ar)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('Listen to duas')),
      findsNothing,
    );
  });

  testWidgets('the recorded duas still open from the Adhkar tab', (
    tester,
  ) async {
    await pumpMadarApp(tester, initialLocation: AppRoutes.adhkar);
    final target = find.text('Listen to duas');
    await tester.scrollUntilVisible(
      target,
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(find.byType(ListeningDuasScreen), findsOneWidget);
  });

  testWidgets('home shows no fabricated prayer times or religious text', (
    tester,
  ) async {
    await pumpMadarApp(tester);
    // No clock-like times (e.g. "04:32") on Home, except exact verified
    // supplication references such as Quran 20:25–28.
    final timeLike = RegExp(r'\b\d{1,2}:\d{2}\b');
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '');
    final knownSources = bundledDailyDuas.map((dua) => dua.sourceEn).toSet();
    expect(
      texts.where(
        (text) => timeLike.hasMatch(text) && !knownSources.contains(text),
      ),
      isEmpty,
    );
  });
}
