import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/features/quran/data/mushaf_edition.dart';
import 'package:madar_al_huda/features/quran/presentation/mushaf_screen.dart';
import 'package:madar_al_huda/features/worship/data/daily_reading_plan.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets(
      '${locale.languageCode}: changing the daily goal preserves saved progress',
      (tester) async {
        final l10n = lookupAppLocalizations(locale);
        final numbers = NumberFormat.decimalPattern(locale.languageCode);
        final card = find.text(l10n.dailyReadingTitle).hitTestable();
        final store = await pumpMadarApp(
          tester,
          deviceLocales: [locale],
          initialLocation: AppRoutes.worship,
        );
        await tester.scrollUntilVisible(card, 100);
        await tester.pumpAndSettle();
        await tester.tap(card);
        await tester.pumpAndSettle();

        await tester.tap(find.text(l10n.dailyReadingMarkRead));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, numbers.format(20)));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField), numbers.format(7));
        await tester.tap(find.text(l10n.dailyReadingSave));
        await tester.pumpAndSettle();
        expect(
          store.getString(DailyReadingPlanController.key),
          '${MushafEdition.id}|7|20',
        );

        await pumpMadarApp(
          tester,
          deviceLocales: [locale],
          initialLocation: AppRoutes.worship,
          store: store,
        );
        await tester.scrollUntilVisible(card, 100);
        await tester.pumpAndSettle();
        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(
          find.text(
            l10n.dailyReadingRange(numbers.format(21), numbers.format(27)),
          ),
          findsOneWidget,
        );
        await tester.tap(
          find.text(l10n.dailyReadingNextPage(numbers.format(21))),
        );
        await tester.pumpAndSettle();
        expect(find.byType(MushafScreen), findsOneWidget);
      },
    );
  }

  test('the final session is capped at the last page', () {
    const plan = (pagesPerSession: 20, pagesRead: 600);
    expect(plan.endPage(604), 604);
    expect(plan.remainingSessions(604), 1);
  });
}
