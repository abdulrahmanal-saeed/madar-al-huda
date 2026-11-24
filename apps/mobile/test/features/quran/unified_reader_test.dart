import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/localization/numbers.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/core/storage/key_value_store.dart';
import 'package:madar_al_huda/features/quran/data/mushaf_edition.dart';
import 'package:madar_al_huda/features/quran/data/quran_services.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('Arabic page input reaches the last page without network', (
    tester,
  ) async {
    const locale = Locale('ar');
    final l10n = lookupAppLocalizations(locale);
    await pumpMadarApp(
      tester,
      deviceLocales: const [locale],
      initialLocation: AppRoutes.quran,
    );
    await tester.tap(find.byTooltip(l10n.readerIndex));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, l10n.readerPages));
    await tester.pumpAndSettle();
    final number = find.widgetWithText(TextField, l10n.readerPageInput);
    await tester.enterText(number, '٦٠٥');
    await tester.tap(find.widgetWithText(FilledButton, l10n.readerGo));
    await tester.pumpAndSettle();
    expect(find.text(l10n.readerPageInvalid), findsOneWidget);
    await tester.enterText(number, '٦٠٤');
    await tester.tap(find.widgetWithText(FilledButton, l10n.readerGo));
    await tester.pumpAndSettle();
    final lastPage = decimalFormat('ar').format(604);
    expect(find.textContaining(l10n.readerPageLabel(lastPage)), findsWidgets);
    expect(tester.takeException(), isNull);
  });

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
        // Source names live on the licences page only.
        expect(find.text('Quran Foundation'), findsNothing);
        final edition = await tester.runAsync(
          () => MushafEdition.load(rootBundle),
        );
        final text = edition!.surahs[1].verses[254];
        final verse = find.byWidgetPredicate(
          (widget) =>
              widget is RichText && widget.text.toPlainText().contains(text),
        );
        expect(verse.hitTestable(), findsOneWidget);
        final paragraph = tester.renderObject<RenderParagraph>(verse);
        final start = paragraph.text.toPlainText().indexOf(text);
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: start, extentOffset: start + text.length),
        );
        await tester.longPressAt(
          paragraph.localToGlobal(boxes.first.toRect().center),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining(
            l10n.readerTafsirFor(
              decimalFormat(locale.languageCode).format(255),
            ),
          ),
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
        await tester.tap(find.byTooltip(l10n.readerAddBookmark));
        await tester.pumpAndSettle();
        expect(find.byTooltip(l10n.readerRemoveBookmark), findsOneWidget);
        final context = tester.element(find.text('Tafsir fixture'));
        Navigator.of(context).pop();
        await tester.pumpAndSettle();
        expect(find.text('Tafsir fixture'), findsNothing);
        expect(verse.hitTestable(), findsOneWidget);
      },
    );
  }
}
