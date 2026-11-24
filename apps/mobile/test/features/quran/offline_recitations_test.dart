import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:madar_al_huda/core/audio/audio_playback.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/core/storage/key_value_store.dart';
import 'package:madar_al_huda/features/quran/data/chapter_reciters.dart';
import 'package:madar_al_huda/features/quran/data/offline_recitations.dart';
import 'package:madar_al_huda/features/quran/data/quran_services.dart';
import 'package:madar_al_huda/features/quran/presentation/recitation_player.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  final banna = publishedChapterReciters[1];
  final sobhi = publishedChapterReciters[2];
  final mp3 = [255, 251, 144, 100, 2, 3];

  test('Sobhi is only offered for the 93 verified chapters', () {
    final covered = [
      for (var chapter = 1; chapter <= 114; chapter++)
        if (chapterRecitersFor(chapter, []).contains(sobhi)) chapter,
    ];
    expect(covered, hasLength(93));
    expect(covered, contains(1));
    expect(covered, isNot(contains(112)));
    expect(banna.publisherAudio(112)?.path, endsWith('/112.mp3'));
    expect(sobhi.publisherAudio(112), isNull);
  });

  test('an incomplete download cannot appear in the offline library', () async {
    final dir = await Directory.systemTemp.createTemp('madar-download-test');
    addTearDown(() => dir.delete(recursive: true));
    var incomplete = true;
    final client = MockClient.streaming((request, _) async {
      expect(request.url, banna.publisherAudio(112));
      return http.StreamedResponse(
        Stream.value(mp3),
        200,
        headers: {'content-type': 'audio/mpeg'},
        contentLength: incomplete ? 20 : mp3.length,
      );
    });
    addTearDown(client.close);
    final library = OfflineAudioStore(() async => dir, client);
    await expectLater(
      library.download(banna, 112, (_) {}),
      throwsFormatException,
    );
    expect(await library.saved(), isEmpty);
    expect(await dir.list().toList(), isEmpty);

    incomplete = false;
    await library.download(banna, 112, (_) {});
    final file = await library.fileFor(banna, 112);
    expect(await file!.readAsBytes(), mp3);
    expect(await library.saved(), {offlineAudioKey(banna, 112)});
    await library.remove(banna, 112);
    expect(await library.saved(), isEmpty);
  });

  testWidgets('reader plays a saved recording with network unavailable', (
    tester,
  ) async {
    final dir = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('madar-offline-playback'),
    ))!;
    addTearDown(() => dir.delete(recursive: true));

    var online = true;
    var requests = 0;
    final client = MockClient((_) async {
      if (!online) throw StateError('Network disabled');
      requests++;
      return http.Response.bytes(
        mp3,
        200,
        headers: {'content-type': 'audio/mpeg'},
      );
    });
    final quran = MockClient((_) async => http.Response('', 503));
    addTearDown(client.close);
    addTearDown(quran.close);
    final library = OfflineAudioStore(() async => dir, client);
    final maher = publishedChapterReciters.first;
    await tester.runAsync(() async {
      for (final chapter in [112, 113, 114]) {
        await library.download(maher, chapter, (_) {});
      }
    });
    expect(requests, 3);
    online = false;
    final playback = (await tester.runAsync(() async => _RecordedPlayback()))!;
    const locale = Locale('en');
    final l10n = lookupAppLocalizations(locale);
    await pumpMadarApp(
      tester,
      deviceLocales: const [locale],
      initialLocation: AppRoutes.verse(112, 1),
      quranApi: QuranApi(quran, 'https://test.invalid/quran', 'test-public'),
      additionalOverrides: [
        offlineAudioStoreProvider.overrideWithValue(library),
        offlineAudioLibraryProvider.overrideWith(
          (_) => {offlineAudioKey(maher, 112)},
        ),
        audioPlaybackProvider.overrideWith(() => playback),
      ],
    );

    await tester.runAsync(() async {
      await tester.tap(find.byTooltip(l10n.recitationPlayOffline));
      await playback.started.future.timeout(const Duration(seconds: 5));
    });
    expect(playback.queue.map((item) => item.track.id), [
      '112:159',
      '113:159',
      '114:159',
    ]);
    expect(
      playback.queue.map((item) => item.source.url.scheme),
      everyElement('file'),
    );
    expect(requests, 3);
  });

  testWidgets(
    'playback starts at the selected chapter and skips uncovered chapters',
    (tester) async {
      final dir = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('madar-recitation-queue'),
      ))!;
      addTearDown(() => dir.delete(recursive: true));
      final client = MockClient((_) async => http.Response('', 503));
      addTearDown(client.close);
      final playback = (await tester.runAsync(
        () async => _RecordedPlayback(),
      ))!;
      final store = OfflineAudioStore(() async => dir, client);
      final l10n = lookupAppLocalizations(const Locale('en'));
      await pumpMadarApp(
        tester,
        initialLocation: AppRoutes.verse(2, 1),
        store: InMemoryKeyValueStore({reciterPreferenceKey: sobhi.key}),
        quranApi: QuranApi(client, 'https://test.invalid/quran', 'test-public'),
        additionalOverrides: [
          offlineAudioStoreProvider.overrideWithValue(store),
          offlineAudioLibraryProvider.overrideWith((_) => {}),
          audioPlaybackProvider.overrideWith(() => playback),
        ],
      );
      await tester.runAsync(() async {
        await tester.tap(find.byTooltip(l10n.readerListenChapter));
        await playback.started.future.timeout(const Duration(seconds: 5));
      });
      expect(playback.queue.take(2).map((item) => item.track.id), [
        '2:${sobhi.key}',
        '5:${sobhi.key}',
      ]);
      expect(playback.queue.last.track.id, '114:${sobhi.key}');
      expect(
        playback.queue.map((item) => item.source.url.host),
        everyElement('cdn.mp3quran.net'),
      );
    },
  );

  testWidgets(
    'the reader exposes a full Mushaf action that queues 114 downloads',
    (tester) async {
      final downloads = _RecordedDownloads();
      final client = MockClient((_) async => http.Response('', 503));
      addTearDown(client.close);
      final l10n = lookupAppLocalizations(const Locale('en'));
      await pumpMadarApp(
        tester,
        initialLocation: AppRoutes.mushaf,
        quranApi: QuranApi(client, 'https://test.invalid/quran', 'test-public'),
        additionalOverrides: [
          offlineAudioLibraryProvider.overrideWith((_) => {}),
          audioDownloadProvider.overrideWith(() => downloads),
        ],
      );
      await tester.tap(find.text(l10n.recitationDownloadMushaf));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.recitationDownloadSurahs('114')));
      await tester.pumpAndSettle();
      expect(downloads.requested, [
        for (var chapter = 1; chapter <= 114; chapter++) '159:$chapter',
      ]);
    },
  );
}

class _RecordedPlayback extends AudioPlayback {
  List<QueuedAudio> queue = [];
  final started = Completer<void>.sync();

  @override
  Future<void> startQueue(
    MediaItem track,
    Future<List<QueuedAudio>> Function() resolve,
  ) async {
    queue = await resolve();
    started.complete();
  }
}

class _RecordedDownloads extends AudioDownloads {
  final requested = <String>[];

  @override
  Future<void> download(ChapterReciter reader, int chapter) async {
    requested.add('${reader.key}:$chapter');
  }
}
