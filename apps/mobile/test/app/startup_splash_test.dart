import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/core/storage/key_value_store.dart';
import 'package:madar_al_huda/core/theme/app_theme.dart';
import 'package:madar_al_huda/features/qibla/domain/qibla_bearing.dart';
import 'package:madar_al_huda/features/worship/application/worship_location.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

void main() {
  for (final locale in AppLocales.supported) {
    testWidgets(
      '${locale.languageCode}: splash uses the wordmark and dedication fonts',
      (tester) async {
        final arabic = lookupAppLocalizations(AppLocales.arabic);
        final english = lookupAppLocalizations(AppLocales.english);
        await pumpMadarApp(
          tester,
          deviceLocales: [locale],
          initialLocation: AppRoutes.prayerTimes,
          showStartupSplash: true,
          store: InMemoryKeyValueStore({
            WorshipLocationController.deviceLocationKey: false,
          }),
        );

        final logo = find.text(english.appTitle.toUpperCase());
        final dedication = find.text(arabic.appDedication);
        expect(
          tester.widget<Text>(logo).style?.fontFamily,
          AppTheme.headingFontFamily,
        );
        expect(
          tester.widget<Text>(dedication).style?.fontFamily,
          AppTheme.readingFontFamily,
        );
        expect(
          find.text(english.appDedication),
          locale == AppLocales.english ? findsOneWidget : findsNothing,
        );

        if (locale == AppLocales.arabic) {
          await tester.tap(logo);
        } else {
          await tester.pump(const Duration(seconds: 2));
        }
        await tester.pumpAndSettle();
        expect(dedication, findsNothing);
        final l10n = lookupAppLocalizations(locale);
        expect(
          find.text(l10n.sectionPrayerTimesTitle).hitTestable(),
          findsWidgets,
        );
      },
    );
  }

  testWidgets('startup offers location and shares it with Prayer and Qibla', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const locale = Locale('en');
    final l10n = lookupAppLocalizations(locale);
    final requests = <bool>[];
    final boundaries = (await tester.runAsync(() async {
      return CountryBoundaries(
        jsonDecode(
          await rootBundle.loadString('assets/location/countries.json'),
        ) as Map<String, dynamic>,
      );
    }))!;
    final store = await pumpMadarApp(
      tester,
      deviceLocales: const [locale],
      initialLocation: AppRoutes.prayerTimes,
      showStartupSplash: true,
      additionalOverrides: [
        readDeviceLocationProvider.overrideWithValue(({
          required requestPermission,
        }) async {
          requests.add(requestPermission);
          if (!requestPermission) throw LocationProblem.denied;
          return ManualCity.cairo.center;
        }),
        countryBoundariesProvider.overrideWith((_) => boundaries),
      ],
    );

    expect(requests, isEmpty);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text(l10n.startupLocationTitle), findsOneWidget);
    expect(requests, [false]);

    await tester.tap(find.widgetWithText(FilledButton, l10n.useLocation));
    await tester.pumpAndSettle();
    expect(requests, [false, true]);
    expect(find.text(l10n.deviceLocation), findsWidgets);
    expect(store.values, {
      WorshipLocationController.deviceLocationKey: true,
      // The located position is kept, rounded, for the next launch.
      WorshipLocationController.lastDevicePointKey: isA<String>(),
    });

    await tester.tap(find.widgetWithText(TextButton, l10n.sectionQiblaTitle));
    await tester.pumpAndSettle();
    expect(find.text(l10n.trueBearing('136')), findsOneWidget);
    expect(find.text(l10n.deviceLocation), findsWidgets);
    debugDefaultTargetPlatformOverride = null;
  });
}
