import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/features/adhkar/presentation/dhikr_content.dart';

void main() {
  test('Quran ranges keep their real ayah numbers including the last', () {
    expect(
      numberedQuranRange(['first', 'second', 'third'], first: 2, last: 3),
      'second ۝٢ third ۝٣',
    );
    final verses = List.generate(200, (index) => 'v${index + 1}');
    final result = numberedQuranRange(verses, first: 190, last: 200);
    expect(result, startsWith('v190 ۝١٩٠'));
    expect(result, endsWith('v200 ۝٢٠٠'));
    expect('۝'.allMatches(result).length, 11);
  });
}
