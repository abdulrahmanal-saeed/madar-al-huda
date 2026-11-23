import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';

final hadithFavoritesProvider = NotifierProvider<HadithFavorites, Set<String>>(
  HadithFavorites.new,
);

class HadithFavorites extends Notifier<Set<String>> {
  static const key = 'hadith.favorites.v1';
  static final _id = RegExp(r'^[0-9]+$');
  Future<void> _writes = Future.value();

  @override
  Set<String> build() => (ref.watch(keyValueStoreProvider).getString(key) ?? '')
      .split(',')
      .where(_id.hasMatch)
      .toSet();

  Future<void> toggle(String id) {
    if (!_id.hasMatch(id)) throw ArgumentError.value(id, 'id');
    final write = _writes.then((_) async {
      final favorites = {...state};
      if (!favorites.remove(id)) favorites.add(id);
      await ref.read(keyValueStoreProvider).setString(key, favorites.join(','));
      state = favorites;
    });
    _writes = write.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return write;
  }
}
