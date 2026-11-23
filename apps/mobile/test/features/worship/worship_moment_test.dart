import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/features/prayer/domain/prayer_schedule.dart';
import 'package:madar_al_huda/features/qibla/domain/qibla_bearing.dart';
import 'package:madar_al_huda/features/worship/application/worship_location.dart';
import 'package:madar_al_huda/features/worship/domain/worship_moment.dart';

void main() {
  // Noon in Dubai on 23 November 2026.
  final schedule = PrayerSchedule.calculate(
    location: ManualCity.dubai.center,
    country: WorshipCountry.emirates,
    now: DateTime.utc(2026, 11, 23, 8),
    hanafi: false,
  );
  DateTime at(PrayerSlot slot, [Duration offset = Duration.zero]) =>
      schedule.today.firstWhere((e) => e.slot == slot).time.add(offset);
  WorshipMoment? moment(DateTime now, {int? bedtime}) => worshipMomentAt(
    schedule,
    now,
    bedtimeMinutes: bedtime ?? defaultBedtimeMinutes,
  );

  test('right after each prayer suggests the after-prayer remembrance', () {
    for (final slot in [
      PrayerSlot.fajr,
      PrayerSlot.dhuhr,
      PrayerSlot.asr,
      PrayerSlot.maghrib,
      PrayerSlot.isha,
    ]) {
      expect(
        moment(at(slot, const Duration(minutes: 5))),
        WorshipMoment.afterPrayer,
        reason: '$slot',
      );
    }
  });

  test('morning runs from after Fajr until Dhuhr', () {
    expect(
      moment(at(PrayerSlot.fajr, const Duration(minutes: 45))),
      WorshipMoment.morning,
    );
    expect(
      moment(at(PrayerSlot.dhuhr, const Duration(minutes: -1))),
      WorshipMoment.morning,
    );
  });

  test('nothing is suggested between Dhuhr and Asr', () {
    expect(moment(at(PrayerSlot.dhuhr, const Duration(hours: 1))), isNull);
  });

  test('evening runs from Asr until bedtime', () {
    expect(
      moment(at(PrayerSlot.asr, const Duration(minutes: 45))),
      WorshipMoment.evening,
    );
    expect(
      moment(at(PrayerSlot.isha, const Duration(minutes: 45))),
      WorshipMoment.evening,
    );
  });

  test('bedtime starts at the chosen time and lasts until Fajr', () {
    final bedtime = bedtimeFor(schedule, defaultBedtimeMinutes);
    expect(bedtime.hour, 22);
    expect(bedtime.minute, 30);
    expect(moment(bedtime), WorshipMoment.bedtime);
    expect(
      moment(at(PrayerSlot.fajr, const Duration(minutes: -10))),
      WorshipMoment.bedtime,
    );
  });

  test('an early bedtime never starts before an hour after Isha', () {
    final bedtime = bedtimeFor(schedule, 19 * 60);
    expect(bedtime, at(PrayerSlot.isha, const Duration(hours: 1)));
  });
}
