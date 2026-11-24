import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

typedef HadithItem = ({String id, String title});
typedef HadithPage = ({List<HadithItem> items, int lastPage, int total});

/// A HadeethEnc topic. Topics nest up to five levels deep.
class HadithCategory {
  const HadithCategory({
    required this.id,
    required this.title,
    this.count = 0,
    this.parentId,
  });

  final String id;
  final String title;

  /// Hadiths in this topic and every topic below it.
  final int count;
  final String? parentId;

  bool get isRoot => parentId == null;
}

class HadithCatalog {
  HadithCatalog(this.categories) {
    for (final category in categories) {
      if (category.parentId case final parent?) {
        (_children[parent] ??= []).add(category);
      }
    }
  }

  final List<HadithCategory> categories;
  final Map<String, List<HadithCategory>> _children = {};

  List<HadithCategory> get roots =>
      categories.where((category) => category.isRoot).toList();

  List<HadithCategory> childrenOf(String id) => _children[id] ?? const [];

  HadithCategory? byId(String? id) =>
      categories.where((category) => category.id == id).firstOrNull;
}

typedef HadithWord = ({String word, String meaning});

class HadithDetail {
  const HadithDetail({
    required this.id,
    required this.title,
    required this.text,
    this.intro = '',
    this.arabicText,
    this.explanation = '',
    this.hints = const [],
    this.words = const [],
    this.grade = '',
    this.attribution = '',
    this.reference,
  });

  final String id;
  final String title;

  /// The full report, narrator chain included.
  final String text;

  /// The opening that names the narrator, when the publisher marks it.
  final String intro;

  /// The Arabic original, given with every translation.
  final String? arabicText;
  final String explanation;

  /// The publisher's "benefits of the hadith".
  final List<String> hints;
  final List<HadithWord> words;
  final String grade;
  final String attribution;
  final String? reference;

  /// The Prophet's words without the narrator's introduction.
  String get body {
    final trimmed = intro.trim();
    if (trimmed.isEmpty || !text.startsWith(trimmed)) return text;
    final rest = text.substring(trimmed.length).trim();
    return rest.isEmpty ? text : rest;
  }

  static HadithDetail parse(Map<String, dynamic> row) {
    List<String> lines(Object? value) => [
      for (final line in (value as List<dynamic>?) ?? const [])
        if ('$line'.trim() case final text when text.isNotEmpty) text,
    ];
    return HadithDetail(
      id: row['id'].toString(),
      title: row['title'] as String,
      text: (row['hadeeth'] as String).trim(),
      intro: row['hadeeth_intro'] as String? ?? '',
      arabicText: (row['hadeeth_ar'] as String?)?.trim(),
      explanation: (row['explanation'] as String? ?? '').trim(),
      hints: lines(row['hints']),
      words: [
        for (final item
            in (row['words_meanings'] as List<dynamic>?) ?? const [])
          if (item is Map<String, dynamic>)
            (
              word: '${item['word'] ?? ''}'.trim(),
              meaning: '${item['meaning'] ?? ''}'.trim(),
            ),
      ].where((item) => item.word.isNotEmpty).toList(),
      grade: (row['grade'] as String? ?? '').trim(),
      attribution: (row['attribution'] as String? ?? '').trim(),
      reference: (row['reference'] as String?)?.trim(),
    );
  }
}

/// HadeethEnc's public API with a copy on the device, so topics already
/// browsed and hadiths already read open without a connection.
class HadeethEnc {
  HadeethEnc(this._client, this._directory);

  final http.Client _client;
  final Future<Directory> Function() _directory;

  Future<Object?> get(
    String path,
    Map<String, String> fields, {
    Duration fresh = Duration.zero,
  }) async {
    final cache = await _cacheFile(path, fields);
    if (cache != null && await cache.exists()) {
      final age = DateTime.now().difference(await cache.lastModified());
      if (age < fresh) {
        final saved = await _read(cache);
        if (saved != null) return saved;
      }
    }
    try {
      final response = await _client
          .get(Uri.https('hadeethenc.com', '/api/v1/$path/', fields))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw StateError('HadeethEnc unavailable');
      }
      final body = utf8.decode(response.bodyBytes);
      final data = jsonDecode(body);
      if (cache != null) {
        try {
          await cache.parent.create(recursive: true);
          await cache.writeAsString(body);
        } on Object {
          // A full disk only costs the offline copy.
        }
      }
      return data;
    } on Object {
      if (cache != null) {
        final saved = await _read(cache);
        if (saved != null) return saved;
      }
      rethrow;
    }
  }

  Future<File?> _cacheFile(String path, Map<String, String> fields) async {
    try {
      final name = [
        path.replaceAll('/', '-'),
        for (final key in fields.keys.toList()..sort()) '$key=${fields[key]}',
      ].join('_').replaceAll(RegExp('[^A-Za-z0-9_=.-]'), '');
      return File('${(await _directory()).path}/hadeethenc/$name.json');
    } on Object {
      return null;
    }
  }

  static Future<Object?> _read(File file) async {
    try {
      return jsonDecode(await file.readAsString());
    } on Object {
      return null;
    }
  }
}

final hadeethEncProvider = Provider<HadeethEnc>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return HadeethEnc(client, getApplicationSupportDirectory);
});

final hadithCatalogProvider = FutureProvider.family<HadithCatalog, String>((
  ref,
  language,
) async {
  final rows = (await ref.read(hadeethEncProvider).get('categories/list', {
    'language': language,
  }, fresh: const Duration(days: 7)) as List).cast<Map<String, dynamic>>();
  return HadithCatalog([
    for (final row in rows)
      HadithCategory(
        id: row['id'].toString(),
        title: (row['title'] as String).trim(),
        count: int.tryParse('${row['hadeeths_count']}') ?? 0,
        parentId: row['parent_id']?.toString(),
      ),
  ]);
});

const hadithPageSize = 20;

final hadithPageProvider = FutureProvider.autoDispose
    .family<HadithPage, ({String language, String category, int page})>((
      ref,
      query,
    ) async {
      final result = await ref.read(hadeethEncProvider).get('hadeeths/list', {
        'language': query.language,
        'category_id': query.category,
        'page': '${query.page}',
        'per_page': '$hadithPageSize',
      }, fresh: const Duration(days: 1)) as Map<String, dynamic>;
      final rows = (result['data'] as List).cast<Map<String, dynamic>>();
      final meta = result['meta'] as Map<String, dynamic>;
      if (int.parse(meta['current_page'].toString()) != query.page) {
        throw const FormatException('Unexpected HadeethEnc page');
      }
      return (
        items: [
          for (final row in rows)
            (id: row['id'].toString(), title: (row['title'] as String).trim()),
        ],
        lastPage: int.parse(meta['last_page'].toString()),
        total: int.tryParse('${meta['total_items']}') ?? 0,
      );
    });

final hadithDetailProvider = FutureProvider.autoDispose
    .family<HadithDetail, ({String language, String id})>((ref, query) async {
      final row = await ref.read(hadeethEncProvider).get('hadeeths/one', {
        'language': query.language,
        'id': query.id,
        // A hadith's text does not change once published.
      }, fresh: const Duration(days: 365)) as Map<String, dynamic>;
      if (row['id'].toString() != query.id) {
        throw const FormatException('Unexpected HadeethEnc hadith');
      }
      return HadithDetail.parse(row);
    });
