import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

typedef PlaybackSource = ({Uri url, Duration? start});
typedef Playback = ({MediaItem? track, MediaItem? pending, String? failedId});

final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(() => unawaited(player.dispose()));
  return player;
});

final audioPlaybackProvider = NotifierProvider<AudioPlayback, Playback>(
  AudioPlayback.new,
);

/// One player and one Android media session for recitation and live radio.
class AudioPlayback extends Notifier<Playback> {
  int _request = 0;
  StreamSubscription<PlayerException>? _errors;

  @override
  Playback build() {
    ref.onDispose(() => unawaited(_errors?.cancel()));
    return (track: null, pending: null, failedId: null);
  }

  Future<void> start(
    MediaItem track,
    Future<PlaybackSource> Function() resolve,
  ) async {
    if (state.pending != null) return;
    final request = ++_request;
    state = (track: state.track, pending: track, failedId: null);
    try {
      final source = await resolve();
      if (!_isCurrent(request)) return;
      final player = ref.read(audioPlayerProvider);
      _errors ??= player.errorStream.listen((_) {
        final playing = state.track;
        if (playing != null && state.pending == null) {
          _onPlaybackError(playing, player, _request);
        }
      });
      await player.pause();
      if (!_isCurrent(request)) return;
      state = (track: null, pending: track, failedId: null);
      try {
        await player
            .setAudioSource(
              AudioSource.uri(source.url, tag: track),
              initialPosition: source.start,
            )
            .timeout(const Duration(seconds: 20));
      } on TimeoutException {
        if (_isCurrent(request)) await player.stop();
        rethrow;
      }
      if (!_isCurrent(request)) return;
      state = (track: track, pending: null, failedId: null);
      _play(track, player, request);
    } catch (_) {
      if (!_isCurrent(request)) return;
      state = (track: state.track, pending: null, failedId: track.id);
      rethrow;
    }
  }

  bool _isCurrent(int request) => ref.mounted && request == _request;

  void _play(MediaItem track, AudioPlayer player, int request) {
    unawaited(
      player.play().catchError((Object _) {
        _onPlaybackError(track, player, request);
      }),
    );
  }

  void _onPlaybackError(MediaItem track, AudioPlayer player, int request) {
    if (!_isCurrent(request) ||
        state.track?.id != track.id ||
        state.failedId == track.id) {
      return;
    }
    if (track.isLive == true) {
      state = (track: null, pending: null, failedId: track.id);
      unawaited(player.stop().catchError((Object _) {}));
    } else {
      state = (track: track, pending: null, failedId: track.id);
      unawaited(player.pause().catchError((Object _) {}));
    }
  }

  Future<void> resume() async {
    final track = state.track;
    if (track == null || state.pending != null) return;
    final player = ref.read(audioPlayerProvider);
    final request = ++_request;
    if (player.processingState == ProcessingState.completed) {
      await player.seek(Duration.zero);
    }
    if (!_isCurrent(request)) return;
    state = (track: track, pending: null, failedId: null);
    _play(track, player, request);
  }

  Future<void> pause() async {
    final request = ++_request;
    final track = state.track;
    try {
      if (track != null) await ref.read(audioPlayerProvider).pause();
      if (track == null && state.pending != null) {
        // The pending source may already be loading in the native player.
        await ref.read(audioPlayerProvider).stop();
      }
    } finally {
      if (_isCurrent(request)) {
        state = (track: track, pending: null, failedId: state.failedId);
      }
    }
  }

  Future<void> stop() async {
    final request = ++_request;
    try {
      if (state.track != null || state.pending != null) {
        await ref.read(audioPlayerProvider).stop();
      }
    } finally {
      if (_isCurrent(request)) {
        state = (track: null, pending: null, failedId: null);
      }
    }
  }
}
