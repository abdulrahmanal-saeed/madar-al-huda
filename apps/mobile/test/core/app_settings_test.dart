import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/content/app_settings.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/features/learning/data/learning_catalog.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

void main() {
  final today = DateTime(2026, 11, 24);

  test('everything shows until the dashboard hides it', () {
    expect(AppSettings.fromFeed(null, today).hidden, isEmpty);
    expect(AppSettings.fromFeed({'version': 1}, today).announcement, isNull);
    final settings = AppSettings.fromFeed({
      'app': {
        'features': {'zakat': false, 'search': true, 'unknown': false},
        'announcement': {
          'ar': 'دورة جديدة',
          'en': '',
          'link': 'https://example.org/x',
          'until': '2026-11-30',
        },
      },
    }, today);
    expect(settings.hidden, {AppFeature.zakat});
    expect(settings.shows(AppFeature.search), isTrue);
    expect(settings.announcement?.ar, 'دورة جديدة');
    expect(settings.announcement?.en, 'دورة جديدة');
    expect(settings.announcement?.link?.host, 'example.org');
  });

  test('an ended announcement or an unsafe link is dropped', () {
    final ended = AppSettings.fromFeed({
      'app': {
        'announcement': {'ar': 'x', 'until': '2026-11-23'},
      },
    }, today);
    expect(ended.announcement, isNull);
    final plain = AppSettings.fromFeed({
      'app': {
        'announcement': {'ar': 'x', 'link': 'http://example.org'},
      },
    }, today);
    expect(plain.announcement?.link, isNull);
  });

  test('story descriptions and episode titles are read when present', () {
    final series = parseLearningCatalog([
      {
        'id': 'adam',
        'ar': 'آدم',
        'en': 'Adam',
        'description': {'ar': 'وصف', 'en': ''},
        'episodes': [
          {
            'number': 1,
            'title': {'ar': 'الخلق', 'en': 'Creation'},
            'media': {
              'audio': {'file': 'Madar-Adam-001.mp3', 'bytes': 10},
            },
          },
          {
            'number': 2,
            'media': {
              'audio': {'file': 'Madar-Adam-002.mp3', 'bytes': 10},
            },
          },
        ],
      },
    ]).single;
    expect(series.description, (ar: 'وصف', en: 'وصف'));
    expect(series.episodes.first.title, (ar: 'الخلق', en: 'Creation'));
    expect(series.episodes.last.title, isNull);
  });

  testWidgets('home hides switched-off features and shows the announcement', (
    tester,
  ) async {
    await pumpMadarApp(
      tester,
      initialLocation: AppRoutes.home,
      additionalOverrides: [
        appSettingsProvider.overrideWithValue(
          const AppSettings(
            hidden: {AppFeature.search, AppFeature.tasbih},
            announcement: (ar: 'إعلان', en: 'Notice', link: null),
          ),
        ),
      ],
    );
    expect(find.byKey(const ValueKey('home-search')), findsNothing);
    expect(find.text('Notice'), findsOneWidget);
    final qibla = find.byKey(const ValueKey('quick-access-AppSection.qibla'));
    await tester.scrollUntilVisible(
      qibla,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('quick-access-tasbih')), findsNothing);
    expect(qibla, findsOneWidget);
  });

  test('reads the radio stream and prayer verses set on the dashboard', () {
    final settings = AppSettings.fromFeed({
      'app': {
        'radio_url': 'https://radio.example/live',
        'prayer_verses': [
          [2, 45, 45],
          [20, 132, 132],
          ['x', 1, 1],
        ],
      },
    }, DateTime(2026));
    expect(settings.radioStream, Uri.https('radio.example', '/live'));
    expect(settings.prayerVerses, [(2, 45, 45), (20, 132, 132)]);
    final insecure = AppSettings.fromFeed({
      'app': {'radio_url': 'http://radio.example/live'},
    }, DateTime(2026));
    expect(insecure.radioStream, isNull);
    expect(insecure.prayerVerses, isEmpty);
  });
}
