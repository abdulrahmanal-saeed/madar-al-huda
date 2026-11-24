import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/features/quran/data/verse_timings.dart';
import 'package:madar_al_huda/features/quran/presentation/mushaf_page_view.dart';

import '../../helpers/pump_app.dart';

class _Recited extends RecitedVerseController {
  @override
  RecitedVerse? build() => null;

  // ignore: use_setters_to_change_properties
  void set(RecitedVerse? verse) => state = verse;
}

void main() {
  test('reads MP3Quran timing lists', () {
    expect(
      parseMp3QuranReads(
        '[{"id":123,"folder_url":"https://cdn.mp3quran.net/audio/mishary-alafasy/r1/"},'
        '{"id":5,"folder_url":"http://cdn.mp3quran.net/audio/x/r1/"}]',
      ),
      {
        'https://cdn.mp3quran.net/audio/mishary-alafasy/r1/': 123,
        'https://cdn.mp3quran.net/audio/x/r1/': 5,
      },
    );
    expect(
      parseMp3QuranTimings(
        '[{"ayah":0,"start_time":0},{"ayah":1,"start_time":6420},'
        '{"ayah":2,"start_time":11120}]',
      ),
      {1: 6420, 2: 11120},
    );
  });

  test('a complete timeline finds the verse at any position', () {
    final timeline = VerseTimeline.complete({1: 6420, 2: 11120, 3: 17640});
    expect(timeline.ayahAt(const Duration(seconds: 1)), isNull);
    expect(timeline.ayahAt(const Duration(milliseconds: 6420)), 1);
    expect(timeline.ayahAt(const Duration(seconds: 12)), 2);
    expect(timeline.ayahAt(const Duration(minutes: 5)), 3);
  });

  test('a timeline found ahead keeps three verses known', () async {
    final asked = <int>[];
    final timeline = VerseTimeline.ahead(
      (ayah) async {
        asked.add(ayah);
        return ayah * 10000;
      },
      verses: 20,
      from: 5,
    );
    await timeline.prime();
    expect(asked, [5, 6, 7, 8]);
    expect(timeline.ayahAt(const Duration(seconds: 61)), 6);
    await Future<void>.delayed(Duration.zero);
    expect(asked.last, 9);
  });

  testWidgets('the Mushaf marks and follows the recited verse', (tester) async {
    final recited = _Recited();
    await pumpMadarApp(
      tester,
      initialLocation: AppRoutes.verse(2, 1),
      additionalOverrides: [recitedVerseProvider.overrideWith(() => recited)],
    );
    await tester.pumpAndSettle();

    bool marked(int surah, int ayah) => tester
        .widgetList<MushafPageView>(find.byType(MushafPageView))
        .any(
          (page) =>
              page.selected?.surah == surah && page.selected?.ayah == ayah,
        );

    recited.set((surah: 2, ayah: 3));
    await tester.pumpAndSettle();
    expect(marked(2, 3), isTrue);

    // Many pages on: the reader jumps there and marks it.
    recited.set((surah: 2, ayah: 255));
    await tester.pumpAndSettle();
    expect(marked(2, 255), isTrue);
  });
}
