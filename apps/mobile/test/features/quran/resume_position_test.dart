import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/audio/audio_playback.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/features/quran/data/quran_services.dart';
import 'package:madar_al_huda/features/quran/data/verse_timings.dart';
import 'package:madar_al_huda/features/quran/presentation/mushaf_page_view.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

class _ChangingRecitation extends AudioPlayback {
  Playback _chapter(int number) => (
    track: MediaItem(
      id: 'chapter-$number',
      title: 'Chapter $number',
      extras: {recitationSurahExtra: number},
    ),
    pending: null,
    failedId: null,
  );

  @override
  Playback build() => _chapter(1);

  void nextChapter() => state = _chapter(2);
}

void main() {
  testWidgets('the Mushaf reopens where reading stopped', (tester) async {
    final store = await pumpMadarApp(tester, initialLocation: AppRoutes.quran);
    for (var i = 0; i < 6; i++) {
      await tester.fling(
        find.byType(Scrollable).first,
        const Offset(0, -2500),
        3000,
      );
      await tester.pumpAndSettle();
    }
    final saved = store.getString(LocalReadingPosition.key)!;
    expect(saved, contains('"tanzil-uthmani-1.1",2,'));

    // A fresh start of the app opens the same page.
    await pumpMadarApp(tester, initialLocation: AppRoutes.quran, store: store);
    final pages = tester
        .widgetList<MushafPageView>(find.byType(MushafPageView))
        .map((page) => page.index);
    expect(pages.first, greaterThan(4));
  });

  testWidgets('a new chapter opens its page even without verse timings', (
    tester,
  ) async {
    final playback = _ChangingRecitation();
    final store = await pumpMadarApp(
      tester,
      initialLocation: AppRoutes.quran,
      additionalOverrides: [audioPlaybackProvider.overrideWith(() => playback)],
    );

    playback.nextChapter();
    await tester.pumpAndSettle();

    final page = tester
        .widgetList<MushafPageView>(find.byType(MushafPageView))
        .firstWhere((page) => page.index == 1);
    expect(page.selected, isNull);
    expect(
      store.getString(LocalReadingPosition.key),
      contains('"tanzil-uthmani-1.1",2,1'),
    );
  });
}
