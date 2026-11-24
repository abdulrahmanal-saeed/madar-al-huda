import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/storage/key_value_store.dart';
import 'package:madar_al_huda/core/storage/storage_providers.dart';
import 'package:madar_al_huda/features/worship/data/daily_reading_plan.dart';
import 'package:madar_al_huda/features/worship/data/khatma.dart';

void main() {
  final now = DateTime(2026, 11, 24, 21);

  test('the streak counts days in a row, allowing today to be pending', () {
    final log = {'2026-11-21': 4, '2026-11-22': 10, '2026-11-23': 2};
    expect(log.streak(now), 3);
    expect({...log, '2026-11-24': 1}.streak(now), 4);
    expect({'2026-11-20': 5}.streak(now), 0);
    expect(log.lastDays(now, 4), [4, 10, 2, 0]);
  });

  test("today's share spreads the remaining pages over the days left", () {
    final goal = KhatmaGoal(days: 30, start: DateTime(2026, 11, 24));
    expect(goal.end, DateTime(2026, 12, 23));
    // 604 pages over 30 days.
    expect(goal.todayTarget(pagesRead: 0, readToday: 0, now: now), 21);
    // Reading today does not move today's target.
    expect(goal.todayTarget(pagesRead: 15, readToday: 15, now: now), 21);
    // Ten days in with 100 pages read: 504 left over 20 days.
    expect(
      goal.todayTarget(
        pagesRead: 100,
        readToday: 0,
        now: DateTime(2026, 12, 4),
      ),
      26,
    );
    expect(goal.todayTarget(pagesRead: 604, readToday: 0, now: now), 0);
  });

  test('pages read are logged, and a goal sets the daily wird', () async {
    final store = InMemoryKeyValueStore();
    final container = ProviderContainer(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final plan = container.read(dailyReadingPlanProvider.notifier);
    await plan.completePage(1);
    await plan.completePage(2);
    await plan.completePage(5); // Not the next page: ignored.
    expect(container.read(readingLogProvider).pagesOn(DateTime.now()), 2);

    await container.read(khatmaGoalProvider.notifier).choose(10);
    expect(container.read(khatmaGoalProvider)?.days, 10);
    // 602 pages left over 10 days.
    expect(container.read(dailyReadingPlanProvider).pagesPerSession, 61);

    final restart = ProviderContainer(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    addTearDown(restart.dispose);
    expect(restart.read(khatmaGoalProvider)?.days, 10);
    expect(restart.read(readingLogProvider).pagesOn(DateTime.now()), 2);
    await restart.read(khatmaGoalProvider.notifier).clear();
    expect(restart.read(khatmaGoalProvider), isNull);
  });
}
