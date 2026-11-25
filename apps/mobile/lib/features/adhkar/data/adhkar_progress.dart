import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/storage_providers.dart';
import 'adhkar_catalog.dart';

final adhkarProgressProvider =
    NotifierProvider<AdhkarProgressController, AdhkarProgress>(
      AdhkarProgressController.new,
    );

String adhkarDayKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

class AdhkarProgress {
  const AdhkarProgress({
    this.groups = const {},
    this.merits = const {},
    this.saved = const {},
    this.counts = const {},
    this.variants = const {},
    this.lastGroup,
  });

  final Set<String> groups;
  final Set<String> merits;
  final Set<String> saved;
  final Map<String, int> counts;
  final Map<String, int> variants;
  final String? lastGroup;

  String entryKey(String day, DhikrGroup group, DhikrEntry entry) =>
      '$day/${group.id}/${entry.id}';

  int variantIndex(String day, DhikrGroup group, DhikrEntry entry) =>
      (variants[entryKey(day, group, entry)] ?? 0).clamp(
        0,
        entry.variants.length - 1,
      );

  int count(String day, DhikrGroup group, DhikrEntry entry) {
    final variant = entry.variants[variantIndex(day, group, entry)];
    return (counts['${entryKey(day, group, entry)}/${variant.key}'] ?? 0).clamp(
      0,
      variant.goal,
    );
  }

  bool complete(String day, DhikrGroup group, DhikrEntry entry) =>
      count(day, group, entry) ==
      entry.variants[variantIndex(day, group, entry)].goal;

  int completedEntries(String day, DhikrGroup group) =>
      group.entries.where((entry) => complete(day, group, entry)).length;

  int completedInGroup(String day, DhikrGroup group) => group.isAfterPrayer
      ? DhikrGroup.prayers
            .where(
              (prayer) =>
                  completedEntries(day, group.prayerSession(prayer)) ==
                  group.entries.length,
            )
            .length
      : completedEntries(day, group);

  int groupGoal(DhikrGroup group) =>
      group.isAfterPrayer ? DhikrGroup.prayers.length : group.entries.length;
}

class AdhkarProgressController extends Notifier<AdhkarProgress> {
  static const key = 'worship.adhkarProgress.v1';
  Future<void> _pending = Future.value();

  @override
  AdhkarProgress build() {
    final stored = ref.watch(keyValueStoreProvider).getString(key);
    try {
      if (stored == null) return const AdhkarProgress();
      final data = jsonDecode(stored) as Map<String, Object?>;
      Map<String, int> counters(String field) => {
        for (final entry
            in (data[field] as Map<String, Object?>? ?? {}).entries)
          if (entry.value case final int value when value >= 0)
            entry.key: value,
      };
      return AdhkarProgress(
        groups: (data['groups'] as List<Object?>? ?? [])
            .whereType<String>()
            .toSet(),
        merits: (data['merits'] as List<Object?>? ?? [])
            .whereType<String>()
            .toSet(),
        saved: (data['saved'] as List<Object?>? ?? [])
            .whereType<String>()
            .toSet(),
        counts: counters('counts'),
        variants: counters('variants'),
        lastGroup: data['lastGroup'] as String?,
      );
    } on Object {
      return const AdhkarProgress();
    }
  }

  Future<void> setGroup(String id, {required bool selected}) => _save(
    (current) => _copy(current, groups: _set(current.groups, id, selected)),
  );

  Future<void> setMerit(String id, {required bool selected}) => _save(
    (current) => _copy(current, merits: _set(current.merits, id, selected)),
  );

  Future<void> setSaved(String id, {required bool selected}) => _save(
    (current) => _copy(current, saved: _set(current.saved, id, selected)),
  );

  Future<void> chooseVariant(
    String day,
    DhikrGroup group,
    DhikrEntry entry,
    int option,
  ) => _save(
    (current) => _copy(
      current,
      variants: {
        ...current.variants,
        current.entryKey(day, group, entry): option,
      },
      lastGroup: group.id,
    ),
  );

  Future<void> advance(String day, DhikrGroup group, DhikrEntry entry) =>
      _save((current) {
        final variant = entry.variants[current.variantIndex(day, group, entry)];
        final path = '${current.entryKey(day, group, entry)}/${variant.key}';
        final count = (current.count(day, group, entry) + 1).clamp(
          0,
          variant.goal,
        );
        return _copy(
          current,
          counts: {...current.counts, path: count},
          lastGroup: group.id,
        );
      });

  Future<void> reset(String day, DhikrGroup group, DhikrEntry entry) =>
      _save((current) {
        final variant = entry.variants[current.variantIndex(day, group, entry)];
        final path = '${current.entryKey(day, group, entry)}/${variant.key}';
        return _copy(
          current,
          counts: {...current.counts, path: 0},
          lastGroup: group.id,
        );
      });

  static Set<String> _set(Set<String> items, String id, bool selected) =>
      selected ? {...items, id} : (items.toSet()..remove(id));

  static AdhkarProgress _copy(
    AdhkarProgress current, {
    Set<String>? groups,
    Set<String>? merits,
    Set<String>? saved,
    Map<String, int>? counts,
    Map<String, int>? variants,
    String? lastGroup,
  }) => AdhkarProgress(
    groups: groups ?? current.groups,
    merits: merits ?? current.merits,
    saved: saved ?? current.saved,
    counts: counts ?? current.counts,
    variants: variants ?? current.variants,
    lastGroup: lastGroup ?? current.lastGroup,
  );

  Future<void> _save(AdhkarProgress Function(AdhkarProgress) change) {
    final operation = _pending.then((_) async {
      final value = change(state);
      final cutoff = adhkarDayKey(
        DateTime.now().subtract(const Duration(days: 14)),
      );
      bool recent(String path) => path.split('/').first.compareTo(cutoff) >= 0;
      final next = AdhkarProgress(
        groups: value.groups,
        merits: value.merits,
        saved: value.saved,
        counts: Map.of(value.counts)..removeWhere((key, _) => !recent(key)),
        variants: Map.of(value.variants)..removeWhere((key, _) => !recent(key)),
        lastGroup: value.lastGroup,
      );
      await ref
          .read(keyValueStoreProvider)
          .setString(
            key,
            jsonEncode({
              'groups': next.groups.toList(),
              'merits': next.merits.toList(),
              'saved': next.saved.toList(),
              'counts': next.counts,
              'variants': next.variants,
              'lastGroup': next.lastGroup,
            }),
          );
      state = next;
    });
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }
}
