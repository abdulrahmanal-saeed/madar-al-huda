import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/audio/audio_playback.dart';
import '../../../core/storage/storage_providers.dart';
import 'verse_timings.dart';

/// Where the last recitation stopped: the reciter, the surah, the position
/// in its recording and, when known, the verse.
typedef SavedRecitation = ({String reader, int surah, int ms, int? ayah});

const lastRecitationKey = 'quran.lastRecitation.v1';

SavedRecitation? decodeSavedRecitation(String? raw) {
  if (raw == null) return null;
  try {
    final data = jsonDecode(raw);
    if (data is! Map<String, dynamic>) return null;
    final reader = data['reader'];
    final surah = data['surah'];
    final ms = data['ms'];
    final ayah = data['ayah'];
    if (reader is! String ||
        reader.isEmpty ||
        surah is! int ||
        surah < 1 ||
        surah > 114 ||
        ms is! int ||
        ms < 0) {
      return null;
    }
    return (
      reader: reader,
      surah: surah,
      ms: ms,
      ayah: ayah is int && ayah >= 1 ? ayah : null,
    );
  } on Object {
    return null;
  }
}

String encodeSavedRecitation(SavedRecitation saved) => jsonEncode({
  'reader': saved.reader,
  'surah': saved.surah,
  'ms': saved.ms,
  'ayah': ?saved.ayah,
});

final savedRecitationProvider =
    NotifierProvider<SavedRecitationController, SavedRecitation?>(
      SavedRecitationController.new,
    );

class SavedRecitationController extends Notifier<SavedRecitation?> {
  @override
  SavedRecitation? build() {
    try {
      return decodeSavedRecitation(
        ref.read(keyValueStoreProvider).getString(lastRecitationKey),
      );
    } on Object {
      return null;
    }
  }

  Future<void> save(SavedRecitation saved) async {
    if (saved == state) return;
    state = saved;
    try {
      await ref
          .read(keyValueStoreProvider)
          .setString(lastRecitationKey, encodeSavedRecitation(saved));
    } on Object {
      // Kept for this session if storage fails.
    }
  }
}

/// The reciter key in a recitation track id («surah:reader»).
String? readerOfTrack(String id) {
  final split = id.indexOf(':');
  return split < 1 || split == id.length - 1 ? null : id.substring(split + 1);
}

/// Keeps the place of the recitation playing now, so the Mushaf can offer
/// to continue it after the app is closed.
class RecitationMemory extends ConsumerStatefulWidget {
  const RecitationMemory({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<RecitationMemory> createState() => _RecitationMemoryState();
}

class _RecitationMemoryState extends ConsumerState<RecitationMemory> {
  StreamSubscription<Duration>? _positions;
  int _lastSavedMs = -1;

  void _watch(String? trackId) {
    unawaited(_positions?.cancel());
    _positions = null;
    _lastSavedMs = -1;
    final track = ref.read(audioPlaybackProvider).track;
    final surah = track?.extras?[recitationSurahExtra];
    final reader = trackId == null ? null : readerOfTrack(trackId);
    if (track == null || surah is! int || reader == null) return;
    final player = ref.read(audioPlayerProvider);
    _positions = player.positionStream.listen((position) {
      // Stopping or finishing reports positions that are not a place to
      // come back to.
      if (player.processingState == ProcessingState.idle ||
          player.processingState == ProcessingState.completed) {
        return;
      }
      final ms = position.inMilliseconds;
      // Every few seconds of listening, and on any jump.
      if (_lastSavedMs >= 0 && (ms - _lastSavedMs).abs() < 4000) return;
      _lastSavedMs = ms;
      final recited = ref.read(recitedVerseProvider);
      unawaited(
        ref.read(savedRecitationProvider.notifier).save((
          reader: reader,
          surah: surah,
          ms: ms,
          ayah: recited?.surah == surah ? recited?.ayah : null,
        )),
      );
    }, onError: (Object _) {});
  }

  @override
  void initState() {
    super.initState();
    _watch(ref.read(audioPlaybackProvider).track?.id);
  }

  @override
  void dispose() {
    unawaited(_positions?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(
      audioPlaybackProvider.select((playback) => playback.track?.id),
      (_, id) => _watch(id),
    );
    return widget.child;
  }
}
