import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/features/fiqh/data/fiqh_catalog.dart';

Map<String, Object?> bilingual(String ar, String en) => {'ar': ar, 'en': en};

Map<String, Object?> fixture() => {
  'schemaVersion': 1,
  'kind': 'published_fiqh',
  'disclaimer': bilingual('بيانات اختبار فقط', 'Synthetic data only'),
  'categories': [
    {'id': 'test', 'title': bilingual('اختبار', 'Test')},
  ],
  'issues': [
    {
      'id': 'synthetic',
      'number': 'FIQH-999',
      'categoryId': 'test',
      'revision': 1,
      'status': 'published',
      'title': bilingual('إِخْتِبَار', 'Synthetic example'),
      'positions': {
        for (final school in fiqhSchools)
          school: {'ruling': bilingual('اختبار فقط', 'Test only')},
      },
    },
  ],
};

void main() {
  test('published feed accepts only supported shape and searches both languages', () {
    final catalog = FiqhCatalog.decode(fixture());
    expect(catalog.search('اختبار'), hasLength(1));
    expect(catalog.search('EXAMPLE'), hasLength(1));
    expect(catalog.search('FIQH-999'), hasLength(1));
    expect(catalog.search('', category: 'missing'), isEmpty);
  });

  test('rejects draft rows and incomplete school sets', () {
    final feed = fixture();
    final issue = (feed['issues'] as List).first as Map<String, Object?>;
    issue['status'] = 'draft';
    expect(() => FiqhCatalog.decode(feed), throwsFormatException);
    issue['status'] = 'published';
    issue['positions'] = <String, Object?>{};
    expect(() => FiqhCatalog.decode(feed), throwsFormatException);
  });

  test('valid empty feed is distinct from absent or invalid feed', () {
    final feed = fixture()..['issues'] = <Object?>[];
    expect(FiqhCatalog.decode(feed).issues, isEmpty);
    expect(() => FiqhCatalog.decode(null), throwsFormatException);
    expect(
      () => FiqhCatalog.decode({'schemaVersion': 1, 'issues': []}),
      throwsFormatException,
    );
  });
}
