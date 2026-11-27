import '../localization/civil_hijri_date.dart';

enum BrandSeason {
  regular,
  ramadan,
  eid;

  static BrandSeason on(DateTime date) => switch (civilHijri(date)) {
    (month: 9, day: _, year: _) => ramadan,
    (month: 10, day: 1, year: _) => eid,
    _ => regular,
  };

  String asset(String kind, {required bool dark}) {
    final prefix = this == regular ? '' : '$name-';
    return 'assets/brand/$prefix$kind-${dark ? 'dark' : 'light'}.png';
  }
}
