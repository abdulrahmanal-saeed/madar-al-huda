import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'chapter_reciters.dart';

typedef OfflineAudioKey = ({String reciterKey, int chapter});
typedef AudioDownload = ({OfflineAudioKey key, double? progress});

final offlineAudioStoreProvider = Provider<OfflineAudioStore>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return OfflineAudioStore(() async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}/recitation-audio-v1');
  }, client);
});

final offlineAudioLibraryProvider = FutureProvider<Set<OfflineAudioKey>>(
  (ref) => ref
      .watch(offlineAudioStoreProvider)
      .saved(ref.watch(reciterSelectionProvider).all),
);

final audioDownloadProvider = NotifierProvider<AudioDownloads, AudioDownload?>(
  AudioDownloads.new,
);

OfflineAudioKey offlineAudioKey(ChapterReciter reciter, int chapter) =>
    (reciterKey: reciter.key, chapter: chapter);

class AudioDownloads extends Notifier<AudioDownload?> {
  @override
  AudioDownload? build() => null;

  Future<void> download(ChapterReciter reader, int chapter) async {
    if (state != null) return;
    final key = offlineAudioKey(reader, chapter);
    state = (key: key, progress: null);
    try {
      await ref.read(offlineAudioStoreProvider).download(reader, chapter, (
        value,
      ) {
        if (!ref.mounted) return;
        final previous = state?.progress;
        if (value != null &&
            (previous == null || value - previous >= .02 || value == 1)) {
          state = (key: key, progress: value);
        }
      });
      if (ref.mounted) ref.invalidate(offlineAudioLibraryProvider);
    } finally {
      if (ref.mounted) state = null;
    }
  }

  Future<void> remove(ChapterReciter reader, int chapter) async {
    await ref.read(offlineAudioStoreProvider).remove(reader, chapter);
    if (ref.mounted) ref.invalidate(offlineAudioLibraryProvider);
  }
}

/// Stores only explicit user downloads from the licensed MP3Quran recordings.
/// A partially written file never appears in the playable library.
class OfflineAudioStore {
  const OfflineAudioStore(this._directory, this._client);

  final Future<Directory> Function() _directory;
  final http.Client _client;
  static const _maxBytes = 256 * 1024 * 1024;
  static const _timeout = Duration(seconds: 30);
  static final _name = RegExp(r'^(.+)_(\d{1,3})\.mp3$');

  Future<Set<OfflineAudioKey>> saved([
    Iterable<ChapterReciter> readers = publishedChapterReciters,
  ]) async {
    final dir = await _directory();
    if (!await dir.exists()) return {};
    final entries = <OfflineAudioKey>{};
    await for (final path in dir.list(followLinks: false)) {
      if (path is! File) continue;
      final match = _name.firstMatch(path.uri.pathSegments.last);
      if (match == null) continue;
      final chapter = int.parse(match[2]!);
      final reader = readers.where((item) => item.key == match[1]).firstOrNull;
      if (reader != null && reader.covers(chapter) && await path.length() > 3) {
        entries.add(offlineAudioKey(reader, chapter));
      }
    }
    return entries;
  }

  Future<File?> fileFor(ChapterReciter reader, int chapter) async {
    if (reader.publisherAudio(chapter) == null) return null;
    final dir = await _directory();
    final file = _file(dir, reader, chapter);
    return await file.exists() && await file.length() > 3 ? file : null;
  }

  Future<Map<int, Uri>> filesFor(
    ChapterReciter reader,
    Iterable<int> chapters,
  ) async {
    final dir = await _directory();
    final files = <int, Uri>{};
    for (final chapter in chapters) {
      if (reader.publisherAudio(chapter) == null) continue;
      final file = _file(dir, reader, chapter);
      if (await file.exists() && await file.length() > 3) {
        files[chapter] = file.uri;
      }
    }
    return files;
  }

  Future<void> remove(ChapterReciter reader, int chapter) async {
    final file = await fileFor(reader, chapter);
    if (file != null) await file.delete();
  }

  File _file(Directory dir, ChapterReciter reader, int chapter) =>
      File('${dir.path}/${reader.key}_$chapter.mp3');

  Future<void> download(
    ChapterReciter reader,
    int chapter,
    void Function(double?) onProgress,
  ) async {
    final url = reader.publisherAudio(chapter);
    if (url == null) throw StateError('No offline edition for this chapter');
    final dir = await _directory();
    await dir.create(recursive: true);
    final target = _file(dir, reader, chapter);
    if (await target.exists() && await target.length() > 3) return;
    final partial = File('${target.path}.part');
    IOSink? sink;
    try {
      final request = http.Request('GET', url)
        ..followRedirects = false
        ..headers['Accept'] = 'audio/mpeg';
      final response = await _client.send(request).timeout(_timeout);
      final expected = response.contentLength;
      final type = response.headers['content-type']?.split(';').first.trim();
      if (response.statusCode != 200 ||
          type != 'audio/mpeg' ||
          (expected != null && (expected < 4 || expected > _maxBytes))) {
        await response.stream.listen(null).cancel();
        throw const FormatException('Invalid chapter recording response');
      }

      sink = partial.openWrite();
      final prefix = <int>[];
      var received = 0;
      await sink.addStream(
        response.stream.timeout(_timeout).map((bytes) {
          if (prefix.length < 3) {
            prefix.addAll(bytes.take(3 - prefix.length));
            if (prefix.length == 3 && !_isMp3(prefix)) {
              throw const FormatException('Invalid MP3 header');
            }
          }
          received += bytes.length;
          if (received > _maxBytes ||
              (expected != null && received > expected)) {
            throw const FormatException(
              'Recording exceeds its expected length',
            );
          }
          onProgress(
            expected == null ? null : math.min(1, received / expected),
          );
          return bytes;
        }),
      );
      await sink.close();
      sink = null;
      if (received < 4 || (expected != null && received != expected)) {
        throw const FormatException('Incomplete chapter recording');
      }
      await partial.rename(target.path);
    } finally {
      try {
        await sink?.close();
      } finally {
        if (await partial.exists()) await partial.delete();
      }
    }
  }

  bool _isMp3(List<int> bytes) =>
      (bytes[0] == 73 && bytes[1] == 68 && bytes[2] == 51) ||
      (bytes[0] == 255 && bytes[1] & 224 == 224);
}
