import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/core/storage/key_value_store.dart';
import 'package:madar_al_huda/features/adhkar/data/adhkar_progress.dart';
import 'package:madar_al_huda/features/quran/application/memorization.dart';
import 'package:madar_al_huda/features/stats/presentation/stats_screen.dart';
import 'package:madar_al_huda/features/worship/data/khatma.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  test('the best streak is the longest run of reading days', () {
    expect(bestStreak(const {}), 0);
    expect(
      bestStreak(const {
        '2026-11-01': 3,
        '2026-11-02': 1,
        '2026-11-03': 9,
        '2026-11-10': 2,
        '2026-11-11': 4,
      }),
      3,
    );
  });

  test('adhkar days count distinct recent days with any count', () {
    final now = DateTime(2026, 11, 24);
    const progress = AdhkarProgress(
      counts: {
        '2026-11-24/morning/a/1': 3,
        '2026-11-24/evening/b/2': 1,
        '2026-11-20/morning/a/1': 1,
        '2026-09-01/morning/a/1': 5,
      },
    );
    expect(adhkarDays(progress, now), 2);
  });

  testWidgets('the wird screen opens the statistics', (tester) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final today = dayKey(DateTime.now());
    await pumpMadarApp(
      tester,
      initialLocation: AppRoutes.dailyReading,
      store: InMemoryKeyValueStore({
        ReadingLog.key: jsonEncode({today: 7}),
        Memorized.key: '{"112":[1,2,3,4]}',
      }),
    );
    await tester.tap(find.byKey(const ValueKey('open-stats')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.statsTitle), findsOneWidget);
    expect(find.text(l10n.statsToday), findsOneWidget);
    expect(find.text('7'), findsWidgets);
    expect(find.text('4'), findsWidgets);
  });
}
