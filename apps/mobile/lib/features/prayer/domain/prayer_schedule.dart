import 'package:adhan_dart/adhan_dart.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../qibla/domain/qibla_bearing.dart';
import '../../worship/application/worship_location.dart';

enum PrayerSlot { fajr, sunrise, dhuhr, asr, maghrib, isha }

typedef PrayerEvent = ({PrayerSlot slot, tz.TZDateTime time});

class PrayerSchedule {
  const PrayerSchedule({required this.today, required this.next});

  final List<PrayerEvent> today;
  final PrayerEvent next;

  static final _zones = _loadZones();

  static Map<WorshipCountry, tz.Location> _loadZones() {
    tzdata.initializeTimeZones();
    return {
      for (final country in WorshipCountry.values)
        country: tz.getLocation(country.timeZone),
    };
  }

  factory PrayerSchedule.calculate({
    required GeoCoordinate location,
    required WorshipCountry country,
    required DateTime now,
    required bool hanafi,
  }) {
    final zone = _zones[country]!;
    final localNow = tz.TZDateTime.from(now, zone);
    final date = DateTime.utc(localNow.year, localNow.month, localNow.day);
    final parameters =
        (country == WorshipCountry.egypt
              ? CalculationMethodParameters.egyptian()
              : CalculationMethodParameters.dubai())
          ..madhab = hanafi ? Madhab.hanafi : Madhab.shafi;

    PrayerTimes calculate(DateTime date) => PrayerTimes(
      date: date,
      coordinates: Coordinates(location.latitude, location.longitude),
      calculationParameters: parameters,
    );

    final times = calculate(date);
    const slots = PrayerSlot.values;
    final values = [
      times.fajr,
      times.sunrise,
      times.dhuhr,
      times.asr,
      times.maghrib,
      times.isha,
    ];
    final today = [
      for (var i = 0; i < slots.length; i++)
        (slot: slots[i], time: tz.TZDateTime.from(values[i], zone)),
    ];
    final next =
        today
            .where(
              (event) =>
                  event.slot != PrayerSlot.sunrise && event.time.isAfter(now),
            )
            .firstOrNull ??
        (
          slot: PrayerSlot.fajr,
          time: tz.TZDateTime.from(
            calculate(date.add(const Duration(days: 1))).fajr,
            zone,
          ),
        );
    return PrayerSchedule(today: today, next: next);
  }
}
