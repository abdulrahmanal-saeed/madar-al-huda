import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/app_router.dart';
import '../../../core/audio/devotional_recording.dart';
import '../../../core/content/app_settings.dart';
import '../../../core/localization/app_locales.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../adhkar/data/quran_dua_index.dart';
import '../../home/data/daily_duas.dart';
import '../../prayer/application/prayer_preferences.dart';
import '../../prayer/domain/prayer_schedule.dart';
import '../../prayer/presentation/next_prayer_card.dart' as prayer_card;
import '../../quran/data/mushaf_edition.dart';
import '../../worship/application/worship_location.dart';
import '../data/reminder_scheduler.dart';
import '../domain/reminder_plan.dart';
import 'reminder_settings_controller.dart';

/// Keeps the scheduled reminders in step with the settings, the location
/// and the language, and routes taps on a reminder into the app.
///
/// Reminders are planned a week ahead; the plan is renewed whenever an
/// input changes and when the app returns after a few hours.
class ReminderSync extends ConsumerStatefulWidget {
  const ReminderSync({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ReminderSync> createState() => _ReminderSyncState();
}

class _ReminderSyncState extends ConsumerState<ReminderSync> {
  static const _renewAfter = Duration(hours: 6);

  Future<void>? _started;
  Future<void> _audioCache = Future.value();
  Timer? _debounce;
  String? _planned;
  DateTime? _plannedAt;
  Duration? _plannedOffset;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        final at = _plannedAt;
        final now = DateTime.now();
        if (at != null &&
            (now.difference(at) > _renewAfter ||
                _plannedOffset != now.timeZoneOffset)) {
          _planned = null;
          if (mounted) setState(() {});
        }
      },
    );
    _started = _start();
  }

  Future<void> _start() async {
    final scheduler = ref.read(reminderSchedulerProvider);
    try {
      final route = await scheduler.start(_open);
      if (route != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _open(route));
      }
    } on Object catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack),
      );
    }
  }

  void _open(String route) {
    if (!mounted) return;
    ref.read(appRouterProvider).go(route);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(reminderSettingsProvider);
    final place = ref.watch(prayerPlaceProvider);
    final hanafi = ref.watch(hanafiAsrProvider);
    // Prayer notifications show a verse too, so they need the Mushaf text.
    final edition =
        settings.dailyDua ||
            settings.duaEveryHours > 0 ||
            settings.adhan ||
            settings.beforePrayer
        ? ref.watch(mushafEditionProvider).asData?.value
        : null;
    final verseRefs = ref.watch(appSettingsProvider).prayerVerses;
    final needsDua = settings.dailyDua || settings.duaEveryHours > 0;
    final dailyDuas = needsDua
        ? ref.watch(dailyDuasProvider).asData?.value ?? bundledDailyDuas
        : const <DailyDua>[];
    final recordings = needsDua
        ? ref.watch(dailyDuaRecordingsProvider)
        : const <String, DevotionalRecording>{};
    final sounds = {
      for (final entry in recordings.entries)
        entry.key: entry.value.url.queryParameters['library_media']!,
    };
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final signature = [
      settings.encode(),
      '$verseRefs',
      place?.point.latitude,
      place?.point.longitude,
      place?.timeZone,
      place?.method.name,
      hanafi,
      language,
      edition != null,
      '$dailyDuas',
      '$sounds',
    ].join('|');
    if (signature != _planned) {
      _planned = signature;
      _debounce?.cancel();
      _debounce = Timer(const Duration(seconds: 1), () async {
        await _started;
        if (!mounted) return;
        String? deviceZone;
        if (!kIsWeb &&
            defaultTargetPlatform == TargetPlatform.android &&
            place == null) {
          try {
            deviceZone = await worshipAlarms.invokeMethod<String>('zone');
          } catch (_) {}
        }
        if (!mounted || signature != _planned) return;
        final reminders = planReminders(
          settings: settings,
          scheduleOn: place == null
              ? null
              : (day) => PrayerSchedule.calculate(
                  place: place,
                  now: day,
                  hanafi: hanafi,
                ),
          deviceZone: deviceZone == null
              ? null
              : PrayerSchedule.zone(deviceZone),
          now: DateTime.now(),
          texts: L10nReminderTexts(l10n, language),
          duas: [
            for (final dua in dailyDuas)
              (
                text: language == 'ar' ? dua.ar : dua.en,
                source: language == 'ar' ? dua.sourceAr : dua.sourceEn,
              ),
          ],
          days: 32,
          duaIds: dailyDuas.map((dua) => dua.id).toList(),
          duaSounds: sounds,
          prayerVerses: edition == null
              ? const []
              : prayerVerses(
                  edition,
                  language,
                  refs: verseRefs.isEmpty ? prayerVerseRefs : verseRefs,
                ),
        );
        if (!kIsWeb &&
            defaultTargetPlatform == TargetPlatform.android &&
            recordings.isNotEmpty) {
          _audioCache = _audioCache.then(
            (_) => _cacheReminderAudio(
              recordings.values,
              reminders,
              isCurrent: () => mounted && signature == _planned,
            ),
          );
          unawaited(_audioCache);
        }
        try {
          await ref.read(reminderSchedulerProvider).replaceAll(reminders);
          _plannedAt = DateTime.now();
          _plannedOffset = _plannedAt?.timeZoneOffset;
        } on Object catch (error, stack) {
          _planned = null;
          FlutterError.reportError(
            FlutterErrorDetails(exception: error, stack: stack),
          );
        }
      });
    }
    return widget.child;
  }
}

