import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/storage/key_value_store.dart';
import 'package:madar_al_huda/features/prayer/application/prayer_widget_sync.dart';
import 'package:madar_al_huda/features/prayer/domain/prayer_schedule.dart';
import 'package:madar_al_huda/features/qibla/domain/qibla_bearing.dart';
import 'package:madar_al_huda/features/worship/application/worship_location.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

PrayerSchedule _dubai(DateTime day) => PrayerSchedule.calculate(
  location: ManualCity.dubai.center,
  country: WorshipCountry.emirates,
  now: day,
  hanafi: false,
);

final class _RecordingWidget implements PrayerWidget {
  final published = <(List<WidgetPrayer>, String)>[];

  @override
  Future<void> publish(List<WidgetPrayer> prayers, String place) async =>
      published.add((prayers, place));
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  setUpAll(() => initializeDateFormatting('en'));

  test('lists the rest of today and all of tomorrow, without sunrise', () {
    // 12:00 in Dubai: Dhuhr has started, Asr is next.
    final now = DateTime.utc(2026, 11, 23, 8, 30);
    final prayers = upcomingPrayers(
      scheduleOn: _dubai,
      now: now,
      l10n: l10n,
      language: 'en',
    );
    expect(prayers.first.name, l10n.prayerAsr);
    expect(prayers.map((p) => p.name).toList(), [
      l10n.prayerAsr,
      l10n.prayerMaghrib,
      l10n.prayerIsha,
      l10n.prayerFajr,
      l10n.prayerDhuhr,
      l10n.prayerAsr,
      l10n.prayerMaghrib,
      l10n.prayerIsha,
    ]);
    expect(prayers.every((p) => p.at.isAfter(now)), isTrue);
  });

  testWidgets('the app publishes the coming prayers with the place', (
    tester,
  ) async {
    final widget = _RecordingWidget();
    await pumpMadarApp(
      tester,
      store: InMemoryKeyValueStore({
        WorshipLocationController.cityKey: ManualCity.dubai.id,
      }),
      additionalOverrides: [prayerWidgetProvider.overrideWithValue(widget)],
    );
    await tester.pump(const Duration(seconds: 2));
    expect(widget.published, isNotEmpty);
    final (prayers, place) = widget.published.last;
    expect(place, l10n.cityDubai);
    expect(prayers, isNotEmpty);
  });
}
