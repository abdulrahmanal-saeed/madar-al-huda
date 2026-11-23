import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:madar_al_huda/app/app.dart';
import 'package:madar_al_huda/app/app_router.dart';
import 'package:madar_al_huda/core/audio/audio_playback.dart';
import 'package:madar_al_huda/core/storage/key_value_store.dart';
import 'package:madar_al_huda/core/storage/storage_providers.dart';
import 'package:madar_al_huda/features/adhkar/data/adhkar_catalog.dart';
import 'package:madar_al_huda/features/quran/data/mushaf_edition.dart';
import 'package:madar_al_huda/features/quran/data/quran_services.dart';
import 'package:madar_al_huda/features/worship/application/cairo_radio_stream.dart';
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
AdhkarCatalog? _testAdhkar;

Future<InMemoryKeyValueStore> pumpMadarApp(
  WidgetTester tester, {
  InMemoryKeyValueStore? store,
  List<Locale> deviceLocales = const [Locale('en', 'US')],
  Size size = phoneSize,
  bool showStartupSplash = false,
  String? initialLocation,
  QuranApi? quranApi,
  AudioPlayer? audioPlayer,
  Uri? cairoRadioStream,
}) async {
  final kv = store ?? InMemoryKeyValueStore();
  _testMushaf ??= await tester.runAsync(() => MushafEdition.load(rootBundle));
  _testAdhkar ??= await tester.runAsync(() async {
    final source = await rootBundle.loadString('assets/adhkar/catalog.json');
    return AdhkarCatalog.fromJson(jsonDecode(source) as Map<String, Object?>);
  });

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
        adhkarCatalogProvider.overrideWith((_) => _testAdhkar!),
        if (quranApi != null) quranApiProvider.overrideWithValue(quranApi),
        if (audioPlayer != null)
          audioPlayerProvider.overrideWithValue(audioPlayer),
        if (cairoRadioStream != null)
          cairoRadioStreamProvider.overrideWithValue(cairoRadioStream),
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
