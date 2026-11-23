import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

final hostedFeedProvider = Provider<HostedFeed>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return HostedFeed(client, getApplicationSupportDirectory);
});

class HostedFeed {
  HostedFeed(this._client, this._directory);

  final http.Client _client;
  final Future<Directory> Function() _directory;
  static const _timeout = Duration(seconds: 5);
  static const _maxBytes = 1024 * 1024;

  Future<T> load<T>({
    required Uri? url,
    required String cacheName,
    required T Function(Object?) decode,
    required Future<T> Function() fallback,
  }) async {
    if (url == null) return fallback();
    File? file;
    String? etag;
    T? saved;
    try {
      file = File('${(await _directory()).path}/$cacheName.json');
      if (await file.exists() && await file.length() < _maxBytes * 2) {
        final cache = jsonDecode(await file.readAsString()) as Map;
        if (cache['url'] == url.toString()) {
          saved = decode(jsonDecode(cache['body'] as String));
          etag = cache['etag'] as String?;
        }
      }
    } catch (_) {
      // A corrupted or inaccessible cache can be replaced by the server.
    }

    try {
      final response = await _fetch(url, etag).timeout(_timeout);
      if (response == null && saved != null) return saved;
      if (response != null) {
        final result = decode(jsonDecode(response.body));
        if (file != null) {
          await _save(file, url, response.body, response.etag);
        }
        return result;
      }
    } catch (_) {
      // Keep the last validated catalog when the server or connection fails.
    }
    return saved ?? await fallback();
  }

  Future<({String body, String? etag})?> _fetch(Uri url, String? etag) async {
    final request = http.Request('GET', url)
      ..followRedirects = false
      ..headers['Accept'] = 'application/json';
    if (etag != null) request.headers['If-None-Match'] = etag;
    final response = await _client.send(request);
    if (response.statusCode == 304) {
      await response.stream.listen(null).cancel();
      return null;
    }
    final type = response.headers['content-type']?.split(';').first.trim();
    if (response.statusCode != 200 ||
        type != 'application/json' ||
        (response.contentLength ?? 0) > _maxBytes) {
      await response.stream.listen(null).cancel();
      throw const FormatException('Invalid catalog response');
    }
    final bytes = <int>[];
    await for (final chunk in response.stream.timeout(_timeout)) {
      if (bytes.length + chunk.length > _maxBytes) {
        throw const FormatException('Catalog response is too large');
      }
      bytes.addAll(chunk);
    }
    return (body: utf8.decode(bytes), etag: response.headers['etag']);
  }

  Future<void> _save(File file, Uri url, String body, String? etag) async {
    Directory? staging;
    try {
      staging = await file.parent.createTemp('catalog-');
      final pending = File('${staging.path}/content.json');
      await pending.writeAsString(
        jsonEncode({'url': url.toString(), 'etag': etag, 'body': body}),
        flush: true,
      );
      await pending.rename(file.path);
    } on FileSystemException {
      // A validated response still works in memory when storage is full.
    } finally {
      try {
        await staging?.delete(recursive: true);
      } on FileSystemException {
        // Temporary files are ignored on subsequent loads.
      }
    }
  }
}
