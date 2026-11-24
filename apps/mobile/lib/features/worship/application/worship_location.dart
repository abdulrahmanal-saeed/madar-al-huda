import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/storage/key_value_store.dart';
import '../../../core/storage/storage_providers.dart';
import '../../prayer/domain/prayer_method.dart';
import '../../prayer/domain/prayer_schedule.dart';
import '../../qibla/domain/qibla_bearing.dart';
import '../domain/world_cities.dart';

enum LocationProblem { denied, blocked, unavailable }

/// One place prayer times and the Qibla are worked out for.
class WorshipPlace {
  const WorshipPlace({
    required this.point,
    required this.timeZone,
    required this.country,
    this.name,
    this.arabicName,
    this.cityId,
  });

  WorshipPlace.city(WorldCity city)
    : this(
        point: city.point,
        timeZone: city.timeZone,
        country: city.country,
        name: city.name,
        arabicName: city.arabicName,
        cityId: city.id,
      );

  /// A device position, named after (and in the time zone of) the closest
  /// listed place.
  WorshipPlace.near(GeoCoordinate point, WorldCity city)
    : this(
        point: point,
        timeZone: city.timeZone,
        country: city.country,
        name: city.name,
        arabicName: city.arabicName,
        cityId: city.id,
      );

  final GeoCoordinate point;
  final String timeZone;

  /// ISO 3166 code, which picks the default calculation method.
  final String country;
  final String? name;
  final String? arabicName;
  final int? cityId;

  String? label(String language) =>
      language == 'ar' ? arabicName ?? name : name;

  Map<String, Object?> toJson() => {
    'lat': point.latitude,
    'lng': point.longitude,
    'tz': timeZone,
    'cc': country,
    if (name != null) 'name': name,
    if (arabicName != null) 'ar': arabicName,
    if (cityId != null) 'id': cityId,
  };

  static WorshipPlace? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final latitude = raw['lat'];
    final longitude = raw['lng'];
    if (latitude is! num || longitude is! num) return null;
    if (latitude.abs() > 90 || longitude.abs() > 180) return null;
    // Saved before worldwide support: only Egypt and the UAE existed.
    final legacy = switch (raw['country']) {
      'egypt' => ('Africa/Cairo', 'EG'),
      'emirates' => ('Asia/Dubai', 'AE'),
      _ => null,
    };
    final timeZone = raw['tz'] ?? legacy?.$1;
    final country = raw['cc'] ?? legacy?.$2;
    if (timeZone is! String || country is! String) return null;
    return WorshipPlace(
      point: GeoCoordinate(latitude.toDouble(), longitude.toDouble()),
      timeZone: timeZone,
      country: country,
      name: raw['name'] as String?,
      arabicName: raw['ar'] as String?,
      cityId: raw['id'] as int?,
    );
  }

  /// The four cities offered before worldwide support, by their saved ids.
  static WorshipPlace? legacyCity(String? id) {
    final city = ManualCity.values.where((city) => city.id == id).firstOrNull;
    if (city == null) return null;
    final (name, arabic, country, geonameId) = switch (city) {
      ManualCity.dubai => ('Dubai', 'دبي', 'AE', 292223),
      ManualCity.abuDhabi => ('Abu Dhabi', 'أبوظبي', 'AE', 292968),
      ManualCity.cairo => ('Cairo', 'القاهرة', 'EG', 360630),
      ManualCity.alexandria => ('Alexandria', 'الإسكندرية', 'EG', 361058),
    };
    return WorshipPlace(
      point: city.center,
      timeZone: city.timeZone,
      country: country,
      name: name,
      arabicName: arabic,
      cityId: geonameId,
    );
  }
}

class WorshipLocation {
  const WorshipLocation({
    this.city,
    this.device,
    this.loading = false,
    this.problem,
  });

  /// The city the user picked, used while the device position is off.
  final WorshipPlace? city;

  /// The device position, when the user chose to use it.
  final WorshipPlace? device;
  final bool loading;
  final LocationProblem? problem;

