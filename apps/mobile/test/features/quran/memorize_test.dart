import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/core/storage/key_value_store.dart';
import 'package:madar_al_huda/core/storage/storage_providers.dart';
import 'package:madar_al_huda/features/quran/application/memorization.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  test('memorized verses are saved by surah and ignore bad data', () async {
    final store = InMemoryKeyValueStore({
      Memorized.key: '{"1":[1,2,999],"200":[1],"x":[3]}',
    });
    final container = ProviderContainer(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    expect(container.read(memorizedProvider), {
      1: {1, 2},
    });
    final memorized = container.read(memorizedProvider.notifier);
    await memorized.toggle(1, 2);
    await memorized.setRange(112, 1, 4, on: true);
    expect(container.read(memorizedProvider), {
      1: {1},
      112: {1, 2, 3, 4},
    });
    await memorized.setRange(1, 1, 7, on: false);
    expect(container.read(memorizedProvider).containsKey(1), isFalse);
    expect(firstWordOf('قُلْ هُوَ ٱللَّهُ أَحَدٌ'), 'قُلْ');
  });

  testWidgets('hide a verse, recite, reveal, count and mark it', (
    tester,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final store = await pumpMadarApp(
      tester,
      initialLocation: AppRoutes.memorize,
    );
    await tester.tap(find.byKey(const ValueKey('memorize-surah-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.memorizeHide));
    await tester.pumpAndSettle();
    expect(find.text(l10n.memorizeTapToReveal), findsWidgets);

    await tester.tap(find.text(l10n.memorizeTapToReveal).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('memorize-count-1')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.memorizeRepeated('1', '5')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('memorized-1')));
    await tester.pumpAndSettle();
    expect(store.getString(Memorized.key), '{"1":[1]}');

    // Verse 1 of another surah starts after the basmala.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '112');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('memorize-surah-112')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.memorizeFirstWord));
    await tester.pumpAndSettle();
    expect(find.textContaining('قُلْ'), findsOneWidget);
    expect(find.textContaining('بِسْمِ'), findsNothing);
  });
}
