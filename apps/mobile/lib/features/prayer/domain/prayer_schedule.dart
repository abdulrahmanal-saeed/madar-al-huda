import 'package:adhan_dart/adhan_dart.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../qibla/domain/qibla_bearing.dart';
import 'prayer_method.dart';

enum PrayerSlot { fajr, sunrise, dhuhr, asr, maghrib, isha }

typedef PrayerEvent = ({PrayerSlot slot, tz.TZDateTime time});

/// Where and how prayer times are calculated.
class PrayerPlace {
  const PrayerPlace({
    required this.point,
    required this.timeZone,
    required this.method,
  });

  final GeoCoordinate point;

  /// IANA name, such as `Africa/Cairo`.
  final String timeZone;
  final PrayerMethod method;

  @override
  bool operator ==(Object other) =>
      other is PrayerPlace &&
      other.point.latitude == point.latitude &&
      other.point.longitude == point.longitude &&
      other.timeZone == timeZone &&
      other.method == method;

  @override
  int get hashCode =>
      Object.hash(point.latitude, point.longitude, timeZone, method);
}

class PrayerSchedule {
  const PrayerSchedule({required this.today, required this.next});

  final List<PrayerEvent> today;
  final PrayerEvent next;

  static final _zones = <String, tz.Location>{};
  static var _zonesLoaded = false;

  /// The IANA zone, or null when the bundled time-zone data lacks it.
  static tz.Location? zone(String name) {
    if (!_zonesLoaded) {
      tzdata.initializeTimeZones();
      _zonesLoaded = true;
    }
    final cached = _zones[name];
    if (cached != null) return cached;
    try {
      return _zones[name] = tz.getLocation(name);
    } on Object {
      return null;
    }
  }

  factory PrayerSchedule.calculate({
    required PrayerPlace place,
    required DateTime now,
    required bool hanafi,
  }) {
    final zone = PrayerSchedule.zone(place.timeZone) ?? tz.UTC;
    final localNow = tz.TZDateTime.from(now, zone);
    final date = DateTime.utc(localNow.year, localNow.month, localNow.day);
    final parameters = place.method.parameters()
      ..madhab = hanafi ? Madhab.hanafi : Madhab.shafi
      // Above 48° twilight can last all night in summer.
      ..highLatitudeRule = HighLatitudeRule.recommended(
        Coordinates(place.point.latitude, place.point.longitude),
      )
      ..polarCircleResolution = PolarCircleResolution.unresolved;

    List<DateTime>? attempt(DateTime date, double latitude) {
      try {
        final times = PrayerTimes(
          date: date,
          coordinates: Coordinates(latitude, place.point.longitude),
          calculationParameters: parameters,
        );
        final values = [
          times.fajr,
          times.sunrise,
          times.dhuhr,
          times.asr,
          times.maghrib,
          times.isha,
        ];
        for (var i = 1; i < values.length; i++) {
          if (!values[i - 1].isBefore(values[i])) return null;
        }
        final span = values.last.difference(values.first);
        return span > Duration.zero && span < const Duration(hours: 24)
            ? values
            : null;
      } on Object {
        return null;
      }
    }

    // Inside the polar circles the sun may not rise or set for weeks. Use
    // the nearest latitude where it does, keeping the local longitude.
    List<DateTime> calculate(DateTime date) {
      var latitude = place.point.latitude;
      while (true) {
        final values = attempt(date, latitude);
        if (values != null || latitude.abs() < 1) return values!;
        latitude -= latitude.sign;
      }
    }

    final values = calculate(date);
    const slots = PrayerSlot.values;
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
            calculate(date.add(const Duration(days: 1))).first,
            zone,
          ),
        );
    return PrayerSchedule(today: today, next: next);
  }
}
