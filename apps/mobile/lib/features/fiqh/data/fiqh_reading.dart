import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';

typedef FiqhReadingState = ({
  List<String> favorites,
  List<String> history,
  double fontScale,
});

final fiqhReadingProvider =
    NotifierProvider<FiqhReadingController, FiqhReadingState>(
      FiqhReadingController.new,
    );

class FiqhReadingController extends Notifier<FiqhReadingState> {
  static const key = 'fiqh.reading.v1';
  Future<void> _pending = Future.value();

  @override
  FiqhReadingState build() {
    final raw = ref.watch(keyValueStoreProvider).getString(key);
    try {
      final value = jsonDecode(raw ?? '{}') as Map<String, Object?>;
      final scale = value['fontScale'];
      return (
        favorites: _ids(value['favorites']),
        history: _ids(value['history']).take(100).toList(growable: false),
        fontScale: scale is num
            ? scale.toDouble().clamp(0.9, 1.5)
            : 1.0,
      );
    } on Object {
      return (favorites: const [], history: const [], fontScale: 1.0);
    }
  }

  List<String> _ids(Object? value) {
    if (value is! List) return const [];
    return List.unmodifiable(
      value.whereType<String>().where(_validId).toSet(),
    );
  }

  bool _validId(String id) =>
      RegExp(r'^[a-z0-9][a-z0-9_-]{0,95}$').hasMatch(id);

  Future<void> toggleFavorite(String id) {
    if (!_validId(id)) return Future.value();
    final favorites = state.favorites.contains(id)
        ? state.favorites.where((item) => item != id).toList()
        : [id, ...state.favorites];
    return _update((
      favorites: List.unmodifiable(favorites),
      history: state.history,
      fontScale: state.fontScale,
    ));
  }

  Future<void> recordReading(String id) {
    if (!_validId(id)) return Future.value();
    return _update((
      favorites: state.favorites,
      history: List.unmodifiable(
        [id, ...state.history.where((item) => item != id)].take(100),
      ),
      fontScale: state.fontScale,
    ));
  }

  Future<void> clearHistory() => _update((
    favorites: state.favorites,
    history: const [],
    fontScale: state.fontScale,
  ));

  Future<void> setFontScale(double value) => _update((
    favorites: state.favorites,
    history: state.history,
    fontScale: value.clamp(0.9, 1.5),
  ));

  Future<void> _update(FiqhReadingState next) {
    state = next;
    final store = ref.read(keyValueStoreProvider);
    final write = _pending.then(
      (_) => store.setString(
        key,
        jsonEncode({
          'favorites': next.favorites,
          'history': next.history,
          'fontScale': next.fontScale,
        }),
      ),
    );
    _pending = write.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return write;
  }
}
