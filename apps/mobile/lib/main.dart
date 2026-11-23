import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'core/storage/key_value_store.dart';
import 'core/storage/storage_providers.dart';
import 'features/adhkar/data/adhkar_progress.dart';
import 'features/quran/data/local_quran_bookmarks.dart';
import 'features/settings/data/settings_repository.dart';
import 'features/worship/data/daily_reading_plan.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicense();

  if (defaultTargetPlatform == TargetPlatform.android) {
    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.abdulrahmanalsaeed.madar.recitation',
        androidNotificationChannelName: 'Quran recitation',
        androidNotificationOngoing: true,
      );
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack),
      );
    }
  }
  final store = await _openPreferences();

  runApp(
    ProviderScope(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
      child: const MadarApp(),
    ),
  );
}

/// Opens on-device preferences. If the platform store is unavailable the app
/// still starts, with defaults kept in memory for this session.
Future<KeyValueStore> _openPreferences() async {
  try {
    return await SharedPreferencesKeyValueStore.create(
      allowList: {
        ...SettingsRepository.keys,
        'worship.manualCity',
        'worship.hanafiAsr',
        'quran.lastRead.v1',
        LocalQuranBookmarks.key,
        AdhkarProgressController.key,
        DailyReadingPlanController.key,
        'quran.reciter.v1',
      },
    );
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'madar_al_huda',
        context: ErrorDescription('while opening preferences'),
      ),
    );
    return InMemoryKeyValueStore();
  }
}

/// Shows the bundled font's OFL licence on the licences page.
void _registerFontLicense() {
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString(
      'assets/fonts/ibm_plex_sans_arabic/OFL.txt',
    );
    yield LicenseEntryWithLineBreaks(['IBM Plex Sans Arabic'], text);
    yield LicenseEntryWithLineBreaks([
      'Amiri Quran',
    ], await rootBundle.loadString('assets/fonts/amiri_quran/OFL.txt'));
    yield LicenseEntryWithLineBreaks([
      'Reem Kufi',
    ], await rootBundle.loadString('assets/fonts/reem_kufi/OFL.txt'));
    yield LicenseEntryWithLineBreaks([
      'Amiri',
    ], await rootBundle.loadString('assets/fonts/amiri/OFL.txt'));
  });
}
