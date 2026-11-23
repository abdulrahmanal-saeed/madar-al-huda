import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/storage/key_value_store.dart';
import 'package:madar_al_huda/core/storage/storage_providers.dart';
import 'package:madar_al_huda/features/qibla/domain/qibla_bearing.dart';
import 'package:madar_al_huda/features/worship/application/worship_location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'offline country polygons recognize all four presets and reject Riyadh',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final boundaries = await container.read(countryBoundariesProvider.future);
      for (final city in ManualCity.values) {
        expect(boundaries.countryAt(city.center), city.country);
      }
      expect(
        boundaries.countryAt(const GeoCoordinate(24.7136, 46.6753)),
        isNull,
      );
    },
  );

  test(
    'permission denial preserves selected city and stores no coordinates',
    () async {
      final store = InMemoryKeyValueStore();
      final container = ProviderContainer(
        overrides: [
          keyValueStoreProvider.overrideWithValue(store),
          readDeviceLocationProvider.overrideWithValue(
            ({required requestPermission}) async =>
                throw LocationProblem.denied,
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(worshipLocationProvider.notifier);
      await controller.selectCity(ManualCity.dubai);
      await controller.useDevice();
      final location = container.read(worshipLocationProvider);
      expect(location.city, ManualCity.dubai);
      expect(location.problem, LocationProblem.denied);
      expect(location.devicePoint, isNull);
      expect(store.values, {
        WorshipLocationController.cityKey: 'dubai-ae',
        WorshipLocationController.deviceLocationKey: true,
      });
    },
  );

  test('startup preserves the manual choice and never repeats a permission request', () async {
    final requests = <bool>[];
    final store = InMemoryKeyValueStore({
      WorshipLocationController.cityKey: ManualCity.dubai.id,
    });
    final legacy = ProviderContainer(
      overrides: [
        keyValueStoreProvider.overrideWithValue(store),
        readDeviceLocationProvider.overrideWithValue(({
          required requestPermission,
        }) async {
          requests.add(requestPermission);
          throw LocationProblem.denied;
        }),
      ],
    );
    addTearDown(legacy.dispose);
    final controller = legacy.read(worshipLocationProvider.notifier);
    expect(await controller.locateAtStartup(), isTrue);
    await controller.deferDeviceAtStartup();

    final nextLaunch = ProviderContainer(
      overrides: [
        keyValueStoreProvider.overrideWithValue(store),
        readDeviceLocationProvider.overrideWithValue(({
          required requestPermission,
        }) async {
          requests.add(requestPermission);
          throw LocationProblem.denied;
        }),
      ],
    );
    addTearDown(nextLaunch.dispose);
    expect(
      await nextLaunch.read(worshipLocationProvider.notifier).locateAtStartup(),
      isFalse,
    );
    expect(nextLaunch.read(worshipLocationProvider).city, ManualCity.dubai);
    expect(requests, [false]);
  });
}
