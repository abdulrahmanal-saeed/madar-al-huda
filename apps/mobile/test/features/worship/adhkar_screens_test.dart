import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/features/adhkar/data/adhkar_progress.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

Future<void> tapVisible(WidgetTester tester, Finder target) async {
  if (target.hitTestable().evaluate().isEmpty) {
    await tester.scrollUntilVisible(target.hitTestable(), 135);
    await tester.pumpAndSettle();
  }
  await tester.tap(target.hitTestable().first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Arabic reader saves a sourced repeat and resumes it', (
    tester,
  ) async {
    const locale = Locale('ar');
    final l10n = lookupAppLocalizations(locale);
    final store = await pumpMadarApp(
      tester,
      deviceLocales: const [locale],
      initialLocation: AppRoutes.adhkar,
    );
    await tapVisible(tester, find.text(l10n.adhkarResume));
    for (var index = 0; index < 2; index++) {
      await tapVisible(tester, find.text(l10n.adhkarMarkRead));
    }
    await tapVisible(tester, find.text(l10n.adhkarThreeSurahCycle));
    expect(
      store.getString(AdhkarProgressController.key),
      contains('three-surahs-morning-evening/6082'),
    );
    await tester.tap(find.byType(BackButton).hitTestable());
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text(l10n.adhkarResume));
    expect(find.text('الإخلاص والمعوذتان صباحًا ومساءً'), findsOneWidget);
    await tapVisible(tester, find.text(l10n.adhkarThreeSurahCycle));
    await tapVisible(tester, find.text(l10n.adhkarThreeSurahCycle));
    expect(find.text('الإخلاص والمعوذتان صباحًا ومساءً'), findsNothing);
    final saved = jsonDecode(
      store.getString(AdhkarProgressController.key)!,
    ) as Map<String, Object?>;
    final counts = saved['counts'] as Map<String, Object?>;
    expect(
      counts.entries
          .singleWhere(
            (entry) => entry.key.endsWith('/three-surahs-morning-evening/6082'),
          )
          .value,
      3,
    );
  });

  testWidgets('English routine, Hisn search, merits and Quranic duas open', (
    tester,
  ) async {
    const locale = Locale('en');
    final l10n = lookupAppLocalizations(locale);
    final store = await pumpMadarApp(
      tester,
      deviceLocales: const [locale],
      initialLocation: AppRoutes.adhkar,
    );
    await tapVisible(tester, find.text('Remembrance routine'));
    await tester.tap(
      find.widgetWithText(SwitchListTile, 'Morning remembrance'),
    );
    await tester.pumpAndSettle();
    expect(
      store.getString(AdhkarProgressController.key),
      contains('"groups":["morning"]'),
    );
    await tester.tap(find.byType(BackButton).hitTestable());
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Fortress of the Muslim'));
    await tester.enterText(find.byType(TextField), 'rain');
    await tester.pumpAndSettle();
    expect(find.text('Weather and natural events'), findsOneWidget);
    expect(find.text('When rain falls'), findsOneWidget);
    await tester.tap(find.byType(BackButton).hitTestable());
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Merits of remembrance'));
    await tapVisible(tester, find.text('Glorification and praise'));
    await tapVisible(tester, find.text(l10n.adhkarAddToWird));
    expect(
      store.getString(AdhkarProgressController.key),
      contains('"merits":["beloved-words"]'),
    );
    await tester.tap(find.byType(BackButton).hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton).hitTestable());
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Quranic supplications'));
    expect(find.byType(ChoiceChip), findsWidgets);
    expect(find.byTooltip(l10n.duaShowSaved), findsOneWidget);
  });
}
