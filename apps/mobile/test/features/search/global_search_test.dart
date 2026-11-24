import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/features/adhkar/data/adhkar_catalog.dart';
import 'package:madar_al_huda/features/hadith/data/hadeeth_enc.dart';
import 'package:madar_al_huda/features/quran/data/mushaf_edition.dart';
import 'package:madar_al_huda/features/search/domain/global_search.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('index', () {
    late GlobalSearchIndex index;

    setUpAll(() async {
      final edition = await MushafEdition.load(rootBundle);
      final adhkar = AdhkarCatalog.fromJson(
        jsonDecode(await rootBundle.loadString('assets/adhkar/catalog.json'))
            as Map<String, Object?>,
      );
      index = GlobalSearchIndex(
        edition: edition,
        adhkar: adhkar,
        hadith: HadithCatalog(const [
          HadithCategory(id: '4', title: 'الفقه وأصوله', count: 1820),
          HadithCategory(id: '50', title: 'الصلاة', count: 300, parentId: '4'),
        ]),
        shortcuts: const [
          (id: 'qibla', names: ['القبلة', 'Qibla']),
          (id: 'tasbih', names: ['السبحة', 'Tasbih']),
        ],
      );
    });

    test('finds a surah by name in either language', () {
      expect(index.search('الكهف').surahs.map((s) => s.id), contains(18));
      expect(index.search('kahf').surahs.map((s) => s.id), [18]);
    });

    test('opens a verse by its number, Arabic digits too', () {
      final verse = index.search('٢:٢٥٥').verses.single;
      expect((verse.ref.surah, verse.ref.ayah), (2, 255));
      expect(index.search('2:255').versesTotal, 1);
    });

    test('finds verses without diacritics and counts them all', () {
      final results = index.search('الصبر', verseLimit: 5);
      expect(results.versesTotal, greaterThan(5));
      expect(results.verses, hasLength(5));
    });

    test('finds app sections, adhkar and hadith topics', () {
      expect(index.search('قبله').shortcuts.single.id, 'qibla');
      expect(index.search('الصلاة').hadithTopics.single.id, '50');
      expect(index.search('الصباح').adhkar, isNotEmpty);
      expect(index.search('xyzzy').isEmpty, isTrue);
    });
  });

  testWidgets('home opens search and a result opens the verse', (tester) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    await pumpMadarApp(tester, initialLocation: AppRoutes.home);
    await tester.tap(find.byKey(const ValueKey('home-search')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.searchIntro), findsOneWidget);

    await tester.enterText(find.byKey(const Key('global-search')), '2:255');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('search-verse-2-255')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader-appearance')), findsOneWidget);
  });
}
