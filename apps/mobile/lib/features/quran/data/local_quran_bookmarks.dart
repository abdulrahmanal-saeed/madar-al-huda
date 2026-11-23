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

  /// Copy of stored bookmarks that could not be fully read.
  static const backupKey = 'quran.bookmarks.v1.unreadable';
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

  /// Holds the original stored text when part of it could not be read, so
  /// the next write keeps a copy instead of silently replacing it.
  String? _unreadable;

  List<QuranBookmark> _read() {
    final raw = _store.getString(key);
    if (raw == null) return const [];
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      _unreadable = raw;
      return const [];
    }
    if (decoded is! List) {
      _unreadable = raw;
      return const [];
    }
    final bookmarks = <QuranBookmark>[];
    for (final item in decoded) {
      try {
        final data = item as Map<String, dynamic>;
        bookmarks.add(
          QuranBookmark(
            id: data['id'] as String,
            ref: AyahRef(
              editionId: data['edition'] as String,
              surah: data['surah'] as int,
              ayah: data['ayah'] as int,
            ),
            createdAt: DateTime.parse(data['created'] as String),
            note: data['note'] as String?,
          ),
        );
      } on Object {
        // Keep every readable bookmark; the full original text is backed up
        // before the next write.
        _unreadable = raw;
      }
    }
    return bookmarks;
  }

  Future<void> _write(List<QuranBookmark> bookmarks) async {
    final unreadable = _unreadable;
    if (unreadable != null && _store.getString(backupKey) == null) {
      await _store.setString(backupKey, unreadable);
    }
    _unreadable = null;
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