/// Verses on prayer shown in prayer notifications: (surah, first, last).
const prayerVerseRefs = [
  (2, 238, 238),
  (4, 103, 103),
  (29, 45, 45),
  (20, 14, 14),
  (2, 45, 45),
  (11, 114, 114),
  (17, 78, 78),
  (14, 40, 40),
  (20, 132, 132),
  (23, 1, 2),
  (2, 153, 153),
];

/// The text of [prayerVerseRefs] from the bundled Mushaf, without the
/// basmala that opens a surah's first verse in this text.
Future<void> _cacheReminderAudio(
  Iterable<DevotionalRecording> recordings,
  List<PlannedReminder> reminders, {
  required bool Function() isCurrent,
}) async {
  if (!isCurrent()) return;
  final needed = reminders
      .map((reminder) => reminder.sound)
      .whereType<String>()
      .toSet();
  try {
    final root = await getApplicationSupportDirectory();
    final folder = Directory('${root.path}/devotional')
      ..createSync(recursive: true);
    final byName = {
      for (final recording in recordings)
        recording.url.queryParameters['library_media']!: recording,
    };
    // planReminders returns time order. Download the first alarms' audio first.
    for (final name in needed) {
      if (!isCurrent()) break;
      final recording = byName[name];
      if (recording == null) continue;
      final file = File('${folder.path}/$name');
      if (await file.exists() && await file.length() == recording.bytes) {
        continue;
      }
      final pending = File(
        '${folder.path}/$name.${DateTime.now().microsecondsSinceEpoch}.partial',
      );
      final client = http.Client();
      try {
        final response = await client
            .send(http.Request('GET', recording.url)..followRedirects = false)
            .timeout(const Duration(seconds: 12));
        final length = response.contentLength;
        if (response.statusCode != 200 ||
            (length != null && length != recording.bytes)) {
          continue;
        }
        var count = 0;
        final handle = await pending.open(mode: FileMode.write);
        try {
          await for (final chunk in response.stream.timeout(
            const Duration(seconds: 15),
          )) {
            count += chunk.length;
            if (count > recording.bytes) break;
            await handle.writeFrom(chunk);
          }
        } finally {
          await handle.close();
        }
        if (count == recording.bytes) await pending.rename(file.path);
      } catch (_) {
        // The alarm shows the published text and sound fallback.
      } finally {
        client.close();
        if (await pending.exists()) await pending.delete();
      }
    }
  } catch (_) {
    // A device unable to store recordings can still display reminders.
  }
}

