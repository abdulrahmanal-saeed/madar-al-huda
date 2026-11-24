import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/localization/numbers.dart';
import 'package:madar_al_huda/features/quran/presentation/verse_image.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  const verse =
      'رَبَّنَآ ءَاتِنَا فِى ٱلدُّنْيَا حَسَنَةً وَفِى ٱلْـَٔاخِرَةِ حَسَنَةً وَقِنَا عَذَابَ ٱلنَّارِ';

  Future<void> open(WidgetTester tester, Locale locale) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: AppLocales.supported,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => shareVerseImage(
              context,
              verseText: verse,
              surahName: locale.languageCode == 'ar' ? 'البقرة' : 'Al-Baqara',
              surah: 2,
              ayah: 201,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('previews the verse card with its reference', (tester) async {
    await open(tester, const Locale('ar'));
    expect(find.byKey(const ValueKey('verse-card')), findsOneWidget);
    expect(find.text(verse), findsOneWidget);
    final ayah = decimalFormat('ar').format(201);
    expect(find.text('البقرة $ayah'), findsOneWidget);
    expect(find.text('مدار الهدى'), findsOneWidget);
    expect(find.byKey(const ValueKey('verse-image-share')), findsOneWidget);
  });

  testWidgets('English uses a chapter:verse reference', (tester) async {
    await open(tester, const Locale('en'));
    expect(find.text('Al-Baqara 2:201'), findsOneWidget);
  });

  testWidgets('the card renders to an image', (tester) async {
    await open(tester, const Locale('ar'));
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('verse-card')),
            matching: find.byType(RepaintBoundary),
          )
          .first,
    );
    final image = await tester.runAsync(() => boundary.toImage());
    expect(image!.width, greaterThan(300));
    image.dispose();
  });
}
