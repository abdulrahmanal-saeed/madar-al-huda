import 'dart:convert';

import '../../worship/domain/worship_moment.dart';

/// Which reminders the user turned on. Everything is off until the user
/// opts in, because each one needs Android's notification permission.
class ReminderSettings {
  const ReminderSettings({
    this.adhan = false,
    this.beforePrayer = false,
    this.beforePrayerMinutes = 15,
    this.morning = false,
    this.evening = false,
    this.afterPrayer = false,
    this.bedtime = false,
    this.bedtimeMinutes = defaultBedtimeMinutes,
    this.kahf = false,
    this.dailyDua = false,
    this.duaEveryHours = 0,
    this.suhoor = false,
    this.iftar = false,
    this.fastMonThu = false,
    this.fastWhiteDays = false,
    this.fastOccasions = false,
    this.quietStartMinutes = 23 * 60,
    this.quietEndMinutes = 6 * 60,
  });

  factory ReminderSettings.fromJson(Map<String, Object?> data) {
    bool flag(String key) => data[key] == true;
    int number(String key, int fallback, int min, int max) {
      final value = data[key];
      return value is int && value >= min && value <= max ? value : fallback;
    }

    const day = 24 * 60 - 1;
    final every = data['duaEveryHours'];
    return ReminderSettings(
      adhan: flag('adhan'),
      beforePrayer: flag('beforePrayer'),
      beforePrayerMinutes: number('beforePrayerMinutes', 15, 5, 60),
      morning: flag('morning'),
      evening: flag('evening'),
      afterPrayer: flag('afterPrayer'),
      bedtime: flag('bedtime'),
      bedtimeMinutes: number('bedtimeMinutes', defaultBedtimeMinutes, 0, day),
      kahf: flag('kahf'),
      dailyDua: flag('dailyDua'),
      duaEveryHours: every is int && duaIntervals.contains(every) ? every : 0,
      suhoor: flag('suhoor'),
      iftar: flag('iftar'),
      fastMonThu: flag('fastMonThu'),
      fastWhiteDays: flag('fastWhiteDays'),
      fastOccasions: flag('fastOccasions'),
      quietStartMinutes: number('quietStartMinutes', 23 * 60, 0, day),
      quietEndMinutes: number('quietEndMinutes', 6 * 60, 0, day),
    );
  }

  static ReminderSettings decode(String? raw) {
    if (raw == null) return const ReminderSettings();
    try {
      return ReminderSettings.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      return const ReminderSettings();
    }
  }

  /// Allowed values for [duaEveryHours]; 0 turns the reminder off.
  static const duaIntervals = [0, 3, 5, 8];

  final bool adhan;
  final bool beforePrayer;
  final int beforePrayerMinutes;
  final bool morning;
  final bool evening;
  final bool afterPrayer;
  final bool bedtime;

  /// Minutes after midnight.
  final int bedtimeMinutes;
  final bool kahf;
  final bool dailyDua;

  /// Hours between supplication reminders; 0 when off.
  final int duaEveryHours;

  /// Ramadan only: 30 minutes before imsak, and at Maghrib.
  final bool suhoor;
  final bool iftar;

  /// Voluntary fasting, reminded the evening before: Mondays and Thursdays,
  /// the white days (13-15 of each Hijri month), and Arafah, Tasua and
  /// Ashura.
  final bool fastMonThu;
  final bool fastWhiteDays;
  final bool fastOccasions;

  /// No supplication reminders between these times (minutes after midnight).
  final int quietStartMinutes;
  final int quietEndMinutes;

  bool get anyEnabled =>
      adhan ||
      beforePrayer ||
      morning ||
      evening ||
      afterPrayer ||
      bedtime ||
      kahf ||
      dailyDua ||
      duaEveryHours > 0 ||
      suhoor ||
      iftar ||
      fastMonThu ||
      fastWhiteDays ||
      fastOccasions;

  Map<String, Object?> toJson() => {
    'adhan': adhan,
    'beforePrayer': beforePrayer,
    'beforePrayerMinutes': beforePrayerMinutes,
    'morning': morning,
    'evening': evening,
    'afterPrayer': afterPrayer,
    'bedtime': bedtime,
    'bedtimeMinutes': bedtimeMinutes,
    'kahf': kahf,
    'dailyDua': dailyDua,
    'duaEveryHours': duaEveryHours,
    'suhoor': suhoor,
    'iftar': iftar,
    'fastMonThu': fastMonThu,
    'fastWhiteDays': fastWhiteDays,
    'fastOccasions': fastOccasions,
    'quietStartMinutes': quietStartMinutes,
    'quietEndMinutes': quietEndMinutes,
  };

  String encode() => jsonEncode(toJson());

  ReminderSettings copyWith({
    bool? adhan,
    bool? beforePrayer,
    int? beforePrayerMinutes,
    bool? morning,
    bool? evening,
    bool? afterPrayer,
    bool? bedtime,
    int? bedtimeMinutes,
    bool? kahf,
    bool? dailyDua,
    int? duaEveryHours,
    bool? suhoor,
    bool? iftar,
    bool? fastMonThu,
    bool? fastWhiteDays,
    bool? fastOccasions,
  }) => ReminderSettings(
    adhan: adhan ?? this.adhan,
    beforePrayer: beforePrayer ?? this.beforePrayer,
    beforePrayerMinutes: beforePrayerMinutes ?? this.beforePrayerMinutes,
    morning: morning ?? this.morning,
    evening: evening ?? this.evening,
    afterPrayer: afterPrayer ?? this.afterPrayer,
    bedtime: bedtime ?? this.bedtime,
    bedtimeMinutes: bedtimeMinutes ?? this.bedtimeMinutes,
    kahf: kahf ?? this.kahf,
    dailyDua: dailyDua ?? this.dailyDua,
    duaEveryHours: duaEveryHours ?? this.duaEveryHours,
    suhoor: suhoor ?? this.suhoor,
    iftar: iftar ?? this.iftar,
    fastMonThu: fastMonThu ?? this.fastMonThu,
    fastWhiteDays: fastWhiteDays ?? this.fastWhiteDays,
    fastOccasions: fastOccasions ?? this.fastOccasions,
    quietStartMinutes: quietStartMinutes,
    quietEndMinutes: quietEndMinutes,
  );
}
