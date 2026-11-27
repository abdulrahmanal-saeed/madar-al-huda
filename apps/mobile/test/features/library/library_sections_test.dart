import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/core/routing/app_sections.dart';
import 'package:madar_al_huda/features/learning/data/learning_catalog.dart'
    show LessonFormat;
import 'package:madar_al_huda/features/library/domain/library_sections.dart';
import 'package:madar_al_huda/features/library/presentation/links_section_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

Map<String, Object?> feed(List<Map<String, Object?>> sections) => {
  'version': 1,
  'appearance': {'sections': sections},
};

const tafsir = {
  'id': 's-abc123',
  'kind': 'links',
  'visible': true,
  'title': {'ar': 'حلقات التفسير بالفيديو', 'en': 'Tafsir videos'},
  'subtitle': {'ar': 'سلسلة أسبوعية', 'en': 'A weekly series'},
  'items': [
    {
      'title': {'ar': 'الحلقة ١', 'en': 'Episode 1'},
      'url': 'https://example.org/ep1.mp4',
    },
    {
      'title': {'ar': 'رابط غير آمن', 'en': 'Insecure'},
      'url': 'http://example.org/ep2.mp4',
    },
  ],
};

void main() {
  test('without a published order the app keeps its own', () {
    expect(librarySectionsFrom(null).map((e) => e.id), defaultLibraryOrder);
  });

  test('follows the dashboard order, hides and adds sections', () {
    final entries = librarySectionsFrom(
      feed([
        {'id': 'stories', 'kind': 'builtin', 'visible': true},
        tafsir,
        {'id': 'lessons', 'kind': 'builtin', 'visible': false},
        {'id': 'radio', 'kind': 'builtin', 'visible': true},
        {'id': 'unknown', 'kind': 'builtin', 'visible': true},
      ]),
    );
    final ids = entries.map((e) => e.id).toList();
    // Listed ones first, in order; hidden and unknown ones left out; built-ins
    // the feed does not mention keep their default order at the end.
    expect(ids, [
      'stories',
      's-abc123',
      'radio',
      'duas',
      'hadith',
      'names',
      'fiqh',
      'articles',
    ]);
    final links = entries.whereType<LinksEntry>().single;
    expect(links.title.en, 'Tafsir videos');
    // Only HTTPS links are kept.
    expect(links.links.map((l) => l.url.toString()), [
      'https://example.org/ep1.mp4',
    ]);
  });

  test('reads published season episodes without changing old links', () {
    final entries = librarySectionsFrom(
      feed([
        {
          ...tafsir,
          'seasons': [
            {
              'id': 'season-0123456789abcdef',
              'title': {'ar': 'الموسم الأول', 'en': 'Season 1'},
              'episodes': [
                {
                  'number': 2,
                  'title': {'ar': 'الثانية', 'en': 'Second'},
                  'media': {
                    'audio': {
                      'file': 'Library-0123456789abcdef0123456789abcdef.mp3',
                      'bytes': 2048,
                    },
                  },
                },
                {
                  'number': 1,
                  'title': {'ar': 'الأولى', 'en': 'First'},
                  'media': {
                    'video': {
                      'file': 'Library-fedcba9876543210fedcba9876543210.mp4',
                      'bytes': 4096,
                    },
                  },
                },
                {
                  'number': 3,
                  'title': {'ar': 'غير صالح', 'en': 'Invalid'},
                  'media': {
                    'audio': {'file': '../invalid.mp3', 'bytes': 2048},
                  },
                },
              ],
            },
          ],
        },
      ]),
    );
    final section = entries.whereType<LinksEntry>().single;
    expect(section.links, hasLength(1));
    final season = section.seasons.single;
    expect(season.title('en'), 'Season 1');
    expect(season.episodes.map((e) => e.number), [1, 2]);
    expect(season.queue(LessonFormat.audio, 1).single.number, 2);
    expect(season.queue(LessonFormat.video, 1).single.number, 1);
  });

  testWidgets('the library shows an added section and opens its links', (
    tester,
  ) async {
    await pumpMadarApp(
      tester,
      initialLocation: AppRoutes.library,
      additionalOverrides: [
        librarySectionsProvider.overrideWithValue(
          librarySectionsFrom(
            feed([
              tafsir,
              {'id': 'lessons', 'kind': 'builtin', 'visible': false},
            ]),
          ),
        ),
      ],
    );
    expect(find.text('Tafsir videos'), findsOneWidget);
    expect(
      find.byKey(ValueKey('section-card-${AppSection.lessons}')),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey('section-card-${AppSection.hadith}')),
      findsOneWidget,
    );

    await tester.tap(find.text('Tafsir videos'));
    await tester.pumpAndSettle();
    expect(find.byType(LinksSectionScreen), findsOneWidget);
    expect(find.text('A weekly series'), findsOneWidget);
    expect(find.byKey(const ValueKey('section-link-0')), findsOneWidget);
    expect(find.text('Insecure'), findsNothing);
  });
}
