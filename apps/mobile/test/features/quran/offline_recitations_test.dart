import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:madar_al_huda/core/audio/audio_playback.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/features/quran/data/chapter_reciters.dart';
import 'package:madar_al_huda/features/quran/data/offline_recitations.dart';
import 'package:madar_al_huda/features/quran/data/quran_services.dart';
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

  testWidgets(
    'reader downloads and plays the saved file with network unavailable',
    (tester) async {
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
      final playback = _RecordedPlayback();
      const locale = Locale('en');
      final l10n = lookupAppLocalizations(locale);
      await pumpMadarApp(
        tester,
        deviceLocales: const [locale],
        initialLocation: AppRoutes.verse(112, 1),
        quranApi: QuranApi(quran, 'https://test.invalid/quran', 'test-public'),
        additionalOverrides: [
          offlineAudioStoreProvider.overrideWithValue(library),
          audioPlaybackProvider.overrideWith(() => playback),
        ],
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).last),
      );
      await tester.runAsync(() async {
        await tester.tap(find.byTooltip(l10n.recitationDownload));
        final deadline = DateTime.now().add(const Duration(seconds: 5));
        while (container.read(audioDownloadProvider) != null &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        expect(await container.read(offlineAudioLibraryProvider.future), {
          offlineAudioKey(publishedChapterReciters.first, 112),
        });
      });
      await tester.pumpAndSettle();
      expect(requests, 1);

      online = false;
      await tester.runAsync(() async {
        await tester.tap(find.byTooltip(l10n.recitationPlayOffline));
        await playback.started.future.timeout(const Duration(seconds: 5));
      });
      expect(playback.source!.url.scheme, 'file');
      expect(requests, 1);
    },
  );
}

class _RecordedPlayback extends AudioPlayback {
  PlaybackSource? source;
  final started = Completer<void>();

  @override
  Future<void> start(
    MediaItem track,
    Future<PlaybackSource> Function() resolve,
  ) async {
    source = await resolve();
    started.complete();
  }
}
