import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/features/adhkar/data/adhkar_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dashboard-written adhkar need no hadith number', () async {
    final data = jsonDecode(
      await rootBundle.loadString('assets/adhkar/catalog.json'),
    ) as Map<String, Object?>;
    final daily = data['daily']! as Map<String, Object?>;
    (daily['entries']! as List<Object?>).add({
      'id': 'my-dua',
      'title': {'ar': 'دعاء خاص', 'en': 'My supplication'},
      'wording': {'ar': 'اللهم اغفر لي', 'en': 'O Allah, forgive me'},
      'source': {'ar': 'رواه مسلم'},
    });
    final morning = (daily['groups']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .firstWhere((group) => group['id'] == 'morning');
    (morning['entries']! as List<Object?>).add('my-dua');
    final hisn = data['hisn']! as Map<String, Object?>;
    ((hisn['topics']! as List<Object?>).first!
        as Map<String, Object?>)['entries'] = [
      {
        'id': 'own-1',
        'title': {'ar': 'دعاء الكرب', 'en': 'Distress'},
        'wording': {'ar': 'لا إله إلا الله العظيم الحليم'},
      },
    ];

    final catalog = AdhkarCatalog.fromJson(data);
    final entry = catalog.groups
        .firstWhere((group) => group.id == 'morning')
        .entries
        .last;
    expect(entry.variants.single.hadith, isNull);
    expect(entry.variants.single.key, 'own');
    expect(entry.savedKey(entry.variants.single), 'own:my-dua');
    expect(entry.wording, 'اللهم اغفر لي');
    expect(entry.meaning, 'O Allah, forgive me');
    expect(entry.source, (ar: 'رواه مسلم', en: 'رواه مسلم'));
    expect(catalog.hisnTopics.first.entries.single.title.ar, 'دعاء الكرب');
  });
}
