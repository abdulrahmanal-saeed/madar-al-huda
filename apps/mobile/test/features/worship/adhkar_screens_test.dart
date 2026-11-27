import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/features/adhkar/data/adhkar_catalog.dart';
import 'package:madar_al_huda/features/adhkar/data/adhkar_progress.dart';
import 'package:madar_al_huda/features/worship/application/current_worship_moment.dart';
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
    final today = DateTime.now();
    final store = await pumpMadarApp(
      tester,
      deviceLocales: const [locale],
      initialLocation: AppRoutes.adhkar,
      additionalOverrides: [
        adhkarClockProvider.overrideWith(
          (_) => Stream.value(DateTime(today.year, today.month, today.day, 9)),
        ),
      ],
    );
    await tapVisible(tester, find.text(l10n.adhkarResume));
    for (var index = 0; index < 2; index++) {
      await tapVisible(tester, find.text(l10n.adhkarMarkRead));
    }
    expect(find.text('كل سورة · ٣ مرات'), findsOneWidget);
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

  for (final (locale, prayer, target) in [
    (const Locale('ar'), 'المغرب', 'أَسْتَغْفِرُ اللَّهَ · ٣ مرات'),
    (const Locale('en'), 'Maghrib', "I seek Allah's forgiveness · 3 times"),
  ]) {
    testWidgets(
      'a published dhikr with a generic count shows its wording in ${locale.languageCode}',
      (tester) async {
        final catalog = await tester.runAsync(() async {
          final json = jsonDecode(
            await rootBundle.loadString('assets/adhkar/catalog.json'),
          ) as Map<String, Object?>;
          final adhkar = json['adhkar'] as Map<String, Object?>? ?? json;
          final daily = adhkar['daily'] as Map<String, Object?>;
          final entries = daily['entries'] as List<Object?>;
          final groups = (daily['groups'] as List<Object?>)
              .cast<Map<String, Object?>>();
          const id = 'published-istighfar';
          entries.add({
            'id': id,
            'title': {
              'ar': 'الاستغفار بعد الصلاة',
              'en': 'Seeking forgiveness after prayer',
            },
            'wording': {
              'ar': 'أَسْتَغْفِرُ اللَّهَ.',
              'en': "I seek Allah's forgiveness.",
            },
            'repeat': [
              {'unit': 'dhikr', 'count': 3},
            ],
          });
          final group = groups.singleWhere(
            (group) => group['id'] == 'after-prayer',
          );
          (group['entries'] as List<Object?>).insert(0, id);
          return AdhkarCatalog.fromJson(json);
        });
        final l10n = lookupAppLocalizations(locale);
        await pumpMadarApp(
          tester,
          deviceLocales: [locale],
          initialLocation: AppRoutes.adhkarGroup('after-prayer'),
          adhkarCatalog: catalog,
        );
        await tapVisible(tester, find.text(prayer));
        expect(find.text(target), findsOneWidget);
        for (var index = 0; index < 3; index++) {
          await tapVisible(tester, find.text(l10n.adhkarCountOnce));
        }
        expect(find.text(target), findsNothing);
      },
    );
  }

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
