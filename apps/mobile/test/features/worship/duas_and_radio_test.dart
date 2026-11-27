import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/features/adhkar/data/quran_dua_index.dart';
import 'package:madar_al_huda/features/quran/data/mushaf_edition.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'each supplication links to unique verses in the pinned edition',
    () async {
      final edition = await MushafEdition.load(rootBundle);
      final seen = <(int, int)>{};
      final entries = quranDuaIndex.values.expand((ranges) => ranges).toList();
      expect(entries, hasLength(75));
      for (final range in entries) {
        expect(range.first, inInclusiveRange(1, range.last));
        expect(
          range.last,
          lessThanOrEqualTo(edition.surahs[range.surah - 1].verses.length),
        );
        for (var ayah = range.first; ayah <= range.last; ayah++) {
          expect(seen.add((range.surah, ayah)), isTrue);
        }
      }
      expect(seen, hasLength(109));
    },
  );

  testWidgets('Arabic verse search and saved supplications work offline', (
    tester,
  ) async {
    const locale = Locale('ar');
    final l10n = lookupAppLocalizations(locale);
    final store = await pumpMadarApp(
      tester,
      deviceLocales: const [locale],
      initialLocation: AppRoutes.adhkar,
    );
    final quranicDuas = find.text('الأدعية القرآنية').hitTestable();
    await tester.scrollUntilVisible(quranicDuas, 140);
    await tester.pumpAndSettle();
    await tester.tap(quranicDuas);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '٢:١٢٩');
    await tester.pumpAndSettle();
    expect(find.byType(ExpansionTile), findsOneWidget);
    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.readerAddBookmark));
    await tester.pumpAndSettle();
    expect(find.byTooltip(l10n.readerRemoveBookmark), findsOneWidget);

    await pumpMadarApp(
      tester,
      deviceLocales: const [locale],
      initialLocation: AppRoutes.adhkar,
      store: store,
    );
    await tester.scrollUntilVisible(quranicDuas, 140);
    await tester.pumpAndSettle();
    await tester.tap(quranicDuas);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.duaShowSaved));
    await tester.pumpAndSettle();
    expect(find.byType(ExpansionTile), findsOneWidget);
    expect(
      find.byKey(const ValueKey((surah: 2, first: 129, last: 129))),
      findsOneWidget,
    );
  });

  testWidgets('radio plays the live stream inside the app', (tester) async {
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final launches = <Map<Object?, Object?>>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'launch');
      launches.add(call.arguments as Map<Object?, Object?>);
      return launches.length > 1;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await pumpMadarApp(tester, initialLocation: AppRoutes.library);
    final l10n = lookupAppLocalizations(const Locale('en'));
    final radio = find.text(l10n.radioTitle);
    await tester.scrollUntilVisible(radio, 160);
    // The radio plays in place from its card: there is no radio page.
    expect(find.byKey(const Key('library-radio')), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_outlined), findsOneWidget);
    expect(launches, isEmpty);
  });
}
