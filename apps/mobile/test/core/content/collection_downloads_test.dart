import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/content/collection_downloads.dart';
import 'package:madar_al_huda/features/adhkar/data/quran_dua_index.dart';
import 'package:madar_al_huda/features/home/presentation/home_screen.dart';

void main() {
  test('the next calendar day advances the dua and skips duplicate ranges', () {
    const first = (surah: 2, first: 200, last: 201);
    const second = (surah: 7, first: 23, last: 23);
    const List<List<DuaRange>> groups = [
      [first],
      [first, second],
    ];
    expect(duaForCivilDay(DateTime(2026, 1, 1, 23, 59), groups), first);
    expect(duaForCivilDay(DateTime(2026, 1, 2), groups), second);
    expect(duaForCivilDay(DateTime(2026, 1, 3), groups), first);
  });

  test(
    'batch stops at a failed download and can restart after recovery',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final downloads = container.read(collectionDownloadsProvider.notifier);
      final saved = <int>{};
      var reachable = false;
      Future<void> save(int id) async {
        if (id == 2 && !reachable) throw StateError('connection lost');
        saved.add(id);
      }

      final tasks = <Future<void> Function()>[
        for (var i = 1; i <= 3; i++) () => save(i),
      ];
      await downloads.start('Stories', tasks);
      expect(saved, {1});
      expect(container.read(collectionDownloadsProvider)?.completed, 1);
      expect(container.read(collectionDownloadsProvider)?.interrupted, isTrue);

      reachable = true;
      await downloads.start('Stories', tasks);
      expect(saved, {1, 2, 3});
      expect(container.read(collectionDownloadsProvider)?.interrupted, isFalse);
    },
  );
}
