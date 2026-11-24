import 'dart:async';
import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/audio/audio_playback.dart';
import '../domain/quran_storage_contracts.dart';
import 'mushaf_edition.dart';
import 'quran_services.dart';

/// MediaItem extras that say where a recitation's verse times come from.
const recitationSurahExtra = 'surah';
const recitationTimingExtra = 'timing';

/// The extras for a surah whose times come from [source]
/// (see [mp3QuranTiming] and [foundationTiming]).
Map<String, dynamic> recitationExtras(int surah, String? source) => {
  recitationSurahExtra: surah,
  recitationTimingExtra: ?source,
};

/// Times published by MP3Quran for the recording in [folder].
String mp3QuranTiming(Uri folder) => 'mp3quran:$folder';

/// Times from Quran Foundation for recitation [resource].
String foundationTiming(int resource) => 'qf:$resource';

/// When each verse of one surah starts in a recording, in milliseconds.
/// Times may be known for every verse at once, or found a few verses ahead
/// of the reciter.
class VerseTimeline {
  VerseTimeline.complete(Map<int, int> starts) : _starts = Map.of(starts) {
    _complete = true;
  }

  VerseTimeline.ahead(this._find, {required this.verses, int from = 1})
    : _starts = {} {
    _next = from;
  }

  final Map<int, int> _starts;
  Future<int?> Function(int ayah)? _find;
  int verses = 0;
  bool _complete = false;
  int _next = 1;
  bool _finding = false;

  /// The verse being recited at [position], or null before the first known
  /// verse or where the times are not known yet.
  int? ayahAt(Duration position) {
    final ms = position.inMilliseconds;
    int? current;
    for (final MapEntry(key: ayah, value: start) in _starts.entries) {
      if (start <= ms && (current == null || ayah > current)) current = ayah;
    }
    if (!_complete && current != null) unawaited(_findAhead(current));
    return current;
  }

  /// Starts finding times from the first verse played.
  Future<void> prime() => _findAhead(_next);

  Future<void> _findAhead(int current) async {
    final find = _find;
    if (find == null || _finding) return;
    _finding = true;
    try {
      // Keep three verses known ahead of the reciter.
      while (_next <= verses && _next <= current + 3) {
        final start = await find(_next);
        if (start == null) {
          _find = null;
          return;
        }
        _starts[_next] = start;
        _next++;
      }
    } on Object {
      _find = null;
    } finally {
      _finding = false;
    }
  }
}

/// Fetches verse times. MP3Quran publishes them for many recordings; Quran
/// Foundation gives one verse at a time through the app's Quran service.
class VerseTimingApi {
  VerseTimingApi(this._client, this._quran);

  final http.Client _client;
  final QuranApi _quran;
  Future<Map<String, int>>? _reads;
  final _timelines = <String, Future<VerseTimeline?>>{};

  static final _readsUrl = Uri.https(
    'www.mp3quran.net',
    '/api/v3/ayat_timing/reads',
  );

  /// The timeline for [surah] from [source], or null when it has none.
  Future<VerseTimeline?> timeline(
    String source,
    int surah, {
    required int verses,
    int from = 1,
  }) {
    final key = '$source|$surah';
    if (source.startsWith('qf:')) {
      final resource = int.tryParse(source.substring(3));
      if (resource == null) return Future.value();
      // Not cached: each play starts finding from its own first verse.
      final timeline = VerseTimeline.ahead(
        (ayah) => _foundationStart(resource, surah, ayah),
        verses: verses,
        from: from,
      );
      return timeline.prime().then((_) => timeline);
    }
    return _timelines[key] ??= _mp3Quran(source.substring(9), surah).then((
      timeline,
    ) {
      if (timeline == null) unawaited(_forget(key));
      return timeline;
    });
  }

  Future<void> _forget(String key) async => _timelines.remove(key);

  Future<int?> _foundationStart(int resource, int surah, int ayah) async {
    try {
      final at = await _quran.audioAtVerse(
        AyahRef(editionId: 'recitation', surah: surah, ayah: ayah),
        resource,
      );
      return at.start.inMilliseconds;
    } on Object {
      return null;
    }
  }

  Future<VerseTimeline?> _mp3Quran(String folder, int surah) async {
    if (!folder.startsWith('https://')) return null;
    try {
      final reads = await (_reads ??= _loadReads());
      final read = reads[folder];
      if (read == null) return null;
      final response = await _client
          .get(
            Uri.https('www.mp3quran.net', '/api/v3/ayat_timing', {
              'surah': '$surah',
              'read': '$read',
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return null;
      final starts = parseMp3QuranTimings(response.body);
      return starts.isEmpty ? null : VerseTimeline.complete(starts);
    } on Object {
      return null;
    }
  }

  Future<Map<String, int>> _loadReads() async {
    try {
      final response = await _client
          .get(_readsUrl)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) throw StateError('reads');
      return parseMp3QuranReads(response.body);
    } on Object {
      _reads = null;
      rethrow;
    }
  }
}

/// MP3Quran's recordings that have verse times: folder URL → read id.
Map<String, int> parseMp3QuranReads(String body) {
  final data = jsonDecode(body);
  return {
    if (data is List)
      for (final row in data.whereType<Map<String, dynamic>>())
        if (row['folder_url'] case final String folder)
          if (row['id'] case final int id)
            folder.replaceFirst('http://', 'https://'): id,
  };
}

/// Verse start times (ayah → ms) from MP3Quran's ayat_timing response.
Map<int, int> parseMp3QuranTimings(String body) {
  final data = jsonDecode(body);
  return {
    if (data is List)
      for (final row in data.whereType<Map<String, dynamic>>())
        if (row['ayah'] case final int ayah when ayah >= 1)
          if (row['start_time'] case final int start when start >= 0)
            ayah: start,
  };
}

final verseTimingApiProvider = Provider<VerseTimingApi>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return VerseTimingApi(client, ref.watch(quranApiProvider));
});

typedef RecitedVerse = ({int surah, int ayah});

/// The verse the reciter is reading now, when the playing recitation has
/// verse times; null otherwise.
final recitedVerseProvider =
    NotifierProvider<RecitedVerseController, RecitedVerse?>(
      RecitedVerseController.new,
    );

class RecitedVerseController extends Notifier<RecitedVerse?> {
  @override
  RecitedVerse? build() {
    final trackId = ref.watch(
      audioPlaybackProvider.select((playback) => playback.track?.id),
    );
    if (trackId == null) return null;
    final track = ref.read(audioPlaybackProvider).track;
    final extras = track?.extras;
    final surah = extras?[recitationSurahExtra];
    final source = extras?[recitationTimingExtra];
    if (surah is! int || source is! String) return null;
    StreamSubscription<Duration>? positions;
    var active = true;
    ref.onDispose(() {
      active = false;
      unawaited(positions?.cancel());
    });
    unawaited(() async {
      final edition = await ref.read(mushafEditionProvider.future);
      if (!active || surah > edition.surahs.length) return;
      final player = ref.read(audioPlayerProvider);
      final timeline = await ref
          .read(verseTimingApiProvider)
          .timeline(
            source,
            surah,
            verses: edition.surahs[surah - 1].verses.length,
            from: _firstAyah(track),
          );
      if (!active || timeline == null) return;
      positions = player.positionStream.listen((position) {
        final ayah = timeline.ayahAt(position);
        final next = ayah == null ? null : (surah: surah, ayah: ayah);
        if (next != state) state = next;
      });
    }());
    return null;
  }

  static int _firstAyah(MediaItem? track) {
    final from = track?.extras?['fromAyah'];
    return from is int && from >= 1 ? from : 1;
  }
}
