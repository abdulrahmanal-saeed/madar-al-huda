import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/localization/app_locales.dart';
import '../../../core/storage/key_value_store.dart';
import '../../../core/storage/storage_providers.dart';
import '../../qibla/domain/qibla_bearing.dart';

enum WorshipCountry {
  egypt('Africa/Cairo'),
  emirates('Asia/Dubai');

  const WorshipCountry(this.timeZone);
  final String timeZone;
}

extension WorshipCity on ManualCity {
  WorshipCountry get country => timeZone == 'Africa/Cairo'
      ? WorshipCountry.egypt
      : WorshipCountry.emirates;

  String label(AppLocalizations l10n) => switch (this) {
    ManualCity.dubai => l10n.cityDubai,
    ManualCity.abuDhabi => l10n.cityAbuDhabi,
    ManualCity.cairo => l10n.cityCairo,
    ManualCity.alexandria => l10n.cityAlexandria,
  };
}

enum LocationProblem { denied, blocked, unavailable, outside }

class WorshipLocation {
  const WorshipLocation({
    this.city,
    this.devicePoint,
    this.deviceCountry,
    this.loading = false,
    this.problem,
  });

  final ManualCity? city;
  final GeoCoordinate? devicePoint;
  final WorshipCountry? deviceCountry;
  final bool loading;
  final LocationProblem? problem;

  GeoCoordinate? get point => devicePoint ?? city?.center;
  WorshipCountry? get country => deviceCountry ?? city?.country;
}

typedef ReadDeviceLocation = Future<GeoCoordinate> Function({
  required bool requestPermission,
});

final readDeviceLocationProvider = Provider<ReadDeviceLocation>(
  (_) => ({required requestPermission}) async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestPermission) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationProblem.blocked;
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      throw LocationProblem.denied;
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationProblem.unavailable;
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 12),
      ),
    );
    return GeoCoordinate(position.latitude, position.longitude);
  },
);

final worshipLocationProvider =
    NotifierProvider<WorshipLocationController, WorshipLocation>(
      WorshipLocationController.new,
    );

class WorshipLocationController extends Notifier<WorshipLocation> {
  static const cityKey = 'worship.manualCity';
  static const deviceLocationKey = 'worship.useDeviceLocation';
  int _request = 0;
  Future<void> _save = Future.value();

  @override
  WorshipLocation build() {
    final cityId = ref.watch(keyValueStoreProvider).getString(cityKey);
    return WorshipLocation(
      city: ManualCity.values.where((city) => city.id == cityId).firstOrNull,
    );
  }

  Future<void> selectCity(ManualCity city) {
    ++_request;
    state = WorshipLocation(city: city);
    return _persist((store) async {
      await store.setString(cityKey, city.id);
      await store.setBool(deviceLocationKey, value: false);
    });
  }

  /// Refreshes an already granted location and signals when initial setup
  /// should offer the user the option to request Android's permission.
  Future<bool> locateAtStartup() async {
    final preferred = ref
        .read(keyValueStoreProvider)
        .getBool(deviceLocationKey);
    if (_request != 0 || preferred == false) return false;
    final request = _request + 1;
    await _locate(requestPermission: false);
    return ref.mounted &&
        _request == request &&
        preferred == null &&
        state.problem == LocationProblem.denied;
  }

  Future<void> deferDeviceAtStartup() =>
      _persist((store) => store.setBool(deviceLocationKey, value: false));

  Future<void> useDevice() async {
    if (state.loading) return;
    final save = _persist(
      (store) => store.setBool(deviceLocationKey, value: true),
    ).then<void>((_) {}, onError: (Object _, StackTrace _) {});
    await _locate(requestPermission: true);
    await save;
  }

  Future<void> _persist(Future<void> Function(KeyValueStore store) update) {
    final store = ref.read(keyValueStoreProvider);
    final write = _save.then((_) => update(store));
    _save = write.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return write;
  }

  Future<void> _locate({required bool requestPermission}) async {
    final request = ++_request;
    final previous = state;
    state = WorshipLocation(
      city: previous.city,
      devicePoint: previous.devicePoint,
      deviceCountry: previous.deviceCountry,
      loading: true,
    );
    try {
      final point = await ref.read(readDeviceLocationProvider)(
        requestPermission: requestPermission,
      );
      if (!ref.mounted || request != _request) return;
      final country = await ref
          .read(countryBoundariesProvider.future)
          .then((boundaries) => boundaries.countryAt(point));
      if (country == null) throw LocationProblem.outside;
      if (ref.mounted && request == _request) {
        state = WorshipLocation(
          city: previous.city,
          devicePoint: point,
          deviceCountry: country,
        );
      }
    } catch (error) {
      if (ref.mounted && request == _request) {
        state = WorshipLocation(
          city: previous.city,
          problem: error is LocationProblem
              ? error
              : LocationProblem.unavailable,
        );
      }
    }
  }
}

final countryBoundariesProvider = FutureProvider<CountryBoundaries>(
  (_) async => CountryBoundaries(
    jsonDecode(await rootBundle.loadString('assets/location/countries.json'))
        as Map<String, dynamic>,
  ),
);

/// Natural Earth 1:10m polygons, loaded on-device only.
class CountryBoundaries {
  const CountryBoundaries(this.polygons);
  final Map<String, dynamic> polygons;

  WorshipCountry? countryAt(GeoCoordinate point) {
    for (final (code, country) in [
      ('EG', WorshipCountry.egypt),
      ('AE', WorshipCountry.emirates),
    ]) {
      final shapes = polygons[code] as List<dynamic>;
      for (final shape in shapes.cast<List<dynamic>>()) {
        if (_inside(point, shape.first as List<dynamic>) &&
            !shape
                .skip(1)
                .any((ring) => _inside(point, ring as List<dynamic>))) {
          return country;
        }
      }
    }
    return null;
  }

  bool _inside(GeoCoordinate point, List<dynamic> ring) {
    var inside = false;
    var previous = ring.last as List<dynamic>;
    for (final current in ring.cast<List<dynamic>>()) {
      final x1 = previous[0] as num;
      final y1 = previous[1] as num;
      final x2 = current[0] as num;
      final y2 = current[1] as num;
      if ((y1 > point.latitude) != (y2 > point.latitude) &&
          point.longitude <
              x1 + (x2 - x1) * (point.latitude - y1) / (y2 - y1)) {
        inside = !inside;
      }
      previous = current;
    }
    return inside;
  }
}
