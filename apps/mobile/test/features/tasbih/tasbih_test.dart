import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/core/storage/key_value_store.dart';
import 'package:madar_al_huda/core/storage/storage_providers.dart';
import 'package:madar_al_huda/features/tasbih/application/tasbih_controller.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  test('counts, reaches the goal once and keeps today separate', () {
    final store = InMemoryKeyValueStore();
    final container = ProviderContainer(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final controller = container.read(tasbihProvider.notifier)
      ..clock = () => DateTime(2026, 11, 24, 9);
    container.read(tasbihProvider);

    var reached = 0;
    for (var i = 0; i < 34; i++) {
      if (controller.increment()) reached++;
    }
    expect(reached, 1);
    final state = container.read(tasbihProvider);
    expect(state.count, 34);
    expect(state.today, 34);
    expect(state.total, 34);

    controller.reset();
    expect(container.read(tasbihProvider).count, 0);
    expect(container.read(tasbihProvider).today, 34);

    // The next day starts today's tally again; the lifetime total continues.
    controller.clock = () => DateTime(2026, 11, 25, 9);
    controller.increment();
    expect(container.read(tasbihProvider).today, 1);
    expect(container.read(tasbihProvider).total, 35);
  });

  test('restores a saved round and ignores bad values', () {
    final store = InMemoryKeyValueStore({
      TasbihController.key: jsonEncode({
        'phrase': 99,
        'goal': 7,
        'count': 12,
        'day': '2000-01-01',
        'today': 50,
        'total': 400,
      }),
    });
    final container = ProviderContainer(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final state = container.read(tasbihProvider);
    expect(state.phrase, 0);
    expect(state.goal, 33);
    expect(state.count, 12);
    expect(state.today, 0, reason: 'a different day');
    expect(state.total, 400);
  });

  testWidgets('tapping counts and the round survives a restart', (
    tester,
  ) async {
    final store = await pumpMadarApp(tester, initialLocation: AppRoutes.tasbih);
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.text(l10n.tasbihTitle), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const ValueKey('tasbih-tap')));
    }
    await tester.pump();
    expect(find.text('3'), findsOneWidget);
    expect(find.text(l10n.tasbihToday('3')), findsOneWidget);

    await pumpMadarApp(tester, store: store, initialLocation: AppRoutes.tasbih);
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tasbih-reset')));
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
  });
}
