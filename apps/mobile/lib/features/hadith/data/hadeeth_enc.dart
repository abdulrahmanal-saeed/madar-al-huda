import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

typedef HadithItem = ({String id, String title});
typedef HadithPage = ({List<HadithItem> items, int lastPage});
typedef HadithDetail = ({
  String title,
  String text,
  String explanation,
  String grade,
  String attribution,
  String? reference,
});

final hadithCategoriesProvider = FutureProvider.autoDispose
    .family<List<HadithItem>, String>((ref, language) async {
      final rows = (await _get('categories/list', {
        'language': language,
      }) as List).cast<Map<String, dynamic>>();
      return rows.map(_item).toList(growable: false);
    });

final hadithPageProvider = FutureProvider.autoDispose
    .family<HadithPage, ({String language, String category, int page})>((
      ref,
      query,
    ) async {
      final result = await _get('hadeeths/list', {
        'language': query.language,
        'category_id': query.category,
        'page': '${query.page}',
        'per_page': '20',
      }) as Map<String, dynamic>;
      final rows = (result['data'] as List).cast<Map<String, dynamic>>();
      final meta = result['meta'] as Map<String, dynamic>;
      if (int.parse(meta['current_page'].toString()) != query.page) {
        throw const FormatException('Unexpected HadeethEnc page');
      }
      return (
        items: rows.map(_item).toList(growable: false),
        lastPage: int.parse(meta['last_page'].toString()),
      );
    });

final hadithDetailProvider = FutureProvider.autoDispose
    .family<HadithDetail, ({String language, String id})>((ref, query) async {
      final row = await _get('hadeeths/one', {
        'language': query.language,
        'id': query.id,
      }) as Map<String, dynamic>;
      if (row['id'].toString() != query.id) {
        throw const FormatException('Unexpected HadeethEnc hadith');
      }
      return (
        title: row['title'] as String,
        text: row['hadeeth'] as String,
        explanation: row['explanation'] as String? ?? '',
        grade: row['grade'] as String? ?? '',
        attribution: row['attribution'] as String? ?? '',
        reference: row['reference'] as String?,
      );
    });

HadithItem _item(Map<String, dynamic> row) =>
    (id: row['id'].toString(), title: row['title'] as String);

Future<Object?> _get(String path, Map<String, String> fields) async {
  final response = await http
      .get(Uri.https('hadeethenc.com', '/api/v1/$path/', fields))
      .timeout(const Duration(seconds: 10));
  if (response.statusCode != 200) throw StateError('HadeethEnc unavailable');
  return jsonDecode(utf8.decode(response.bodyBytes));
}
