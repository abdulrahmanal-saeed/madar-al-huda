import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/storage/key_value_store.dart';
import 'package:madar_al_huda/core/storage/storage_providers.dart';
import 'package:madar_al_huda/features/prayer/domain/prayer_method.dart';
import 'package:madar_al_huda/features/qibla/domain/qibla_bearing.dart';
import 'package:madar_al_huda/features/worship/application/worship_location.dart';
import 'package:madar_al_huda/features/worship/domain/world_cities.dart';

import '../../helpers/places.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer container(
    KeyValueStore store, {
    required ReadDeviceLocation read,
  }) {
    final result = ProviderContainer(
      overrides: [
        keyValueStoreProvider.overrideWithValue(store),
        readDeviceLocationProvider.overrideWithValue(read),
        worldCitiesProvider.overrideWith((_) => testCities()),
      ],
    );
    addTearDown(result.dispose);
    return result;
  }

  group('bundled cities', () {
    final cities = WorldCities.parse(
      File('assets/location/cities.json').readAsStringSync(),
    );

    test('find cities by Arabic or English name, however they are spelt', () {
      expect(cities.search('القاهرة').first.name, 'Cairo');
      expect(cities.search('قاهره').first.name, 'Cairo');
      expect(cities.search('cairo').first.arabicName, 'القاهرة');
      expect(cities.search('الاسكندرية').first.name, 'Alexandria');
      expect(cities.search('مكة').first.country, 'SA');
      expect(cities.search('london').first.country, 'GB');
      expect(cities.search('sao paulo').first.country, 'BR');
      expect(cities.search('xyzzy'), isEmpty);
    });

    test('name a position after the closest city, across borders', () {
      expect(
        cities.nearest(const GeoCoordinate(30.05, 31.24)).timeZone,
        'Africa/Cairo',
      );
      final mecca = cities.nearest(const GeoCoordinate(21.42, 39.82));
      expect(mecca.timeZone, 'Asia/Riyadh');
      expect(mecca.arabicName, 'مكة المكرمة');
      expect(cities.nearest(const GeoCoordinate(-36.85, 174.76)).country, 'NZ');
      expect(cities.countryName('EG', 'ar'), 'مصر');
    });
  });

  test(
    'permission denial preserves selected city and stores no coordinates',
    () async {
      final store = InMemoryKeyValueStore();
      final app = container(
        store,
        read: ({required requestPermission}) async =>
            throw LocationProblem.denied,
      );
      final controller = app.read(worshipLocationProvider.notifier);
      final dubai = WorshipPlace.city(testCities().search('dubai').single);
      await controller.selectCity(dubai);
      await controller.useDevice();
      final location = app.read(worshipLocationProvider);
      expect(location.city, dubai);
      expect(location.problem, LocationProblem.denied);
      expect(location.device, isNull);
      expect(store.values.keys, {
        WorshipLocationController.placeKey,
        WorshipLocationController.deviceLocationKey,
      });
      expect(
        jsonDecode(store.values[WorshipLocationController.placeKey]! as String),
        containsPair('tz', 'Asia/Dubai'),
      );
    },
  );

  test('a city saved before worldwide support still loads', () {
    final app = container(
      InMemoryKeyValueStore({
        WorshipLocationController.cityKey: ManualCity.cairo.id,
      }),
      read: ({required requestPermission}) async =>
          throw LocationProblem.denied,
    );
    final city = app.read(worshipLocationProvider).city!;
    expect(city.timeZone, 'Africa/Cairo');
    expect(city.label('ar'), 'القاهرة');
    expect(app.read(prayerPlaceProvider)?.method, PrayerMethod.egyptian);
  });

  test('startup preserves the manual choice and never repeats a permission request', () async {
    final requests = <bool>[];
    final store = InMemoryKeyValueStore({
      WorshipLocationController.cityKey: ManualCity.dubai.id,
    });
    Future<GeoCoordinate> denied({required bool requestPermission}) async {
      requests.add(requestPermission);
      throw LocationProblem.denied;
    }

    final legacy = container(store, read: denied);
    final controller = legacy.read(worshipLocationProvider.notifier);
    expect(await controller.locateAtStartup(), isTrue);
    await controller.deferDeviceAtStartup();

    final nextLaunch = container(store, read: denied);
    expect(
      await nextLaunch.read(worshipLocationProvider.notifier).locateAtStartup(),
      isFalse,
    );
    expect(nextLaunch.read(worshipLocationProvider).city?.cityId, 292223);
    expect(requests, [false]);
  });

  test(
    'a located position survives a restart, rounded to about 1 km',
    () async {
      final store = InMemoryKeyValueStore();
      final first = container(
        store,
        read: ({required requestPermission}) async =>
            const GeoCoordinate(51.50849, -0.12578),
      );
      await first.read(worshipLocationProvider.notifier).useDevice();
      final device = first.read(worshipLocationProvider).device!;
      expect(device.timeZone, 'Europe/London');
      expect(device.label('ar'), 'لندن');
      expect(
        first.read(prayerPlaceProvider)?.method,
        PrayerMethod.muslimWorldLeague,
      );

      final restart = container(
        store,
        read: ({required requestPermission}) async =>
            throw LocationProblem.unavailable,
      );
      final saved = restart.read(worshipLocationProvider);
      expect(saved.point?.latitude, 51.51);
      expect(saved.point?.longitude, -0.13);
      expect(saved.device?.country, 'GB');

      // GPS off at start-up keeps the saved position instead of an error.
      await restart.read(worshipLocationProvider.notifier).locateAtStartup();
      final after = restart.read(worshipLocationProvider);
      expect(after.problem, isNull);
      expect(after.point?.latitude, 51.51);
    },
  );

  test('a device position saved by an older version still loads', () {
    final app = container(
      InMemoryKeyValueStore({
        WorshipLocationController.deviceLocationKey: true,
        WorshipLocationController.lastDevicePointKey: jsonEncode({
          'lat': 25.2,
          'lng': 55.27,
          'country': 'emirates',
        }),
      }),
      read: ({required requestPermission}) async =>
          throw LocationProblem.unavailable,
    );
    final device = app.read(worshipLocationProvider).device!;
    expect(device.timeZone, 'Asia/Dubai');
    expect(app.read(prayerPlaceProvider)?.method, PrayerMethod.dubai);
  });

  test(
    'a chosen method overrides the country default and can be reset',
    () async {
      final store = InMemoryKeyValueStore({
        WorshipLocationController.cityKey: ManualCity.cairo.id,
      });
      final app = container(
        store,
        read: ({required requestPermission}) async =>
            throw LocationProblem.denied,
      );
      await app
          .read(prayerMethodProvider.notifier)
          .select(PrayerMethod.muslimWorldLeague);
      expect(
        app.read(prayerPlaceProvider)?.method,
        PrayerMethod.muslimWorldLeague,
      );
      await app.read(prayerMethodProvider.notifier).select(null);
      expect(app.read(prayerPlaceProvider)?.method, PrayerMethod.egyptian);
      expect(store.values.containsKey(PrayerMethodChoice.key), isFalse);
    },
  );
}
