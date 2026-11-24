import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/features/prayer/domain/prayer_method.dart';
import 'package:madar_al_huda/features/prayer/domain/prayer_schedule.dart';
import 'package:madar_al_huda/features/qibla/domain/qibla_bearing.dart';
import 'package:madar_al_huda/features/worship/domain/world_cities.dart';

import '../../helpers/places.dart';

void main() {
  PrayerSchedule times(ManualCity city, DateTime date, {bool hanafi = false}) =>
      PrayerSchedule.calculate(place: placeOf(city), now: date, hanafi: hanafi);

  void expectChronological(PrayerSchedule result, String reason) {
    expect(
      result.today.map((event) => event.slot),
      orderedEquals(PrayerSlot.values),
      reason: reason,
    );
    for (var i = 1; i < result.today.length; i++) {
      expect(
        result.today[i - 1].time.isBefore(result.today[i].time),
        isTrue,
        reason: '$reason ${result.today[i].slot}',
      );
    }
  }

  test('cities everywhere, polar summers included, get six ordered times', () {
    final places = [
      ('Riyadh', 24.6877, 46.7219, 'Asia/Riyadh', 'SA'),
      ('London', 51.5085, -0.1257, 'Europe/London', 'GB'),
      ('New York', 40.7143, -74.006, 'America/New_York', 'US'),
      ('Jakarta', -6.2146, 106.8451, 'Asia/Jakarta', 'ID'),
      ('Tromsø', 69.6496, 18.957, 'Europe/Oslo', 'NO'),
      ('Cape Town', -33.9258, 18.4232, 'Africa/Johannesburg', 'ZA'),
    ];
    for (final (name, lat, lng, zone, country) in places) {
      for (final day in [
        DateTime.utc(2026, 6, 21, 12),
        DateTime.utc(2026, 12, 21, 12),
      ]) {
        final result = PrayerSchedule.calculate(
          place: PrayerPlace(
            point: GeoCoordinate(lat, lng),
            timeZone: zone,
            method: PrayerMethod.forCountry(country),
          ),
          now: day,
          hanafi: false,
        );
        expectChronological(result, '$name $day');
        expect(result.today.first.time.location.name, zone);
      }
    }
  });

  test(
    'each country gets its own authority, others the Muslim World League',
    () {
      expect(PrayerMethod.forCountry('EG'), PrayerMethod.egyptian);
      expect(PrayerMethod.forCountry('AE'), PrayerMethod.dubai);
      expect(PrayerMethod.forCountry('SA'), PrayerMethod.ummAlQura);
      expect(PrayerMethod.forCountry('US'), PrayerMethod.northAmerica);
      expect(PrayerMethod.forCountry('GB'), PrayerMethod.muslimWorldLeague);
      for (final method in PrayerMethod.values) {
        expect(method.parameters(), isNotNull);
      }
    },
  );

  test('every time zone in the bundled city list is known', () {
    final cities = WorldCities.parse(
      File('assets/location/cities.json').readAsStringSync(),
    );
    final missing = {
      for (final city in cities.cities)
        if (PrayerSchedule.zone(city.timeZone) == null) city.timeZone,
    };
    expect(missing, isEmpty);
    expect(cities.cities.length, greaterThan(30000));
  });

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

  test(
    'dated Egypt and UAE comparisons reproduce the recorded differences',
    () {
      Map<String, dynamic> fixture(String file) => jsonDecode(
        File('../../docs/prayer/reference/$file').readAsStringSync(),
      ) as Map<String, dynamic>;
      List<Map<String, dynamic>> rows(
        Map<String, dynamic> fixture,
        String key,
      ) => (fixture[key] as List).cast<Map<String, dynamic>>();
      final egypt = fixture('official-2026-11-22.json');
      final uae = fixture('uae-2026-11-comparison.json');
      final cities = {for (final city in ManualCity.values) city.id: city};
      final fields = (egypt['fields'] as List).cast<String>();
      int minutes(String time) {
        final fields = time.split(':').map(int.parse).toList();
        return fields[0] * 60 + fields[1];
      }

      List<int> differences(String city, String day, List<dynamic> reference) {
        final date = DateTime.parse('${day}T12:00:00Z');
        final actual = times(cities[city]!, date).today;
        return [
          for (var index = 0; index < actual.length; index++)
            actual[index].time.hour * 60 +
                actual[index].time.minute -
                minutes(reference[index] as String),
        ];
      }

      for (final city in rows(egypt, 'cities')) {
        final official = city['local_times'] as Map<String, dynamic>?;
        if (official == null) continue;
        expect(
          differences(city['city_id'] as String, city['date'] as String, [
            for (final field in fields) official[field],
          ]),
          city['city_id'] == 'cairo-eg'
              ? [0, 0, 1, 0, 0, 0]
              : [1, 0, 1, 0, 0, 0],
        );
      }
      final sources = {
        for (final source in rows(uae, 'sources'))
          source['id'] as String: source['city'] as String,
      };
      for (final sample in rows(uae, 'samples')) {
        final source = sample['source'] as String;
        final date = sample['date'] as String;
        expect(
          differences(sources[source]!, date, sample['reference'] as List),
          sample['difference_minutes'],
          reason: '$source on $date',
        );
      }
    },
  );
}
