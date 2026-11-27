import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/app/first_run.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/core/storage/key_value_store.dart';
import 'package:madar_al_huda/features/qibla/domain/qibla_bearing.dart';
import 'package:madar_al_huda/features/worship/application/worship_location.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/pump_app.dart';

void main() {
  for (final locale in AppLocales.supported) {
    testWidgets('${locale.languageCode}: splash uses the approved artwork', (
      tester,
    ) async {
      await pumpMadarApp(
        tester,
        deviceLocales: [locale],
        initialLocation: AppRoutes.prayerTimes,
        showStartupSplash: true,
        store: InMemoryKeyValueStore({
          WorshipLocationController.deviceLocationKey: false,
          firstRunDoneKey: true,
        }),
      );

      final logo = find.byKey(const ValueKey('approved-startup-splash'));
      final image = tester.widget<Image>(logo);
      expect(
        (image.image as AssetImage).assetName,
        startsWith('assets/brand/'),
      );
      if (locale == AppLocales.arabic) {
        await tester.tap(logo);
      } else {
        await tester.pump(const Duration(seconds: 2));
      }
      await tester.pumpAndSettle();
      expect(logo, findsNothing);
      final l10n = lookupAppLocalizations(locale);
      expect(
        find.text(l10n.sectionPrayerTimesTitle).hitTestable(),
        findsWidgets,
      );
    });
  }

  testWidgets('startup offers location and shares it with Prayer and Qibla', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const locale = Locale('en');
    final l10n = lookupAppLocalizations(locale);
    final requests = <bool>[];
    final store = await pumpMadarApp(
      tester,
      deviceLocales: const [locale],
      initialLocation: AppRoutes.prayerTimes,
      showStartupSplash: true,
      store: InMemoryKeyValueStore({firstRunDoneKey: true}),
      additionalOverrides: [
        readDeviceLocationProvider.overrideWithValue(({
          required requestPermission,
        }) async {
          requests.add(requestPermission);
          if (!requestPermission) throw LocationProblem.denied;
          return ManualCity.cairo.center;
        }),
      ],
    );

    expect(requests, isEmpty);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text(l10n.startupLocationTitle), findsOneWidget);
    expect(requests, [false]);

    // The startup prompt sits above the empty location card.
    await tester.tap(find.widgetWithText(FilledButton, l10n.useLocation).last);
    await tester.pumpAndSettle();
    expect(requests, [false, true]);
    expect(
      find.text('Cairo, Egypt · ${l10n.locationFromDevice}'),
      findsOneWidget,
    );
    expect(store.values, {
      firstRunDoneKey: true,
      WorshipLocationController.deviceLocationKey: true,
      // The located position is kept, rounded, for the next launch.
      WorshipLocationController.lastDevicePointKey: isA<String>(),
    });

    await tester.tap(find.byTooltip(l10n.sectionQiblaTitle));
    await tester.pumpAndSettle();
    expect(find.text(l10n.trueBearing('136')), findsOneWidget);
    expect(
      find.text('Cairo, Egypt · ${l10n.locationFromDevice}'),
      findsOneWidget,
    );
    debugDefaultTargetPlatformOverride = null;
  });
}
