import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_router.dart';
import '../../../core/localization/app_locales.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../adhkar/data/adhkar_catalog.dart';
import '../../adhkar/data/quran_dua_index.dart';
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
  Timer? _debounce;
  String? _planned;
  DateTime? _plannedAt;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        final at = _plannedAt;
        if (at != null && DateTime.now().difference(at) > _renewAfter) {
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
    final location = ref.watch(worshipLocationProvider);
    final hanafi = ref.watch(hanafiAsrProvider);
    final edition = settings.dailyDua || settings.duaEveryHours > 0
        ? ref.watch(mushafEditionProvider).asData?.value
        : null;
    final duaIndex = ref.watch(quranDuaIndexProvider).asData?.value;
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final point = location.point;
    final country = location.country;
    final signature = [
      settings.encode(),
      point?.latitude,
      point?.longitude,
      country?.name,
      hanafi,
      language,
      edition != null,
      duaIndex?.length,
    ].join('|');
    if (signature != _planned) {
      _planned = signature;
      _debounce?.cancel();
      _debounce = Timer(const Duration(seconds: 1), () async {
        await _started;
        if (!mounted) return;
        final reminders = point == null || country == null
            ? const <PlannedReminder>[]
            : planReminders(
                settings: settings,
                scheduleOn: (day) => PrayerSchedule.calculate(
                  location: point,
                  country: country,
                  now: day,
                  hanafi: hanafi,
                ),
                now: DateTime.now(),
                texts: L10nReminderTexts(l10n, language),
                duas: edition == null
                    ? const []
                    : remindersDuas(
                        edition,
                        duaIndex ?? quranDuaIndex,
                        language,
                      ),
              );
        try {
          await ref.read(reminderSchedulerProvider).replaceAll(reminders);
          _plannedAt = DateTime.now();
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
