import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:madar_al_huda/app/app.dart';
import 'package:madar_al_huda/app/app_router.dart';
import 'package:madar_al_huda/core/audio/audio_playback.dart';
import 'package:madar_al_huda/core/connectivity/offline_banner.dart';
import 'package:madar_al_huda/core/content/managed_library.dart';
import 'package:madar_al_huda/core/storage/key_value_store.dart';
import 'package:madar_al_huda/core/storage/storage_providers.dart';
import 'package:madar_al_huda/features/adhkar/data/adhkar_catalog.dart';
import 'package:madar_al_huda/features/adhkar/data/quran_dua_index.dart';
import 'package:madar_al_huda/features/hadith/data/hadeeth_enc.dart';
import 'package:madar_al_huda/features/quran/data/mushaf_edition.dart';
import 'package:madar_al_huda/features/quran/data/quran_services.dart';
import 'package:madar_al_huda/features/worship/application/cairo_radio_stream.dart';
import 'package:madar_al_huda/features/worship/application/worship_location.dart';
import 'package:material_ui/material_ui.dart';

import 'places.dart';

/// HadeethEnc without network or disk: tests that show hadiths override
/// the hadith providers themselves.
class OfflineHadeethEnc extends HadeethEnc {
  OfflineHadeethEnc()
    : super(http.Client(), () async => throw UnsupportedError('no disk'));

  @override
  Future<Object?> get(
    String path,
    Map<String, String> fields, {
    Duration fresh = Duration.zero,
  }) async => throw StateError('HadeethEnc unavailable in tests');
}

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
  bool offline = false,
  Size size = phoneSize,
  bool showStartupSplash = false,
  String? initialLocation,
  QuranApi? quranApi,
  AudioPlayer? audioPlayer,
  Uri? cairoRadioStream,
  List<Override> additionalOverrides = const [],
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
        quranDuaIndexProvider.overrideWith((_) => quranDuaIndex),
        managedLibraryProvider.overrideWith((_) => null),
        worldCitiesProvider.overrideWith((_) => testCities()),
        offlineProvider.overrideWith((_) => Stream.value(offline)),
        hadeethEncProvider.overrideWithValue(OfflineHadeethEnc()),
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
        ...additionalOverrides,
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