List<ReminderDua> prayerVerses(
  MushafEdition edition,
  String language, {
  List<(int, int, int)> refs = prayerVerseRefs,
}) {
  final number = decimalFormat(language).format;
  final basmala = edition.surahs.first.verses.first;
  return [
    for (final (surah, first, last) in refs)
      // The dashboard checks ranges too; skip any this text cannot show.
      if (surah >= 1 &&
          surah <= edition.surahs.length &&
          first >= 1 &&
          last >= first &&
          last <= edition.surahs[surah - 1].verses.length)
        (
          text: edition.surahs[surah - 1].verses
              .sublist(first - 1, last)
              .map(
                (verse) => verse.startsWith('$basmala ')
                    ? verse.substring(basmala.length + 1)
                    : verse,
              )
              .join(' '),
          source:
              '${edition.surahs[surah - 1].name(language)} ${number(first)}'
              '${last == first ? '' : '–${number(last)}'}',
        ),
  ];
}

/// Every Quranic supplication in the catalog, with its verse text and a
/// short source such as «البقرة ٢٠١».
List<ReminderDua> remindersDuas(
  MushafEdition edition,
  Map<DuaTopic, List<DuaRange>> index,
  String language,
) {
  final number = decimalFormat(language).format;
  final ranges = {for (final group in index.values) ...group};
  return [
    for (final range in ranges)
      if (range.surah <= edition.surahs.length)
        (
          text: edition.surahs[range.surah - 1].verses
              .sublist(range.first - 1, range.last)
              .join(' '),
          source:
              '${edition.surahs[range.surah - 1].name(language)} '
              '${number(range.first)}'
              '${range.last == range.first ? '' : '–${number(range.last)}'}',
        ),
  ];
}

class L10nReminderTexts implements ReminderTexts {
  L10nReminderTexts(this.l10n, String language)
    : _number = decimalFormat(language).format;

  final AppLocalizations l10n;
  final String Function(num) _number;

  @override
  String prayerName(PrayerSlot slot) => prayer_card.prayerName(slot, l10n);
  @override
  String adhanTitle(String prayer) => l10n.reminderAdhanTitle(prayer);
  @override
  String adhanBody(String prayer) => l10n.reminderPrayerBody;
  @override
  String beforePrayerTitle(String prayer, int minutes) =>
      l10n.reminderBeforeTitle(prayer, _number(minutes));
  @override
  String afterPrayerTitle(String prayer) => l10n.reminderAfterTitle(prayer);
  @override
  String get afterPrayerBody => l10n.reminderAfterBody;
  @override
  String get morningTitle => l10n.remindersMorning;
  @override
  String get eveningTitle => l10n.remindersEvening;
  @override
  String get bedtimeTitle => l10n.remindersBedtime;
  @override
  String get adhkarBody => l10n.reminderAdhkarBody;
  @override
  String get kahfTitle => l10n.reminderKahfTitle;
  @override
  String get kahfBody => l10n.reminderKahfBody;
  @override
  String get duaTitle => l10n.reminderDuaTitle;
  @override
  String get suhoorTitle => l10n.reminderSuhoorTitle;
  @override
  String get suhoorBody => l10n.reminderSuhoorBody;
  @override
  String get iftarTitle => l10n.reminderIftarTitle;
  @override
  String get iftarBody => l10n.reminderIftarBody;
  @override
  String fastingTitle(FastingDay day) => switch (day) {
    FastingDay.arafah => l10n.reminderFastArafah,
    FastingDay.tasua => l10n.reminderFastTasua,
    FastingDay.ashura => l10n.reminderFastAshura,
    FastingDay.whiteDay => l10n.reminderFastWhiteDay,
    FastingDay.monday => l10n.reminderFastMonday,
    FastingDay.thursday => l10n.reminderFastThursday,
  };
  @override
  String get fastingBody => l10n.reminderFastBody;
}
