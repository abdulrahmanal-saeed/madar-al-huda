import 'dart:math' as math;

import 'package:intl/intl.dart';

const _englishMonths = [
  'Muharram',
  'Safar',
  'Rabi I',
  'Rabi II',
  'Jumada I',
  'Jumada II',
  'Rajab',
  'Shaban',
  'Ramadan',
  'Shawwal',
  'Dhu al-Qadah',
  'Dhu al-Hijjah',
];

const _arabicMonths = [
  'محرم',
  'صفر',
  'ربيع الأول',
  'ربيع الآخر',
  'جمادى الأولى',
  'جمادى الآخرة',
  'رجب',
  'شعبان',
  'رمضان',
  'شوال',
  'ذو القعدة',
  'ذو الحجة',
];

typedef CivilHijri = ({int year, int month, int day});

/// The tabular Hijri calendar uses the civil epoch and a 30-year leap cycle.
/// Dates determined by local moon sighting can differ from the civil date.
CivilHijri? civilHijri(DateTime date) {
  final day = DateTime.utc(date.year, date.month, date.day);
  final elapsed = day.difference(DateTime.utc(622, 7, 19)).inDays;
  if (elapsed < 0) return null;
  final year = (30 * elapsed + 10646) ~/ 10631;
  final dayOfYear = elapsed - ((year - 1) * 354 + (3 + 11 * year) ~/ 30);
  final monthIndex = math.min(11, 2 * dayOfYear ~/ 59);
  final dayOfMonth = dayOfYear - (59 * monthIndex + 1) ~/ 2 + 1;
  return (year: year, month: monthIndex + 1, day: dayOfMonth);
}

String? civilHijriDate(DateTime date, String language) {
  final hijri = civilHijri(date);
  if (hijri == null) return null;
  final (:year, :month, day: dayOfMonth) = hijri;
  final monthIndex = month - 1;
  final numbers = NumberFormat('0', language);
  final name = (language == 'ar' ? _arabicMonths : _englishMonths)[monthIndex];
  final era = language == 'ar' ? 'هـ' : 'AH';
  return '${numbers.format(dayOfMonth)} $name ${numbers.format(year)} $era';
}
