import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/storage/key_value_store.dart';
import 'package:madar_al_huda/features/quran/data/local_quran_bookmarks.dart';
import 'package:madar_al_huda/features/quran/domain/quran_storage_contracts.dart';

void main() {
  final ref = AyahRef(editionId: 'tanzil-uthmani', surah: 2, ayah: 255);

  Map<String, Object?> stored(int ayah) => {
    'id': 'tanzil-uthmani:1:$ayah',
    'edition': 'tanzil-uthmani',
    'surah': 1,
    'ayah': ayah,
    'created': '2026-11-20T10:00:00.000Z',
    'note': null,
  };

  test('keeps readable bookmarks when one entry is damaged', () async {
    final raw = jsonEncode([
      stored(1),
      {'id': 'broken'},
      stored(2),
    ]);
    final store = InMemoryKeyValueStore({LocalQuranBookmarks.key: raw});
    final bookmarks = LocalQuranBookmarks(store);

    final first = await bookmarks.watchAll().first;
    expect(first.map((b) => b.ref.ayah), [1, 2]);

    await bookmarks.add(ref);
    final saved = jsonDecode(store.getString(LocalQuranBookmarks.key)!) as List;
    expect(saved, hasLength(3));
    expect(store.getString(LocalQuranBookmarks.backupKey), raw);
    bookmarks.dispose();
  });

  test('backs up unreadable text before replacing it', () async {
    const raw = '{not json';
    final store = InMemoryKeyValueStore({LocalQuranBookmarks.key: raw});
    final bookmarks = LocalQuranBookmarks(store);

    expect(await bookmarks.watchAll().first, isEmpty);
    await bookmarks.add(ref);

    expect(store.getString(LocalQuranBookmarks.backupKey), raw);
    final saved = jsonDecode(store.getString(LocalQuranBookmarks.key)!) as List;
    expect(saved, hasLength(1));
    bookmarks.dispose();
  });

  test('writes no backup for healthy data', () async {
    final store = InMemoryKeyValueStore({
      LocalQuranBookmarks.key: jsonEncode([stored(1)]),
    });
    final bookmarks = LocalQuranBookmarks(store);

    await bookmarks.add(ref);

    expect(store.getString(LocalQuranBookmarks.backupKey), isNull);
    bookmarks.dispose();
  });
}
