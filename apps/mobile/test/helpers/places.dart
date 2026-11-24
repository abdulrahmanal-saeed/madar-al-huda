import 'package:madar_al_huda/features/prayer/domain/prayer_method.dart';
import 'package:madar_al_huda/features/prayer/domain/prayer_schedule.dart';
import 'package:madar_al_huda/features/qibla/domain/qibla_bearing.dart';
import 'package:madar_al_huda/features/worship/application/worship_location.dart';
import 'package:madar_al_huda/features/worship/domain/world_cities.dart';

/// Prayer settings for one of the four original presets.
PrayerPlace placeOf(ManualCity city) => PrayerPlace(
  point: city.center,
  timeZone: city.timeZone,
  method: PrayerMethod.forCountry(WorshipPlace.legacyCity(city.id)!.country),
);

/// A few cities in place of the bundled list.
WorldCities testCities() => WorldCities(
  const [
    WorldCity(
      id: 360630,
      name: 'Cairo',
      arabicName: 'القاهرة',
      country: 'EG',
      latitude: 30.0626,
      longitude: 31.2497,
      timeZone: 'Africa/Cairo',
      population: 9606,
    ),
    WorldCity(
      id: 292223,
      name: 'Dubai',
      arabicName: 'دبي',
      country: 'AE',
      latitude: 25.0772,
      longitude: 55.3093,
      timeZone: 'Asia/Dubai',
      population: 3790,
    ),
    WorldCity(
      id: 108410,
      name: 'Riyadh',
      arabicName: 'الرياض',
      country: 'SA',
      latitude: 24.6877,
      longitude: 46.7219,
      timeZone: 'Asia/Riyadh',
      population: 4205,
    ),
    WorldCity(
      id: 2643743,
      name: 'London',
      arabicName: 'لندن',
      country: 'GB',
      latitude: 51.5085,
      longitude: -0.1257,
      timeZone: 'Europe/London',
      population: 8961,
    ),
    WorldCity(
      id: 361058,
      name: 'Alexandria',
      arabicName: 'الإسكندرية',
      country: 'EG',
      latitude: 31.2018,
      longitude: 29.9158,
      timeZone: 'Africa/Cairo',
      population: 5263,
    ),
  ],
  const {
    'EG': ['Egypt', 'مصر'],
    'AE': ['UAE', 'الإمارات'],
    'SA': ['Saudi Arabia', 'المملكة العربية السعودية'],
    'GB': ['United Kingdom', 'المملكة المتحدة'],
  },
);
