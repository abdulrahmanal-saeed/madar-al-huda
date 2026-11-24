import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/features/zakat/domain/zakat.dart';
import 'package:madar_al_huda/features/zakat/presentation/zakat_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  test('wealth above the gold nisab owes 2.5%', () {
    final result = calculateZakat(
      const ZakatInput(cash: 100000, debts: 10000, goldPrice: 1000),
    );
    expect(result.nisab, 85000);
    expect(result.wealth, 90000);
    expect(result.due, 2250);
  });

  test('gold of every karat counts as pure gold', () {
    const input = ZakatInput(gold24: 10, gold21: 24, gold18: 40);
    // 10 + 21 + 30 grams of pure gold.
    expect(input.pureGoldGrams, 61);
  });

  test('below the nisab, or without a price, nothing is due', () {
    expect(
      calculateZakat(const ZakatInput(cash: 50000, goldPrice: 1000)).due,
      0,
    );
    final noPrice = calculateZakat(const ZakatInput(cash: 1e9));
    expect(noPrice.nisab, isNull);
    expect(noPrice.due, 0);
    // The silver nisab is lower.
    final silver = calculateZakat(
      const ZakatInput(cash: 50000, silverPrice: 50, basis: NisabBasis.silver),
    );
    expect(silver.reachesNisab, isTrue);
    expect(silver.due, 1250);
  });

  test('amounts read Arabic digits and separators', () {
    expect(parseAmount('١٢٬٥٠٠٫٥'), 12500.5);
    expect(parseAmount('12,000'), 12000);
    expect(parseAmount('abc'), 0);
    expect(parseAmount('-5'), 0);
  });

  testWidgets('typing amounts shows the zakat due', (tester) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    await pumpMadarApp(tester, initialLocation: AppRoutes.zakat);
    expect(find.text(l10n.zakatNeedPrice), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('zakat-goldPrice')),
      '1000',
    );
    await tester.enterText(find.byKey(const ValueKey('zakat-cash')), '100000');
    await tester.pumpAndSettle();
    expect(find.text(l10n.zakatDue), findsOneWidget);
    expect(find.text('2,500'), findsOneWidget);
  });
}
