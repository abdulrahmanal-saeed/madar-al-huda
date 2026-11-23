import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/features/quran/data/mushaf_edition.dart';
import 'package:madar_al_huda/features/quran/domain/quran_storage_contracts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the pinned Tanzil assets contain every expected surah and verse',
    () async {
      final edition = await MushafEdition.load(rootBundle);
      expect(edition.surahs.length, 114);
      expect(edition.pageStarts.length, 604);
      expect(edition.juzStarts.length, 30);
      expect(edition.hizbStarts.length, 60);
      expect([
        for (var page = 0; page < edition.pageStarts.length; page++)
          ...edition.page(page),
      ], orderedEquals(edition.verses));
      expect(edition.page(0).map((verse) => verse.ref.surah).toSet(), {1});
      expect(edition.page(1).first.ref.surah, 2);
      expect(edition.page(1).last.ref.ayah, 5);
      expect(edition.page(2).first.ref.ayah, 6);
      expect(edition.page(603).last.ref.surah, 114);
      expect(edition.page(603).last.ref.ayah, 6);
      expect(
        edition.surahs.fold(0, (sum, surah) => sum + surah.verses.length),
        6236,
      );
      expect(
        edition.contains(
          AyahRef(editionId: MushafEdition.id, surah: 2, ayah: 255),
        ),
        isTrue,
      );
      expect(
        edition.contains(
          AyahRef(editionId: MushafEdition.id, surah: 2, ayah: 287),
        ),
        isFalse,
      );
      expect(
        edition.contains(AyahRef(editionId: 'other', surah: 1, ayah: 1)),
        isFalse,
      );
    },
  );
}
