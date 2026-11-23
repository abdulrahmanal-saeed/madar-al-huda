import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/storage/key_value_store.dart';
import 'package:madar_al_huda/core/storage/storage_providers.dart';
import 'package:madar_al_huda/features/qibla/presentation/qibla_screen.dart';
import 'package:madar_al_huda/features/worship/application/worship_location.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'weak headings turn the compass and calibrated headings guide alignment',
    (tester) async {
      const declination = MethodChannel('madar/geomagnetic');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      var declinationCalls = 0;
      messenger.setMockMethodCallHandler(declination, (_) async {
        declinationCalls++;
        return 5.0;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(declination, null));
      final headings = StreamController<MagneticHeading>.broadcast(sync: true);
      addTearDown(() => unawaited(headings.close()));

      const locale = Locale('en');
      final l10n = lookupAppLocalizations(locale);
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            keyValueStoreProvider.overrideWithValue(
              InMemoryKeyValueStore({
                WorshipLocationController.cityKey: 'dubai-ae',
              }),
            ),
            magneticHeadingProvider.overrideWith((_) => headings.stream),
          ],
          child: const MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: QiblaScreen(),
          ),
        ),
      );

      headings.add((degrees: 250, reliable: false));
      await tester.pump();
      await tester.pump();
      expect(find.text(l10n.compassApproximateHeading('255')), findsOneWidget);
      expect(find.text(l10n.compassCalibrate), findsOneWidget);
      expect(find.text(l10n.compassAligned), findsNothing);

      headings.add((degrees: 253, reliable: true));
      await tester.pump();
      await tester.pump();
      expect(find.text(l10n.compassPhoneHeading('258')), findsOneWidget);
      expect(find.text(l10n.compassAligned), findsOneWidget);
      expect(declinationCalls, 1);
    },
  );
}
