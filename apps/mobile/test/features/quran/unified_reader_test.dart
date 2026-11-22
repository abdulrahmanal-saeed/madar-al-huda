import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/core/storage/key_value_store.dart';
import 'package:madar_al_huda/features/quran/data/mushaf_edition.dart';
import 'package:madar_al_huda/features/quran/data/quran_services.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets(
      '${locale.languageCode}: long-press opens the selected verse and keeps its position',
      (tester) async {
        final store = InMemoryKeyValueStore({
          LocalReadingPosition.key: jsonEncode([
            MushafEdition.id,
            2,
            255,
            '2026-11-22T00:00:00Z',
          ]),
        });
        final requested = <Uri>[];
        final client = MockClient((request) async {
          requested.add(request.url);
          if (request.url.path.endsWith('/catalog')) {
            return http.Response(
              jsonEncode({
                'chapters': [
                  {'id': 2, 'verses': 286},
                ],
                'tafsirs': [
                  {'id': 15, 'name': 'Source', 'language': 'english'},
                ],
                'reciters': [],
              }),
              200,
            );
          }
          expect(request.url.queryParameters, {
            'surah': '2',
            'ayah': '255',
            'resource': '15',
          });
          return http.Response(
            jsonEncode({
              'verse': '2:255',
              'resource': 15,
              'text': 'Tafsir fixture',
            }),
            200,
          );
        });
        addTearDown(client.close);
        await pumpMadarApp(
          tester,
          initialLocation: AppRoutes.tafsir,
          deviceLocales: [locale],
          store: store,
          quranApi: QuranApi(
            client,
            'https://test.invalid/quran',
            'public-test-key',
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        final l10n = lookupAppLocalizations(locale);
        expect(
          find.text(l10n.readerQuranFoundation),
          findsOneWidget,
          reason: '$requested',
        );
        final verse = find.byKey(const ValueKey('ayah-2-255'));
        expect(verse.hitTestable(), findsOneWidget);
        await tester.longPressAt(
          tester.getTopLeft(verse) + const Offset(170, 36),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(l10n.readerTafsirFor(255)),
          findsOneWidget,
          reason: '$requested',
        );
        expect(
          find.text('Tafsir fixture'),
          findsOneWidget,
          reason: '$requested',
        );
        expect(
          tester.widget<Text>(find.text('Tafsir fixture')).textDirection,
          TextDirection.ltr,
        );
        final context = tester.element(find.text('Tafsir fixture'));
        Navigator.of(context).pop();
        await tester.pumpAndSettle();
        expect(find.text('Tafsir fixture'), findsNothing);
        expect(verse.hitTestable(), findsOneWidget);
      },
    );
  }
}
