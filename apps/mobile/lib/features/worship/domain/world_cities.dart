import 'dart:convert';
import 'dart:math' as math;

import '../../../core/localization/search_text.dart';
import '../../qibla/domain/qibla_bearing.dart';

/// A populated place from the bundled GeoNames list (15,000+ people).
class WorldCity {
  const WorldCity({
    required this.id,
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.timeZone,
    this.arabicName,
    this.asciiName,
    this.population = 0,
  });

  final int id;
  final String name;
  final String? arabicName;

  /// The name without accents, when it differs (São Paulo → Sao Paulo).
  final String? asciiName;
  final String country;
  final double latitude;
  final double longitude;
  final String timeZone;

  /// Thousands of people, used to rank search results.
  final int population;

  GeoCoordinate get point => GeoCoordinate(latitude, longitude);

  String label(String language) => language == 'ar' ? arabicName ?? name : name;
}

/// Every city of the bundled list, searchable in Arabic and English, all on
/// the device.
class WorldCities {
  WorldCities(this.cities, this._countries)
    : _keys = [for (final city in cities) _CityKeys.of(city, _countries)];

  /// Parses `assets/location/cities.json` (see its README for the format).
  factory WorldCities.parse(String source) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    final zones = (data['zones'] as List<dynamic>).cast<String>();
    final countries = {
      for (final MapEntry(:key, :value)
          in (data['countries'] as Map<String, dynamic>).entries)
        key: (value as List<dynamic>).cast<String>(),
    };
    final cities = <WorldCity>[];
    for (final row in (data['cities'] as List<dynamic>).cast<List<dynamic>>()) {
      final ascii = row[2] as String;
      final arabic = row[3] as String;
      cities.add(
        WorldCity(
          id: row[0] as int,
          name: row[1] as String,
          arabicName: arabic.isEmpty ? null : arabic,
          asciiName: ascii.isEmpty ? null : ascii,
          country: row[4] as String,
          latitude: (row[5] as num).toDouble(),
          longitude: (row[6] as num).toDouble(),
          timeZone: zones[row[7] as int],
          population: row[8] as int,
        ),
      );
    }
    return WorldCities(cities, countries);
  }

  /// Largest first.
  final List<WorldCity> cities;
  final Map<String, List<String>> _countries;
  final List<_CityKeys> _keys;

  String countryName(String code, String language) {
    final names = _countries[code];
    if (names == null) return code;
    return language == 'ar' ? names[1] : names[0];
  }

  /// The closest listed place, which gives a device position its time zone,
  /// country and a readable name.
  WorldCity nearest(GeoCoordinate point) {
    WorldCity? best;
    var bestDistance = double.infinity;
    final latitude = point.latitude * math.pi / 180;
    final scale = math.cos(latitude);
    for (final city in cities) {
      final dLat = city.latitude - point.latitude;
      var dLng = (city.longitude - point.longitude).abs();
      if (dLng > 180) dLng = 360 - dLng;
      final distance = dLat * dLat + dLng * dLng * scale * scale;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = city;
      }
    }
    return best!;
  }

  /// The country's largest places, for the picker before anything is typed.
  List<WorldCity> largestIn(String? country, {int limit = 30}) {
    final matches = country == null
        ? cities
        : cities.where((city) => city.country == country);
    return matches.take(limit).toList();
  }

  /// Matches city and country names in either language, ignoring hamza
  /// forms, ta marbuta, diacritics, letter case and the Arabic article.
  List<WorldCity> search(String query, {int limit = 50}) {
    final needle = normalizeSearch(query);
    if (needle.isEmpty) return const [];
    final ranked = <(int, int)>[];
    for (var i = 0; i < cities.length; i++) {
      final rank = _keys[i].rank(needle);
      if (rank != null) ranked.add((rank, i));
    }
    // Stable on the population order the list already has.
    ranked.sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
    return [for (final (_, index) in ranked.take(limit)) cities[index]];
  }
}

class _CityKeys {
  const _CityKeys(this.names, this.countries);

  factory _CityKeys.of(WorldCity city, Map<String, List<String>> countries) =>
      _CityKeys(
        [
          normalizeSearch(city.name),
          if (city.asciiName case final ascii?) normalizeSearch(ascii),
          if (city.arabicName case final arabic?) normalizeSearch(arabic),
        ],
        [
          for (final name in countries[city.country] ?? const <String>[])
            normalizeSearch(name),
        ],
      );

  final List<String> names;
  final List<String> countries;

  int? rank(String needle) {
    var best = 99;
    for (final name in names) {
      if (name == needle) return 0;
      if (name.startsWith(needle)) {
        best = math.min(best, 1);
      } else if (name.contains(' $needle')) {
        best = math.min(best, 2);
      } else if (name.contains(needle)) {
        best = math.min(best, 3);
      }
    }
    if (best == 99) {
      for (final name in countries) {
        if (name == needle || name.startsWith(needle)) best = 4;
      }
    }
    return best == 99 ? null : best;
  }
}
