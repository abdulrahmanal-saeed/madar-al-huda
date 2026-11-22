import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/features/prayer/domain/prayer_schedule.dart';
import 'package:madar_al_huda/features/qibla/domain/qibla_bearing.dart';
import 'package:madar_al_huda/features/worship/application/worship_location.dart';

void main() {
  PrayerSchedule times(ManualCity city, DateTime date, {bool hanafi = false}) =>
      PrayerSchedule.calculate(
        location: city.center,
        country: city.country,
        now: date,
        hanafi: hanafi,
      );

  test('all four city schedules contain six chronological local times', () {
    for (final city in ManualCity.values) {
      final result = times(city, DateTime.utc(2026, 11, 22, 8));
      expect(
        result.today.map((event) => event.slot),
        orderedEquals(PrayerSlot.values),
      );
      expect(result.today.map((event) => event.time.day).toSet(), {22});
      for (var i = 1; i < result.today.length; i++) {
        expect(
          result.today[i - 1].time.isBefore(result.today[i].time),
          isTrue,
          reason: city.id,
        );
      }
    }
  });

  test('Cairo switches DST on the location date and Dubai keeps UTC+04', () {
    final cases = [
      (ManualCity.cairo, DateTime.utc(2026, 4, 23, 12), 2),
      (ManualCity.cairo, DateTime.utc(2026, 4, 24, 12), 3),
      (ManualCity.cairo, DateTime.utc(2026, 10, 29, 12), 3),
      (ManualCity.cairo, DateTime.utc(2026, 10, 30, 12), 2),
      (ManualCity.dubai, DateTime.utc(2026, 4, 24, 12), 4),
      (ManualCity.dubai, DateTime.utc(2026, 10, 30, 12), 4),
    ];
    for (final (city, date, offset) in cases) {
      expect(
        times(city, date).today.first.time.timeZoneOffset,
        Duration(hours: offset),
      );
    }
  });

  test('after Isha the next prayer is Fajr on the next local day', () {
    final result = times(ManualCity.dubai, DateTime.utc(2026, 11, 22, 18));
    expect(result.next.slot, PrayerSlot.fajr);
    expect(result.next.time.day, 23);
  });

  test('Hanafi Asr is later and does not change the other entries', () {
    final now = DateTime.utc(2026, 11, 22, 10);
    final standard = times(ManualCity.cairo, now);
    final hanafi = times(ManualCity.cairo, now, hanafi: true);
    for (var i = 0; i < standard.today.length; i++) {
      if (standard.today[i].slot == PrayerSlot.asr) {
        expect(hanafi.today[i].time.isAfter(standard.today[i].time), isTrue);
      } else {
        expect(hanafi.today[i].time, standard.today[i].time);
      }
    }
  });
}
