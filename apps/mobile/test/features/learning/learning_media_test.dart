import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:madar_al_huda/core/audio/audio_playback.dart';
import 'package:madar_al_huda/features/learning/data/learning_catalog.dart';
import 'package:madar_al_huda/features/learning/data/learning_files.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('matches both formats and queues Adam’s episodes in order', () async {
    final source = await rootBundle.loadString(
      'assets/learning/prophet_stories.json',
    );
    final catalog = parseLearningSeries(source);
    final adam = catalog.first;
    expect(adam.id, 'adam');
    for (final format in LessonFormat.values) {
      expect(adam.queue(format, 1).map((item) => item.number), [
        1,
        2,
        3,
        4,
        5,
        6,
      ]);
      expect(adam.queue(format, 4).map((item) => item.number), [4, 5, 6]);
      expect(
        adam.episodes.last.media[format]?.fileName,
        'Madar-Adam-006.${format.extension}',
      );
    }
    expect(catalog.last.id, 'idris');
    expect(catalog.last.episodes, isEmpty);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final first = adam.episodes.first.media[LessonFormat.audio]!;
    expect(
      container.read(learningFilesProvider).source(first).toString(),
      'https://quran.abdulrahmanalsaeed.com/Prophet%20Stories/Madar-Adam-001.mp3',
    );
  });

  test('only complete downloads play offline in the chosen format', () async {
    final dir = await Directory.systemTemp.createTemp('madar-learning-test');
    addTearDown(() => dir.delete(recursive: true));
    const audio = LessonMedia('adam-001.mp3', 4, LessonFormat.audio);
    const video = LessonMedia('adam-001.mp4', 4, LessonFormat.video);
    final files = LearningFiles(
      () async => dir,
      MockClient.streaming((request, body) async {
        final complete = request.url.path.endsWith(audio.fileName);
        return http.StreamedResponse(
          Stream.value(complete ? [1, 2, 3, 4] : [1, 2]),
          200,
          contentLength: 4,
          headers: {'content-type': complete ? 'audio/mpeg' : 'video/mp4'},
        );
      }),
      base: Uri.https('media.example.test', '/learning/v1'),
    );
    await expectLater(files.download(video), throwsFormatException);
    expect(await files.saved(video), isNull);
    await files.download(audio);
    expect((await files.playable(audio)).scheme, 'file');
    expect((await files.playable(video)).scheme, 'https');
    expect(
      (await dir.list(recursive: true).toList()).whereType<File>().length,
      1,
    );
    await files.remove(audio);
    expect(await files.saved(audio), isNull);
  });

  test(
    'the shared audio session receives an ordered native playlist',
    () async {
      final player = _QueuePlayer();
      final container = ProviderContainer(
        overrides: [audioPlayerProvider.overrideWithValue(player)],
      );
      addTearDown(() async {
        container.dispose();
        await player.positions.close();
      });
      final queue = [
        for (var number = 2; number <= 4; number++)
          (
            track: MediaItem(id: 'adam:$number', title: 'Episode $number'),
            source: (
              url: Uri.https('media.example.test', '/$number.mp3'),
              start: null,
            ),
          ),
      ];
      await container
          .read(audioPlaybackProvider.notifier)
          .startQueue(queue.first.track, () async => queue);
      expect(player.ids, ['adam:2', 'adam:3', 'adam:4']);
      expect(player.startedAt, 0);
      expect(container.read(audioPlaybackProvider).track?.id, 'adam:2');
      player.positions.add(1);
      expect(container.read(audioPlaybackProvider).track?.id, 'adam:3');
      await container.read(audioPlaybackProvider.notifier).stop();
      player.positions.add(2);
      expect(container.read(audioPlaybackProvider).track, isNull);
    },
  );
}

class _QueuePlayer extends Fake implements AudioPlayer {
  final positions = StreamController<int?>.broadcast(sync: true);
  List<String> ids = [];
  int? startedAt;

  @override
  Stream<PlayerException> get errorStream => const Stream.empty();

  @override
  Stream<int?> get currentIndexStream => positions.stream;

  @override
  Future<Duration?> setAudioSources(
    List<AudioSource> audioSources, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
    ShuffleOrder? shuffleOrder,
  }) async {
    ids = audioSources
        .map((source) => ((source as IndexedAudioSource).tag as MediaItem).id)
        .toList();
    startedAt = initialIndex;
    return null;
  }

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {}
}
