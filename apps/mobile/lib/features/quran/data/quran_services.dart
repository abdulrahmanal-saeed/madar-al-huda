import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/storage/key_value_store.dart';
import '../../../core/storage/storage_providers.dart';
import '../domain/quran_storage_contracts.dart';

final quranApiProvider = Provider<QuranApi>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return QuranApi(
    client,
    const String.fromEnvironment('MADAR_QURAN_API_URL'),
    const String.fromEnvironment('MADAR_SUPABASE_ANON_KEY'),
  );
});

final quranCatalogProvider = FutureProvider.autoDispose
    .family<QuranCatalog, String>(
      (ref, language) => ref.watch(quranApiProvider).catalog(language),
    );

final quranPositionProvider = Provider<ReadingPositionRepository>(
  (ref) => LocalReadingPosition(ref.watch(keyValueStoreProvider)),
);

final lastReadingPositionProvider = FutureProvider<ReadingPosition?>(
  (ref) => ref.watch(quranPositionProvider).lastRead(),
);

class QuranResource {
  const QuranResource(this.id, this.name, {this.language});
  final int id;
  final String name;
  final String? language;

  factory QuranResource.fromJson(Map<String, dynamic> json) => QuranResource(
    json['id'] as int,
    json['name'] as String,
    language: json['language'] as String?,
  );
}

class QuranCatalog {
  const QuranCatalog(
    this.ayatBySurah,
    this.tafsirs,
    this.reciters, {
    this.isPreview = false,
  });
  final Map<int, int> ayatBySurah;
  final List<QuranResource> tafsirs;
  final List<QuranResource> reciters;
  final bool isPreview;
}

class VerseTimingUnavailable implements Exception {
  const VerseTimingUnavailable();
}

class QuranApi {
  const QuranApi(this._client, this._base, this._key);
  final http.Client _client;
  final String _base;
  final String _key;

  Future<QuranCatalog> catalog(String language) async {
    final json = await _get('catalog', {'lang': language});
    final chapters = (json['chapters'] as List).cast<Map<String, dynamic>>();
    List<QuranResource> resources(String key) => (json[key] as List)
        .cast<Map<String, dynamic>>()
        .map(QuranResource.fromJson)
        .toList(growable: false);
    return QuranCatalog(
      {
        for (final chapter in chapters)
          chapter['id'] as int: chapter['verses'] as int,
      },
      resources('tafsirs'),
      resources('reciters'),
      isPreview:
          (json['availability'] as Map<String, dynamic>?)?['environment'] ==
          'prelive',
    );
  }

  Future<String> tafsir(AyahRef ref, int resource) async {
    final json = await _get('tafsir', {
      'surah': '${ref.surah}',
      'ayah': '${ref.ayah}',
      'resource': '$resource',
    });
    if (json['verse'] != '${ref.surah}:${ref.ayah}' ||
        json['resource'] != resource) {
      throw const FormatException('Tafsir identity mismatch');
    }
    return json['text'] as String;
  }

  Future<Uri> audio(int surah, int resource) async {
    final json = await _recitation(surah, resource);
    return _audioUri(json, surah, resource);
  }

  Future<({Uri url, Duration start})> audioAtVerse(
    AyahRef verse,
    int resource,
  ) async {
    final json = await _recitation(verse.surah, resource, ayah: verse.ayah);
    final url = _audioUri(json, verse.surah, resource);
    final start = json['start_ms'];
    if (json['verse'] != '${verse.surah}:${verse.ayah}' ||
        start is! int ||
        start < 0) {
      throw const VerseTimingUnavailable();
    }
    return (url: url, start: Duration(milliseconds: start));
  }

  Future<({Uri url, Map<int, int> starts})> chapterTimings(
    int surah,
    int resource,
    int count,
  ) async {
    final json = await _get('recitation', {
      'surah': '$surah',
      'resource': '$resource',
      'timings': '1',
    });
    final url = _audioUri(json, surah, resource);
    final data = json['starts'] as List;
    final starts = <int, int>{};
    var previous = -1;
    for (var i = 0; i < data.length; i++) {
      final row = data[i] as List;
      final start = row[1];
      if (row[0] != '$surah:${i + 1}' || start is! int || start <= previous) {
        throw const VerseTimingUnavailable();
      }
      starts[i + 1] = start;
      previous = start;
    }
    if (starts.length != count) throw const VerseTimingUnavailable();
    return (url: url, starts: starts);
  }

  Future<Map<String, dynamic>> mushafPage(int edition, int page) =>
      _get('mushaf', {'edition': '$edition', 'page': '$page'});

  Future<Map<String, dynamic>> _recitation(
    int surah,
    int resource, {
    int? ayah,
  }) => _get('recitation', {
    'surah': '$surah',
    'resource': '$resource',
    if (ayah != null) 'ayah': '$ayah',
  });

  Uri _audioUri(Map<String, dynamic> json, int surah, int resource) {
    final uri = Uri.parse(json['url'] as String);
    if (json['surah'] != surah ||
        json['resource'] != resource ||
        uri.scheme != 'https' ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty) {
      throw const FormatException('Unrecognized audio source');
    }
    return uri;
  }

  Future<Map<String, dynamic>> _get(
    String route,
    Map<String, String> parameters,
  ) async {
    final base = Uri.tryParse(_base);
    if (base == null ||
        base.scheme != 'https' ||
        base.host.isEmpty ||
        _key.isEmpty) {
      throw StateError('Quran service is not configured');
    }
    final uri = base.replace(
      pathSegments: [
        ...base.pathSegments.where((s) => s.isNotEmpty),
        'v1',
        route,
      ],
      queryParameters: parameters,
    );
    final response = await _client
        .get(uri, headers: {'Authorization': 'Bearer $_key', 'apikey': _key})
        .timeout(const Duration(seconds: 12));
    if (response.statusCode == 404 &&
        route == 'recitation' &&
        parameters.containsKey('ayah')) {
      throw const VerseTimingUnavailable();
    }
    if (response.statusCode != 200) {
      throw StateError('Quran service unavailable');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }
}

class LocalReadingPosition implements ReadingPositionRepository {
  LocalReadingPosition(this._store);
  static const key = 'quran.lastRead.v1';
  final KeyValueStore _store;
  Future<void> _pending = Future.value();

  @override
  Future<ReadingPosition?> lastRead() async {
    final stored = _store.getString(key);
    if (stored == null) return null;
    try {
      final data = jsonDecode(stored) as List<dynamic>;
      return ReadingPosition(
        ref: AyahRef(
          editionId: data[0] as String,
          surah: data[1] as int,
          ayah: data[2] as int,
        ),
        updatedAt: DateTime.parse(data[3] as String),
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<void> saveLastRead(AyahRef ref) {
    final value = jsonEncode([
      ref.editionId,
      ref.surah,
      ref.ayah,
      DateTime.now().toUtc().toIso8601String(),
    ]);
    final result = _pending.then((_) => _store.setString(key, value));
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}
