import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/localization/app_locales.dart';
import '../../../core/localization/civil_hijri_date.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_routes.dart';
import '../../reminders/application/reminder_settings_controller.dart';
import '../../reminders/data/reminder_scheduler.dart';
import '../../worship/application/worship_location.dart';
import '../domain/prayer_schedule.dart';
import '../presentation/next_prayer_card.dart' show prayerName;
import 'prayer_preferences.dart';

/// One upcoming prayer as the widget shows it.
typedef WidgetPrayer = ({String name, String time, DateTime at});

/// Writes the coming prayers for the home-screen widget. The default does
/// nothing, so tests and other platforms never touch the plugin; `main`
/// installs [HomePrayerWidget] on Android.
final prayerWidgetProvider = Provider<PrayerWidget>(
  (_) => const NoPrayerWidget(),
);

abstract interface class PrayerWidget {
  Future<void> publish(List<WidgetPrayer> prayers, String place);
}

final class NoPrayerWidget implements PrayerWidget {
  const NoPrayerWidget();

  @override
  Future<void> publish(List<WidgetPrayer> prayers, String place) async {}
}

final class HomePrayerWidget implements PrayerWidget {
  static const _provider =
      'com.abdulrahmanalsaeed.madaralhuda.NextPrayerWidget';

  @override
  Future<void> publish(List<WidgetPrayer> prayers, String place) async {
    await HomeWidget.saveWidgetData<String>(
      'prayer_count',
      '${prayers.length}',
    );
    for (final (index, prayer) in prayers.indexed) {
      await HomeWidget.saveWidgetData<String>(
        'prayer_name_$index',
        prayer.name,
      );
      await HomeWidget.saveWidgetData<String>(
        'prayer_time_$index',
        prayer.time,
      );
      await HomeWidget.saveWidgetData<String>(
        'prayer_at_$index',
        '${prayer.at.millisecondsSinceEpoch}',
      );
    }
    await HomeWidget.saveWidgetData<String>('prayer_place', place);
    await HomeWidget.updateWidget(qualifiedAndroidName: _provider);
    // Move to the next prayer as each one starts, even with the app closed.
    await HomeWidget.scheduleWidgetUpdates([
      for (final prayer in prayers) prayer.at.add(const Duration(seconds: 1)),
    ], qualifiedAndroidName: _provider);
  }
}

/// The next prayers from [now]: the rest of today and all of tomorrow.
List<WidgetPrayer> upcomingPrayers({
  required PrayerSchedule Function(DateTime day) scheduleOn,
  required DateTime now,
  required AppLocalizations l10n,
  required String language,
}) {
  final time = DateFormat.jm(language);
  final today = scheduleOn(now);
  final tomorrow = scheduleOn(now.add(const Duration(days: 1)));
  return [
    for (final event in [...today.today, ...tomorrow.today])
      if (event.slot != PrayerSlot.sunrise && event.time.isAfter(now))
        (
          name: prayerName(event.slot, l10n),
          time: time.format(event.time),
          at: event.time,
        ),
  ];
}

/// Keeps the widget's prayers current with the location, Asr method and
/// language, and refreshes them when the app returns to the foreground.
class PrayerWidgetSync extends ConsumerStatefulWidget {
  const PrayerWidgetSync({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<PrayerWidgetSync> createState() => _PrayerWidgetSyncState();
}

class _PrayerWidgetSyncState extends ConsumerState<PrayerWidgetSync> {
  String? _published;
  Timer? _debounce;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        _published = null;
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final widgetTarget = ref.watch(prayerWidgetProvider);
    if (widgetTarget is NoPrayerWidget) return widget.child;
    final enabled = ref.watch(reminderSettingsProvider).prayerStatus;
    final location = ref.watch(worshipLocationProvider);
    final prayerPlace = ref.watch(prayerPlaceProvider);
    final hanafi = ref.watch(hanafiAsrProvider);
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final accent = Theme.of(context).colorScheme.primary.toARGB32();
    final place =
        location.place?.label(language) ??
        (location.fromDevice ? l10n.deviceLocation : '');
    final signature = [
      prayerPlace?.point.latitude,
      prayerPlace?.point.longitude,
      prayerPlace?.timeZone,
      prayerPlace?.method.name,
      hanafi,
      enabled,
      language,
      place,
      accent,
    ].join('|');
    if (signature != _published) {
      _published = signature;
      _debounce?.cancel();
      _debounce = Timer(const Duration(seconds: 1), () async {
        final prayers = prayerPlace == null
            ? const <WidgetPrayer>[]
            : upcomingPrayers(
                scheduleOn: (day) => PrayerSchedule.calculate(
                  place: prayerPlace,
                  now: day,
                  hanafi: hanafi,
                ),
                now: DateTime.now(),
                l10n: l10n,
                language: language,
              );
        try {
          await widgetTarget.publish(prayers, place);
          final now = DateTime.now();
          final zone = prayerPlace == null
              ? tz.UTC
              : PrayerSchedule.zone(prayerPlace.timeZone) ?? tz.UTC;
          final local = tz.TZDateTime.from(now, zone);
          final days = [
            for (var offset = -1; offset < 32; offset++)
              tz.TZDateTime(zone, local.year, local.month, local.day + offset),
          ];
          final clock = DateFormat.jm(language);
          final statusPrayers = !enabled || prayerPlace == null
              ? const <PrayerEvent>[]
              : [
                  for (final day in days)
                    ...PrayerSchedule.calculate(
                      place: prayerPlace,
                      now: day.add(const Duration(hours: 12)),
                      hanafi: hanafi,
                    ).today.where((event) => event.slot != PrayerSlot.sunrise),
                ];
          await worshipAlarms.invokeMethod<void>('status', {
            'enabled': enabled,
            'place': place,
            'title': l10n.appTitle,
            'accent': accent,
            'lang': language,
            'route': AppRoutes.prayerTimes,
            'locationRoute': '${AppRoutes.prayerTimes}?location=1',
            'open': l10n.sectionPrayerTimesTitle,
            'refresh': language == 'ar' ? 'تحديث الموقع' : 'Update location',
            'choose': l10n.locationChooseTitle,
            'unknown': language == 'ar'
                ? 'اختار مدينتك لعرض مواقيت الصلاة'
                : 'Choose your city to show prayer times',
            'next': l10n.nextPrayer,
            'last': language == 'ar' ? 'آخر صلاة' : 'Last prayer',
            'dates': [
              if (enabled && prayerPlace != null)
                for (final day in days)
                  {
                    'at': day.millisecondsSinceEpoch,
                    'label': civilHijriDate(day, language) ?? '',
                  },
            ],
            'prayers': [
              for (final prayer in statusPrayers)
                {
                  'label': prayerName(prayer.slot, l10n),
                  'time': clock.format(prayer.time),
                  'at': prayer.time.millisecondsSinceEpoch,
                },
            ],
          });
        } on Object catch (error, stack) {
          _published = null;
          FlutterError.reportError(
            FlutterErrorDetails(exception: error, stack: stack),
          );
        }
      });
    }
    return widget.child;
  }
}
