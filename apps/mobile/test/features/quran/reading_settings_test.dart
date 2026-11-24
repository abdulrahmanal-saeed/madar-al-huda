import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/app/app_shell.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/features/quran/application/reading_preferences.dart';
import 'package:madar_al_huda/features/quran/presentation/mushaf_page_view.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('text size and page background apply and are remembered', (
    tester,
  ) async {
    final store = await pumpMadarApp(tester, initialLocation: AppRoutes.quran);
    final l10n = lookupAppLocalizations(const Locale('en'));
    MushafPageView page() =>
        tester.widget<MushafPageView>(find.byType(MushafPageView).first);
    expect(page().preferences.fontSize, defaultReadingFontSize);

    await tester.tap(find.byKey(const ValueKey('reader-appearance')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.readerLarger));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.readerPaperWarm));
    await tester.pumpAndSettle();

    expect(page().preferences.fontSize, defaultReadingFontSize + 2);
    expect(page().preferences.paper, ReadingPaper.warm);
    final saved = jsonDecode(
      store.getString(ReadingPreferencesController.key)!,
    ) as Map<String, Object?>;
    expect(saved, {'fontSize': defaultReadingFontSize + 2, 'paper': 'warm'});
  });

  testWidgets('full screen hides the bars and the tab bar until exited', (
    tester,
  ) async {
    await pumpMadarApp(tester, initialLocation: AppRoutes.quran);
    expect(find.byKey(AppShell.navigationBarKey), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reader-fullscreen')));
    await tester.pumpAndSettle();
    expect(find.byKey(AppShell.navigationBarKey), findsNothing);
    expect(find.byKey(const ValueKey('reader-appearance')), findsNothing);
    expect(find.byType(MushafPageView), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('reader-exit-fullscreen')));
    await tester.pumpAndSettle();
    expect(find.byKey(AppShell.navigationBarKey), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-appearance')), findsOneWidget);
  });

  test('every page background keeps the verses readable', () {
    final theme = ThemeData.light();
    for (final paper in ReadingPaper.values) {
      final colors = paperColors(paper, theme);
      final ratio =
          (colors.ink.computeLuminance() + 0.05) /
          (colors.paper.computeLuminance() + 0.05);
      expect(ratio > 1 ? ratio : 1 / ratio, greaterThan(7), reason: paper.name);
    }
  });
}