  WorshipPlace? get place => device ?? city;
  GeoCoordinate? get point => place?.point;
  bool get fromDevice => device != null;
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

/// The bundled city list, parsed off the UI thread.
final worldCitiesProvider = FutureProvider<WorldCities>((_) async {
  final source = await rootBundle.loadString('assets/location/cities.json');
  return Isolate.run(() => WorldCities.parse(source));
});

final worshipLocationProvider =
    NotifierProvider<WorshipLocationController, WorshipLocation>(
      WorshipLocationController.new,
    );

class WorshipLocationController extends Notifier<WorshipLocation> {
  /// The city picked before worldwide support (`cairo-eg`, …).
  static const cityKey = 'worship.manualCity';

  /// The picked city as JSON.
  static const placeKey = 'worship.city';
  static const deviceLocationKey = 'worship.useDeviceLocation';

  /// Last device position, kept so prayer times show immediately (and
  /// offline) after a restart while a fresh reading is taken.
  static const lastDevicePointKey = 'worship.lastDevicePoint';
  int _request = 0;
  Future<void> _save = Future.value();

  @override
  WorshipLocation build() {
    final store = ref.watch(keyValueStoreProvider);
    final city =
        _decode(store.getString(placeKey)) ??
        WorshipPlace.legacyCity(store.getString(cityKey));
    if (store.getBool(deviceLocationKey) == true) {
      final saved = _decode(store.getString(lastDevicePointKey));
      if (saved != null) return WorshipLocation(city: city, device: saved);
    }
    return WorshipLocation(city: city);
  }

  static WorshipPlace? _decode(String? raw) {
    if (raw == null) return null;
    try {
      return WorshipPlace.fromJson(jsonDecode(raw));
    } on Object {
      return null;
    }
  }

  Future<void> selectCity(WorshipPlace city) {
    ++_request;
    state = WorshipLocation(city: city);
    return _persist((store) async {
      await store.setString(placeKey, jsonEncode(city.toJson()));
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
      device: previous.device,
      loading: true,
    );
    try {
      final point = await ref.read(readDeviceLocationProvider)(
        requestPermission: requestPermission,
      );
      if (!ref.mounted || request != _request) return;
      final nearest = (await ref.read(worldCitiesProvider.future))
          .nearest(point);
      if (!ref.mounted || request != _request) return;
      // Rounded to about 1 km: enough for prayer times and Qibla, without
      // keeping a precise position on the device.
      final device = WorshipPlace.near(
        GeoCoordinate(
          (point.latitude * 100).round() / 100,
          (point.longitude * 100).round() / 100,
        ),
        nearest,
      );
      state = WorshipLocation(city: previous.city, device: device);
      await _persist(
        (store) =>
            store.setString(lastDevicePointKey, jsonEncode(device.toJson())),
      ).then<void>((_) {}, onError: (Object _, StackTrace _) {});
    } catch (error) {
      if (!ref.mounted || request != _request) return;
      // A silent refresh at start-up keeps the last saved position instead
      // of leaving prayer times empty when GPS is off or slow.
      if (!requestPermission && previous.device != null) {
        state = WorshipLocation(city: previous.city, device: previous.device);
        return;
      }
      state = WorshipLocation(
        city: previous.city,
        problem: error is LocationProblem ? error : LocationProblem.unavailable,
      );
    }
  }
}

/// Null means the country's own method ([PrayerMethod.forCountry]).
final prayerMethodProvider =
    NotifierProvider<PrayerMethodChoice, PrayerMethod?>(PrayerMethodChoice.new);

class PrayerMethodChoice extends Notifier<PrayerMethod?> {
  static const key = 'worship.prayerMethod';

  @override
  PrayerMethod? build() {
    final saved = ref.watch(keyValueStoreProvider).getString(key);
    return PrayerMethod.values.where((m) => m.name == saved).firstOrNull;
  }

  Future<void> select(PrayerMethod? method) async {
    final store = ref.read(keyValueStoreProvider);
    if (method == null) {
      await store.remove(key);
    } else {
      await store.setString(key, method.name);
    }
    state = method;
  }
}

/// Everything prayer times need about where the user is, or null before a
/// location is known.
final prayerPlaceProvider = Provider<PrayerPlace?>((ref) {
  final place = ref.watch(worshipLocationProvider.select((l) => l.place));
  if (place == null) return null;
  return PrayerPlace(
    point: place.point,
    timeZone: place.timeZone,
    method:
        ref.watch(prayerMethodProvider) ??
        PrayerMethod.forCountry(place.country),
  );
});
