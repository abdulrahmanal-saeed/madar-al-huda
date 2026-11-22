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
