import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';

/// Verses marked as memorized, by surah, kept on the device.
final memorizedProvider = NotifierProvider<Memorized, Map<int, Set<int>>>(
  Memorized.new,
);

class Memorized extends Notifier<Map<int, Set<int>>> {
  static const key = 'quran.memorized.v1';
  Future<void> _writes = Future.value();

  @override
  Map<int, Set<int>> build() {
    final raw = ref.watch(keyValueStoreProvider).getString(key);
    if (raw == null) return const {};
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final MapEntry(:key, :value) in data.entries)
          if (int.tryParse(key) case final surah?
              when surah >= 1 && surah <= 114 && value is List)
            surah: {
              for (final ayah in value)
                if (ayah is int && ayah >= 1 && ayah <= 286) ayah,
            },
      };
    } on Object {
      return const {};
    }
  }

  bool contains(int surah, int ayah) => state[surah]?.contains(ayah) ?? false;

  Future<void> toggle(int surah, int ayah) => _update((map) {
    final verses = {...?map[surah]};
    if (!verses.remove(ayah)) verses.add(ayah);
    return {...map, surah: verses};
  });

  Future<void> setRange(int surah, int first, int last, {required bool on}) =>
      _update((map) {
        final verses = {...?map[surah]};
        for (var ayah = first; ayah <= last; ayah++) {
          on ? verses.add(ayah) : verses.remove(ayah);
        }
        return {...map, surah: verses};
      });

  Future<void> _update(Map<int, Set<int>> Function(Map<int, Set<int>>) change) {
    final operation = _writes.then((_) async {
      final next = {
        for (final MapEntry(:key, :value) in change(state).entries)
          if (value.isNotEmpty) key: value,
      };
      await ref
          .read(keyValueStoreProvider)
          .setString(
            key,
            jsonEncode({
              for (final MapEntry(:key, :value) in next.entries)
                '$key': (value.toList()..sort()),
            }),
          );
      state = next;
    });
    _writes = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }
}

/// How much of a verse is shown while memorizing.
enum MemorizeView { full, firstWord, hidden }

/// The opening word of a verse, as a prompt.
String firstWordOf(String verse) {
  final words = verse.trim().split(RegExp(r'\s+'));
  return words.isEmpty ? '' : words.first;
}
