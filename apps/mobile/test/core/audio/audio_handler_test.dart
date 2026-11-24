import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:madar_al_huda/core/audio/audio_handler.dart';

void main() {
  PlaybackState state({
    bool playing = true,
    bool live = false,
    bool hasPrevious = false,
    bool hasNext = false,
  }) => playbackStateFor(
    playing: playing,
    processing: ProcessingState.ready,
    position: const Duration(seconds: 30),
    buffered: const Duration(seconds: 60),
    speed: 1,
    live: live,
    hasPrevious: hasPrevious,
    hasNext: hasNext,
    index: 1,
  );

  test('a surah in the middle of a queue can skip both ways and seek', () {
    final playing = state(hasPrevious: true, hasNext: true);
    expect(playing.controls, [
      MediaControl.skipToPrevious,
      MediaControl.pause,
      MediaControl.skipToNext,
      MediaControl.stop,
    ]);
    expect(playing.androidCompactActionIndices, [0, 1, 2]);
    expect(playing.systemActions, contains(MediaAction.seek));
    expect(playing.updatePosition, const Duration(seconds: 30));
    expect(playing.processingState, AudioProcessingState.ready);
  });

  test('the first surah shows play and next only', () {
    final paused = state(playing: false, hasNext: true);
    expect(paused.controls, [
      MediaControl.play,
      MediaControl.skipToNext,
      MediaControl.stop,
    ]);
    expect(paused.androidCompactActionIndices, [0, 1]);
  });

  test('live radio has no skipping or seeking', () {
    final radio = state(live: true, hasPrevious: true, hasNext: true);
    expect(radio.controls, [MediaControl.pause, MediaControl.stop]);
    expect(radio.androidCompactActionIndices, [0]);
    expect(radio.systemActions, isEmpty);
    expect(radio.updatePosition, Duration.zero);
  });
}
