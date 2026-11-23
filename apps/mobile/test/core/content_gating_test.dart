import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/content/content_status.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/core/routing/app_sections.dart';
import 'package:madar_al_huda/features/quran/domain/quran_storage_contracts.dart';

/// Guards the "no unverified religious content" rule (plan/RISKS R-01, R-02).
///
/// Making a section `available` must be a deliberate, reviewed change: update
/// this allow-list in the same PR that links the DONE tracker evidence.
const Set<AppSection> approvedSections = {};

void main() {
  test('only explicitly approved sections are ungated', () {
    final ungated = AppSection.values.where((s) => !s.status.isGated).toSet();
    expect(ungated, approvedSections);
  });

  test('religious-content sections carry the right gate', () {
    expect(AppSection.mushaf.status, ContentStatus.awaitingSourceVerification);
    expect(AppSection.tafsir.status, ContentStatus.awaitingSourceVerification);
    expect(AppSection.recitations.status, ContentStatus.awaitingAudioRights);
    expect(AppSection.hadith.status, ContentStatus.awaitingSourceVerification);
    expect(AppSection.fiqh.status, ContentStatus.awaitingScholarlyReview);
    expect(AppSection.stories.status, ContentStatus.awaitingScholarlyReview);
    expect(
      AppSection.prayerTimes.status,
      ContentStatus.awaitingCalculationValidation,
    );
  });

  test(
    'section paths remain unique under the tab and legacy route prefixes',
    () {
      final paths = AppSection.values.map((s) => s.path).toList();
      expect(paths.toSet().length, paths.length);
      final prefixes = [
        ...AppRoutes.tabs,
        AppRoutes.worship,
        AppRoutes.learning,
      ];
      for (final path in paths) {
        expect(
          prefixes.any(
            (prefix) => path == prefix || path.startsWith('$prefix/'),
          ),
          isTrue,
          reason: path,
        );
      }
    },
  );

  group('AyahRef', () {
    test('accepts valid references and compares by value', () {
      final a = AyahRef(editionId: 'ed', surah: 1, ayah: 1);
      expect(a, AyahRef(editionId: 'ed', surah: 1, ayah: 1));
      expect(a, isNot(AyahRef(editionId: 'other', surah: 1, ayah: 1)));
      expect(AyahRef(editionId: 'ed', surah: surahCount, ayah: 1).surah, 114);
    });

    test('rejects out-of-range or edition-less references', () {
      expect(
        () => AyahRef(editionId: 'ed', surah: 0, ayah: 1),
        throwsRangeError,
      );
      expect(
        () => AyahRef(editionId: 'ed', surah: 115, ayah: 1),
        throwsRangeError,
      );
      expect(
        () => AyahRef(editionId: 'ed', surah: 2, ayah: 0),
        throwsRangeError,
      );
      expect(
        () => AyahRef(editionId: '', surah: 2, ayah: 1),
        throwsArgumentError,
      );
    });
  });
}
