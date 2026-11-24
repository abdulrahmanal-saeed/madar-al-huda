import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:madar_al_huda/core/localization/generated/app_localizations.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/features/hadith/data/hadeeth_enc.dart';
import 'package:madar_al_huda/features/hadith/data/hadith_favorites.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

final _catalog = HadithCatalog(const [
  HadithCategory(id: '1', title: 'The Quran', count: 197),
  HadithCategory(id: '5', title: 'Virtues and manners', count: 1022),
  HadithCategory(
    id: '12',
    title: 'Virtues of the Quran',
    count: 41,
    parentId: '1',
  ),
  HadithCategory(id: '9', title: 'Recitation', count: 19, parentId: '1'),
]);

const _detail = HadithDetail(
  id: '5913',
  title: 'The best of you learn the Quran',
  text: 'Uthman reported: The best of you are those who learn the Quran.',
  arabicText: 'عن عثمان رضي الله عنه: «خيركم من تعلم القرآن وعلمه».',
  explanation: 'Learning and teaching the Quran is the best work.',
  hints: ['Encouragement to learn the Quran.', 'Teaching it to others.'],
  words: [(word: 'Khayr', meaning: 'Best')],
  grade: 'Authentic',
  attribution: 'Al-Bukhari',
  reference: 'Sahih al-Bukhari 5027',
);

void main() {
  testWidgets('topics show counts, open subtopics, a list and the reader', (
    tester,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final store = await pumpMadarApp(
      tester,
      initialLocation: AppRoutes.hadith,
      additionalOverrides: [
        hadithCatalogProvider('en').overrideWith((_) => _catalog),
        hadithPageProvider((language: 'en', category: '12', page: 1))
            .overrideWith(
              (_) => (
                items: [
                  (id: '5913', title: _detail.title),
                  (id: '5907', title: 'Keep refreshing your memory of it'),
                ],
                lastPage: 1,
                total: 2,
              ),
            ),
        hadithDetailProvider((language: 'en', id: '5913'))
            .overrideWith((_) => _detail),
        hadithDetailProvider((language: 'en', id: '5907')).overrideWith(
          (_) => const HadithDetail(
            id: '5907',
            title: 'Keep refreshing your memory of it',
            text: 'Keep refreshing your memory of the Quran.',
          ),
        ),
      ],
    );

    // Main topics only, each with its count: no flat list of 493 topics.
    expect(find.text('The Quran'), findsOneWidget);
    expect(find.text('197 hadiths'), findsOneWidget);
    expect(find.text('Virtues of the Quran'), findsNothing);

    await tester.tap(find.text('The Quran'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.hadithAllIn('The Quran')), findsOneWidget);
    expect(find.text('Recitation'), findsOneWidget);

    await tester.tap(find.text('Virtues of the Quran'));
    await tester.pumpAndSettle();
    // No page arrows: the list simply continues.
    expect(find.byIcon(Icons.arrow_forward), findsNothing);
    await tester.tap(find.text(_detail.title));
    await tester.pumpAndSettle();

    expect(find.text(_detail.arabicText!), findsOneWidget);
    expect(find.text(_detail.text), findsOneWidget);
    expect(find.text('Authentic'), findsOneWidget);
    expect(find.text(l10n.hadithBenefits), findsOneWidget);
    expect(find.text('Teaching it to others.'), findsOneWidget);
    expect(find.text(l10n.hadithWords), findsOneWidget);
    expect(find.text(l10n.hadithPosition('1', '2')), findsOneWidget);

    await tester.tap(find.byKey(const Key('hadith-favorite')));
    await tester.pumpAndSettle();
    expect(store.getString(HadithFavorites.key), '5913');

    await tester.tap(find.text(l10n.hadithNext));
    await tester.pumpAndSettle();
    expect(
      find.text('Keep refreshing your memory of the Quran.'),
      findsOneWidget,
    );
    expect(find.text(l10n.hadithPosition('2', '2')), findsOneWidget);
  });

  testWidgets('topic search finds subtopics with their parent', (tester) async {
    await pumpMadarApp(
      tester,
      initialLocation: AppRoutes.hadith,
      additionalOverrides: [
        hadithCatalogProvider('en').overrideWith((_) => _catalog),
      ],
    );
    await tester.enterText(find.byKey(const Key('hadith-search')), 'recit');
    await tester.pumpAndSettle();
    expect(find.text('Recitation'), findsOneWidget);
    expect(find.text('The Quran · 19 hadiths'), findsOneWidget);
  });

  test('a hadith read once opens again without a connection', () async {
    final folder = await Directory.systemTemp.createTemp('hadith');
    addTearDown(() => folder.delete(recursive: true));
    final row = {
      'id': '5913',
      'title': 'خيركم من تعلم القرآن وعلمه',
      'hadeeth': 'عن عثمان رضي الله عنه: «خيركم من تعلم القرآن وعلمه».',
      'hadeeth_intro': 'عن عثمان رضي الله عنه:',
      'hints': ['الحث على تعلم القرآن.'],
      'words_meanings': [
        {'word': 'خيركم', 'meaning': ' أفضلكم.'},
      ],
      'grade': 'صحيح',
    };
    var online = true;
    final client = MockClient((request) async {
      if (!online) throw const SocketException('offline');
      return http.Response.bytes(utf8.encode(jsonEncode(row)), 200);
    });
    final api = HadeethEnc(client, () async => folder);
    final first = HadithDetail.parse(
      await api.get('hadeeths/one', {'id': '5913', 'language': 'ar'})
          as Map<String, dynamic>,
    );
    expect(first.body, '«خيركم من تعلم القرآن وعلمه».');
    expect(first.words.single.meaning, 'أفضلكم.');

    online = false;
    final again = await api.get('hadeeths/one', {
      'id': '5913',
      'language': 'ar',
    });
    expect((again! as Map)['grade'], 'صحيح');
  });
}
