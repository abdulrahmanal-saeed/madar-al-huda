import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'app/first_run.dart';
import 'core/audio/audio_handler.dart';
import 'core/audio/audio_playback.dart';
import 'core/auth/google_account.dart';
import 'core/diagnostics/error_log.dart';
import 'core/storage/key_value_store.dart';
import 'core/storage/storage_providers.dart';
import 'features/adhkar/data/adhkar_progress.dart';
import 'features/hadith/data/hadith_favorites.dart';
import 'features/prayer/application/prayer_preferences.dart';
import 'features/prayer/application/prayer_widget_sync.dart';
import 'features/quran/application/memorization.dart';
import 'features/quran/application/reading_preferences.dart';
import 'features/quran/data/local_quran_bookmarks.dart';
import 'features/reminders/application/reminder_settings_controller.dart';
import 'features/reminders/data/reminder_scheduler.dart';
import 'features/settings/data/settings_repository.dart';
import 'features/tasbih/application/tasbih_controller.dart';
import 'features/worship/application/worship_location.dart';
import 'features/worship/data/daily_reading_plan.dart';
import 'features/worship/data/khatma.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Errors are kept on the phone only; Settings shows them for sharing.
  final errorLog = ErrorLog(getApplicationSupportDirectory);
  captureErrors(errorLog);
  _registerFontLicense();

  // One player for recitation, lessons and radio; on Android its media
  // session (notification, lock screen, headset) runs through audio_service.
  final player = AudioPlayer();
  MadarAudioHandler? audioHandler;
  if (defaultTargetPlatform == TargetPlatform.android) {
    try {
      audioHandler = await AudioService.init(
        builder: () => MadarAudioHandler(player),
        config: const AudioServiceConfig(
          androidNotificationChannelId:
              'com.abdulrahmanalsaeed.madar.recitation',
          androidNotificationChannelName: 'Madar Al-Huda audio',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      );
    } catch (error, stack) {
      // Playback still works, without the notification.
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack),
      );
    }
  }
  final store = await _openPreferences();
  final googleAuth = await initializeGoogleAccount();

  runApp(
    ProviderScope(
      overrides: [
        keyValueStoreProvider.overrideWithValue(store),
        googleAuthProvider.overrideWithValue(googleAuth),
        errorLogProvider.overrideWithValue(errorLog),
        audioPlayerProvider.overrideWithValue(player),
        audioHandlerProvider.overrideWithValue(audioHandler),
        if (defaultTargetPlatform == TargetPlatform.android)
          reminderSchedulerProvider.overrideWithValue(LocalReminderScheduler()),
        if (defaultTargetPlatform == TargetPlatform.android)
          prayerWidgetProvider.overrideWithValue(HomePrayerWidget()),
      ],
      child: const MadarApp(),
    ),
  );
}

/// Every key the app stores. The platform store refuses any other key, so a
/// new key must be added here (see storage_allow_list_test.dart).
@visibleForTesting
final Set<String> storageAllowList = {
  ...SettingsRepository.keys,
  WorshipLocationController.cityKey,
  WorshipLocationController.placeKey,
  PrayerMethodChoice.key,
  WorshipLocationController.deviceLocationKey,
  WorshipLocationController.lastDevicePointKey,
  ReminderSettingsController.key,
  HanafiAsr.key,
  HadithFavorites.key,
  'quran.lastRead.v1',
  LocalQuranBookmarks.key,
  LocalQuranBookmarks.backupKey,
  ReadingPreferencesController.key,
  TasbihController.key,
  AdhkarProgressController.key,
  DailyReadingPlanController.key,
  ReadingLog.key,
  Memorized.key,
  KhatmaGoalController.key,
  'quran.reciter.v1',
  firstRunDoneKey,
};

/// Opens on-device preferences. If the platform store is unavailable the app
/// still starts, with defaults kept in memory for this session.
Future<KeyValueStore> _openPreferences() async {
  try {
    return await SharedPreferencesKeyValueStore.create(
      allowList: storageAllowList,
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
const _contentSources = [
  (
    'Tanzil Project',
    'Quran text: Tanzil Project (tanzil.net), used under its terms: the '
        'text is reproduced verbatim with no changes.',
  ),
  (
    'Quran Foundation',
    'Tafsir, translations and some recitations: Quran Foundation '
        '(quran.foundation) Content API, under its terms of use.',
  ),
  (
    'MP3Quran',
    'Recitations and verse timings: MP3Quran (mp3quran.net), and '
        'recordings published by Yousef Heiba.',
  ),
  (
    'HadeethEnc',
    'Hadiths, grades and explanations: the Encyclopedia of Translated '
        'Prophetic Hadiths (hadeethenc.com).',
  ),
  (
    'Hisn al-Muslim',
    "Adhkar and supplications: Hisn al-Muslim by Sa'id ibn Ali ibn Wahf "
        'Al-Qahtani, with narrations from HadeethEnc and Sunnah.com.',
  ),
  ('Quran.com', 'Quranic supplication topics: Quran.com.'),
  (
    'Egyptian Radio',
    'Holy Quran Radio from Cairo: the National Media Authority of Egypt '
        '(misrquran.gov.eg).',
  ),
];

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
    yield const LicenseEntryWithLineBreaks(
      ['GeoNames'],
      'City names, positions and time zones: GeoNames (geonames.org), '
      'licensed under Creative Commons Attribution 4.0 '
      '(creativecommons.org/licenses/by/4.0). Arabic country names: '
      'Unicode CLDR, under the Unicode License.',
    );
    // Content sources are credited here only, not on the reading screens.
    for (final (name, credit) in _contentSources) {
      yield LicenseEntryWithLineBreaks([name], credit);
    }
  });
}
