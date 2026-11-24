import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

/// The media notification, lock screen and headset buttons for the app's
/// single [AudioPlayer]: it mirrors the player's state into the Android
/// media session and sends the buttons back to the player.
class MadarAudioHandler extends BaseAudioHandler with SeekHandler {
  MadarAudioHandler(this._player) {
    _subscriptions
      ..add(
        _player.playbackEventStream.listen(
          (_) => _publish(),
          // Player errors are handled by AudioPlayback; keep the session.
          onError: (Object _, StackTrace _) => _publish(),
        ),
      )
      ..add(_player.playingStream.listen((_) => _publish()))
      ..add(_player.sequenceStateStream.listen(_publishTrack))
      ..add(_player.durationStream.listen(_publishDuration));
  }

  final AudioPlayer _player;
  final _subscriptions = <StreamSubscription<Object?>>[];
  final _stopped = StreamController<void>.broadcast();

  /// Fires when the user stops playback from the notification.
  Stream<void> get stopped => _stopped.stream;

  bool get _live => mediaItem.value?.isLive ?? false;

  void _publish() {
    final sequence = _player.sequence;
    final index = _player.currentIndex;
    playbackState.add(
      playbackStateFor(
        playing: _player.playing,
        processing: _player.processingState,
        position: _player.position,
        buffered: _player.bufferedPosition,
        speed: _player.speed,
        index: index,
        live: _live,
        hasPrevious: index != null && index > 0,
        hasNext: index != null && index < sequence.length - 1,
      ),
    );
  }

  void _publishTrack(SequenceState? sequence) {
    final tags = [
      for (final source in sequence?.sequence ?? const <IndexedAudioSource>[])
        if (source.tag case final MediaItem item) item,
    ];
    queue.add(tags);
    final current = sequence?.currentSource?.tag;
    if (current is MediaItem) {
      mediaItem.add(current.copyWith(duration: _player.duration));
    }
    _publish();
  }

  void _publishDuration(Duration? duration) {
    final current = mediaItem.value;
    if (current != null && duration != null && current.duration != duration) {
      mediaItem.add(current.copyWith(duration: duration));
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> skipToQueueItem(int index) =>
      _player.seek(Duration.zero, index: index);

  @override
  Future<void> stop() async {
    await _player.stop();
    _stopped.add(null);
    await super.stop();
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _stopped.close();
  }
}

/// The media session state for the player's current state. Live radio has
/// no seeking or skipping; a queue of surahs can skip both ways.
PlaybackState playbackStateFor({
  required bool playing,
  required ProcessingState processing,
  required Duration position,
  required Duration buffered,
  required double speed,
  required bool live,
  required bool hasPrevious,
  required bool hasNext,
  int? index,
}) => PlaybackState(
  controls: [
    if (!live && hasPrevious) MediaControl.skipToPrevious,
    if (playing) MediaControl.pause else MediaControl.play,
    if (!live && hasNext) MediaControl.skipToNext,
    MediaControl.stop,
  ],
  systemActions: {
    if (!live) ...{
      MediaAction.seek,
      MediaAction.seekForward,
      MediaAction.seekBackward,
    },
  },
  androidCompactActionIndices: [
    if (!live && hasPrevious) 0,
    if (!live && hasPrevious) 1 else 0,
    if (!live && hasNext) (hasPrevious ? 2 : 1),
  ],
  processingState: switch (processing) {
    ProcessingState.idle => AudioProcessingState.idle,
    ProcessingState.loading => AudioProcessingState.loading,
    ProcessingState.buffering => AudioProcessingState.buffering,
    ProcessingState.ready => AudioProcessingState.ready,
    ProcessingState.completed => AudioProcessingState.completed,
  },
  playing: playing,
  updatePosition: live ? Duration.zero : position,
  bufferedPosition: live ? Duration.zero : buffered,
  speed: speed,
  queueIndex: index,
);

/// The media session handler, set in main() on Android; null in tests and
/// where the service could not start (playback still works, without the
/// notification).
final audioHandlerProvider = Provider<MadarAudioHandler?>((_) => null);
