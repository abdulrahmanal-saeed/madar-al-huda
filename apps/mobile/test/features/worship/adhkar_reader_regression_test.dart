import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/storage/key_value_store.dart';
import 'package:madar_al_huda/core/storage/storage_providers.dart';
import 'package:madar_al_huda/features/adhkar/data/adhkar_catalog.dart';
import 'package:madar_al_huda/features/adhkar/data/adhkar_progress.dart';
import 'package:madar_al_huda/features/adhkar/presentation/dhikr_content.dart';

void main() {
  final entry = DhikrEntry.fromJson({
    'id': 'tasbih',
    'title': {'ar': 'التسبيح', 'en': 'Remembrance'},
    'repeat': [
      {'unit': 'tasbih', 'count': 33},
      {'unit': 'tahmid', 'count': 33},
      {'unit': 'takbir', 'count': 34},
    ],
  });
  final group = DhikrGroup('bedtime', entry.title, [entry]);

  test('legacy cumulative progress maps to individual steps', () {
    const day = '2026-11-25';
    const progress = AdhkarProgress(
      counts: {'2026-11-25/bedtime/tasbih/own': 83},
    );
    expect(progress.stepCount(day, group, entry, 0), 33);
    expect(progress.stepCount(day, group, entry, 1), 33);
    expect(progress.stepCount(day, group, entry, 2), 17);
  });

  test('individual counters persist independently and reset together', () async {
    final day = adhkarDayKey(DateTime.now());
    final store = InMemoryKeyValueStore();
    ProviderContainer create() => ProviderContainer(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    final first = create();
    final controller = first.read(adhkarProgressProvider.notifier);
    await controller.advanceStep(day, group, entry, 2);
    await controller.advanceStep(day, group, entry, 0);
    await controller.advanceStep(day, group, entry, 2);
    first.dispose();

    final second = create();
    addTearDown(second.dispose);
    final progress = second.read(adhkarProgressProvider);
    expect(progress.stepCount(day, group, entry, 0), 1);
    expect(progress.stepCount(day, group, entry, 1), 0);
    expect(progress.stepCount(day, group, entry, 2), 2);
    expect(progress.count(day, group, entry), 3);
    await second.read(adhkarProgressProvider.notifier).reset(day, group, entry);
    final reset = second.read(adhkarProgressProvider);
    expect(reset.count(day, group, entry), 0);
    expect(reset.stepCount(day, group, entry, 2), 0);
  });

  test('Quran ranges keep their real ayah numbers including the last', () {
    expect(
      numberedQuranRange(['first', 'second', 'third'], first: 2, last: 3),
      'second ۝٢ third ۝٣',
    );
    final verses = List.generate(200, (index) => 'v${index + 1}');
    final result = numberedQuranRange(verses, first: 190, last: 200);
    expect(result, startsWith('v190 ۝١٩٠'));
    expect(result, endsWith('v200 ۝٢٠٠'));
    expect('۝'.allMatches(result).length, 11);
  });
}
