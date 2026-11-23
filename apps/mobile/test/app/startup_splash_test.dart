import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/core/theme/app_theme.dart';
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
}
