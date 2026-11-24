import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/core/storage/key_value_store.dart';
import 'package:madar_al_huda/features/quran/data/recitation_resume.dart';
import 'package:madar_al_huda/features/quran/presentation/recitation_player.dart';
import 'package:madar_al_huda/main.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  test('the saved place round-trips and rejects bad data', () {
    const saved = (reader: '159', surah: 2, ms: 90500, ayah: 30);
    expect(decodeSavedRecitation(encodeSavedRecitation(saved)), saved);
    expect(
      decodeSavedRecitation(
        encodeSavedRecitation((reader: '159', surah: 2, ms: 10, ayah: null)),
      ),
      (reader: '159', surah: 2, ms: 10, ayah: null),
    );
    expect(decodeSavedRecitation('{"reader":"","surah":2,"ms":1}'), isNull);
    expect(decodeSavedRecitation('{"reader":"x","surah":200,"ms":1}'), isNull);
    expect(decodeSavedRecitation('not json'), isNull);
    expect(decodeSavedRecitation(null), isNull);
    expect(readerOfTrack('2:mp3quran-121'), 'mp3quran-121');
    expect(readerOfTrack('cairo-quran-radio-live'), isNull);
    expect(storageAllowList, contains(lastRecitationKey));
  });

  testWidgets('the same reciter offers to continue where it stopped', (
    tester,
  ) async {
    await pumpMadarApp(
      tester,
      deviceLocales: const [AppLocales.arabic],
      initialLocation: AppRoutes.verse(2, 1),
      store: InMemoryKeyValueStore({
        reciterPreferenceKey: '159',
        lastRecitationKey: encodeSavedRecitation((
          reader: '159',
          surah: 2,
          ms: 90500,
          ayah: 30,
        )),
      }),
    );
    await tester.pumpAndSettle();
    final l10n = lookupAppLocalizations(AppLocales.arabic);
    expect(find.byKey(const Key('recitation-resume')), findsOneWidget);
    expect(
      find.text(l10n.recitationResumeVerse('البقرة', '٣٠')),
      findsOneWidget,
    );
  });

  testWidgets('another reciter does not', (tester) async {
    await pumpMadarApp(
      tester,
      initialLocation: AppRoutes.verse(2, 1),
      store: InMemoryKeyValueStore({
        reciterPreferenceKey: '159',
        lastRecitationKey: encodeSavedRecitation((
          reader: 'mp3quran-121',
          surah: 2,
          ms: 1000,
          ayah: null,
        )),
      }),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recitation-resume')), findsNothing);
  });
}
