import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/key_value_store.dart';
import '../../../core/storage/storage_providers.dart';
import '../domain/quran_storage_contracts.dart';

final quranBookmarksProvider = Provider<BookmarkRepository>((ref) {
  final repository = LocalQuranBookmarks(ref.watch(keyValueStoreProvider));
  ref.onDispose(repository.dispose);
  return repository;
});

final quranBookmarkListProvider = StreamProvider<List<QuranBookmark>>(
  (ref) => ref.watch(quranBookmarksProvider).watchAll(),
);

class LocalQuranBookmarks implements BookmarkRepository {
  LocalQuranBookmarks(this._store);

  static const key = 'quran.bookmarks.v1';
  final KeyValueStore _store;
  final _changes = StreamController<List<QuranBookmark>>.broadcast();
  Future<void> _pending = Future.value();

  @override
  Stream<List<QuranBookmark>> watchAll() => Stream.multi((listener) {
    listener.add(_read());
    final subscription = _changes.stream.listen(
      listener.add,
      onDone: listener.close,
    );
    listener.onCancel = subscription.cancel;
  });

  @override
  Future<QuranBookmark> add(AyahRef ref, {String? note}) => _enqueue(() async {
    final bookmarks = _read();
    for (final bookmark in bookmarks) {
      if (bookmark.ref == ref) return bookmark;
    }
    final bookmark = QuranBookmark(
      id: '${ref.editionId}:${ref.surah}:${ref.ayah}',
      ref: ref,
      createdAt: DateTime.now().toUtc(),
      note: note,
    );
    await _write([bookmark, ...bookmarks]);
    return bookmark;
  });

  @override
  Future<void> remove(String id) => _enqueue(() async {
    final bookmarks = _read();
    await _write(bookmarks.where((bookmark) => bookmark.id != id).toList());
  });

  Future<T> _enqueue<T>(Future<T> Function() work) {
    final update = _pending.then((_) => work());
    _pending = update.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return update;
  }

  List<QuranBookmark> _read() {
    final raw = _store.getString(key);
    if (raw == null) return const [];
    try {
      return [
        for (final item
            in (jsonDecode(raw) as List).cast<Map<String, dynamic>>())
          QuranBookmark(
            id: item['id'] as String,
            ref: AyahRef(
              editionId: item['edition'] as String,
              surah: item['surah'] as int,
              ayah: item['ayah'] as int,
            ),
            createdAt: DateTime.parse(item['created'] as String),
            note: item['note'] as String?,
          ),
      ];
    } on Object {
      return const [];
    }
  }

  Future<void> _write(List<QuranBookmark> bookmarks) async {
    await _store.setString(
      key,
      jsonEncode([
        for (final bookmark in bookmarks)
          {
            'id': bookmark.id,
            'edition': bookmark.ref.editionId,
            'surah': bookmark.ref.surah,
            'ayah': bookmark.ref.ayah,
            'created': bookmark.createdAt.toIso8601String(),
            'note': bookmark.note,
          },
      ]),
    );
    if (!_changes.isClosed) _changes.add(List.unmodifiable(bookmarks));
  }

  void dispose() => unawaited(_changes.close());
}
