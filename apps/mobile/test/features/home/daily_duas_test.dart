import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/features/home/data/daily_duas.dart';

void main() {
  test('bundled supplications rotate once per civil day', () {
    final start = DateTime(2026, 1, 1);
    final ids = [
      for (var i = 0; i < bundledDailyDuas.length; i++)
        dailyDuaForCivilDay(
          DateTime(start.year, start.month, start.day + i),
          bundledDailyDuas,
        ).id,
    ];
    expect(ids.toSet().length, bundledDailyDuas.length);
    expect(
      dailyDuaForCivilDay(
        DateTime(2026, 1, 1 + bundledDailyDuas.length),
        bundledDailyDuas,
      ).id,
      ids.first,
    );
  });

  test('invalid or missing managed list uses curated offline defaults', () {
    expect(decodeDailyDuas(null), bundledDailyDuas);
    expect(decodeDailyDuas([]), bundledDailyDuas);
    expect(decodeDailyDuas([{}]), bundledDailyDuas);
  });

  test('managed list replaces the bundled list', () {
    final list = decodeDailyDuas([
      {
        'id': 'knowledge',
        'wording': {'ar': 'رَبِّ زِدْنِي عِلْمًا', 'en': 'Increase my knowledge'},
        'source': {'ar': 'طه: ١١٤', 'en': 'Quran 20:114'},
      },
    ]);
    expect(list.single.id, 'knowledge');
    expect(dailyDuaForCivilDay(DateTime(2026, 11, 26), list), list.single);
  });
}
