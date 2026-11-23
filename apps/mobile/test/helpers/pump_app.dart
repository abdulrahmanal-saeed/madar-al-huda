import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/app/app.dart';
import 'package:madar_al_huda/app/app_router.dart';
import 'package:madar_al_huda/core/storage/key_value_store.dart';
import 'package:madar_al_huda/core/storage/storage_providers.dart';
import 'package:madar_al_huda/features/quran/data/mushaf_edition.dart';
import 'package:madar_al_huda/features/quran/data/quran_services.dart';
import 'package:material_ui/material_ui.dart';

/// Phone-sized logical viewport (Pixel-class device).
const Size phoneSize = Size(412, 915);

/// Tablet-sized logical viewport (triggers the navigation rail).
const Size tabletSize = Size(1024, 768);

/// Pumps the full app with an in-memory preferences store.
///
/// [deviceLocales] simulates the device language list; [store] lets a test
/// pre-seed or inspect persisted preferences.
MushafEdition? _testMushaf;

Future<InMemoryKeyValueStore> pumpMadarApp(
  WidgetTester tester, {
  InMemoryKeyValueStore? store,
  List<Locale> deviceLocales = const [Locale('en', 'US')],
  Size size = phoneSize,
  bool showStartupSplash = false,
  String? initialLocation,
  QuranApi? quranApi,
}) async {
  final kv = store ?? InMemoryKeyValueStore();
  _testMushaf ??= await tester.runAsync(() => MushafEdition.load(rootBundle));

  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.platformDispatcher.localesTestValue = deviceLocales;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  await tester.pumpWidget(
    ProviderScope(
      // Fresh scope (and router) on every pump, even within one test.
      key: UniqueKey(),
      overrides: [
        keyValueStoreProvider.overrideWithValue(kv),
        mushafEditionProvider.overrideWith((_) => _testMushaf!),
        if (quranApi != null) quranApiProvider.overrideWithValue(quranApi),
        if (initialLocation != null)
          appRouterProvider.overrideWith((ref) {
            final router = buildAppRouter(initialLocation: initialLocation);
            ref.onDispose(router.dispose);
            return router;
          }),
      ],
      child: MadarApp(showStartupSplash: showStartupSplash),
    ),
  );
  await tester.pumpAndSettle();
  return kv;
}

/// The text direction in effect at the app's home content.
TextDirection appDirection(WidgetTester tester) =>
    Directionality.of(tester.element(find.byType(Scaffold).first));
