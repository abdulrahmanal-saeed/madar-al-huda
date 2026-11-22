import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

typedef VerseMeaning = ({String text, String footnotes});
typedef ChapterMeaning = ({String version, Map<int, VerseMeaning> verses});

const _translationKey = 'english_rwwad';

final _quranEncVersion = FutureProvider.autoDispose<String>((ref) async {
  final json = await _get('/api/v1/translations/list/en/');
  final rows = (json['translations'] as List).cast<Map<String, dynamic>>();
  final entry = rows.firstWhere((row) => row['key'] == _translationKey);
  final version = entry['version'] as String;
  if (version.isEmpty) throw const FormatException('QuranEnc version missing');
  return version;
});

final quranEnglishMeaningProvider = FutureProvider.autoDispose
    .family<ChapterMeaning, int>((ref, surah) async {
      final version = await ref.watch(_quranEncVersion.future);
      final json = await _get(
        '/api/v1/translation/sura/$_translationKey/$surah',
      );
      final rows = (json['result'] as List).cast<Map<String, dynamic>>();
      final verses = <int, VerseMeaning>{};
      for (final row in rows) {
        final ayah = int.parse(row['aya'].toString());
        final text = row['translation'] as String;
        if (int.parse(row['sura'].toString()) != surah ||
            ayah != verses.length + 1 ||
            text.isEmpty) {
          throw const FormatException('Unexpected QuranEnc verse');
        }
        verses[ayah] = (
          text: text,
          footnotes: (row['footnotes'] as String?) ?? '',
        );
      }
      if (verses.isEmpty) throw const FormatException('Empty QuranEnc chapter');
      return (
        version: version,
        verses: Map<int, VerseMeaning>.unmodifiable(verses),
      );
    });

Future<Map<String, dynamic>> _get(String path) async {
  final response = await http
      .get(Uri.https('quranenc.com', path))
      .timeout(const Duration(seconds: 10));
  if (response.statusCode != 200) throw StateError('QuranEnc unavailable');
  return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
}
