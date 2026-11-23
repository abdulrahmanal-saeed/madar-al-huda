import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'learning_catalog.dart';

final learningFilesProvider = Provider<LearningFiles>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  final configured = Uri.tryParse(
    const String.fromEnvironment(
      'MADAR_LEARNING_MEDIA_BASE_URL',
      defaultValue: 'https://quran.abdulrahmanalsaeed.com/Prophet%20Stories/',
    ),
  );
  return LearningFiles(
    getApplicationSupportDirectory,
    client,
    base:
        configured?.scheme == 'https' &&
            configured?.host.isNotEmpty == true &&
            configured?.userInfo.isEmpty == true
        ? configured
        : null,
  );
});

final lessonSavedProvider = FutureProvider.family<bool, LessonMedia>(
  (ref, media) async =>
      await ref.watch(learningFilesProvider).saved(media) != null,
);

class LearningFiles {
  LearningFiles(this._directory, this._client, {this.base});

  final Future<Directory> Function() _directory;
  final http.Client _client;
  final Uri? base;
  final Map<String, Future<void>> _downloads = {};
  static const _timeout = Duration(seconds: 30);

  Uri? source(LessonMedia media) {
    final root = base;
    if (root == null) return null;
    return root.replace(
      pathSegments: [
        ...root.pathSegments.where((segment) => segment.isNotEmpty),
        media.fileName,
      ],
    );
  }

  Future<Uri> playable(LessonMedia media) async {
    final original = source(media);
    File? copy;
    try {
      copy = await saved(media);
    } on Exception {
      // Streaming can continue when app-private storage is unavailable.
    }
    return copy?.uri ??
        original ??
        (throw StateError('No learning media source'));
  }

  Future<File?> saved(LessonMedia media) async {
    final file = await _target(media);
    return await file.exists() && await file.length() == media.bytes
        ? file
        : null;
  }

  Future<void> remove(LessonMedia media) async {
    final file = await saved(media);
    if (file != null) await file.delete();
  }

  Future<File> _target(LessonMedia media) async {
    final root = await _directory();
    return File('${root.path}/learning-media-v1/${media.fileName}');
  }

  Future<void> download(LessonMedia media) => _downloads.putIfAbsent(
    media.fileName,
    () => _download(media).whenComplete(() {
      _downloads.remove(media.fileName);
    }),
  );

  Future<void> _download(LessonMedia media) async {
    if (await saved(media) != null) return;
    final uri = source(media);
    if (uri == null) throw StateError('No learning media source');
    final target = await _target(media);
    await target.parent.create(recursive: true);
    final partial = File('${target.path}.part');
    try {
      final input = await _openMedia(uri, media);
      final sink = partial.openWrite();
      var written = 0;
      try {
        await sink.addStream(
          input.map((chunk) {
            written += chunk.length;
            if (written > media.bytes) {
              throw const FormatException('Media exceeds catalog size');
            }
            return chunk;
          }),
        );
      } finally {
        await sink.close();
      }
      if (written != media.bytes) {
        throw const FormatException('Incomplete episode download');
      }
      await partial.rename(target.path);
    } finally {
      if (await partial.exists()) await partial.delete();
    }
  }

  Future<Stream<List<int>>> _openMedia(Uri uri, LessonMedia media) async {
    final request = http.Request('GET', uri)
      ..followRedirects = false
      ..headers['Accept'] = media.format.mimeType;
    final response = await _client.send(request).timeout(_timeout);
    final mime = response.headers['content-type']?.split(';').first.trim();
    if (response.statusCode != 200 ||
        (mime != media.format.mimeType && mime != 'application/octet-stream') ||
        (response.contentLength != null &&
            response.contentLength != media.bytes)) {
      await response.stream.listen(null).cancel();
      throw const FormatException('Unexpected episode response');
    }
    return response.stream.timeout(_timeout);
  }
}
