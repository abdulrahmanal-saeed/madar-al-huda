import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/features/quran/presentation/mushaf_page_view.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('tablets read a two-page spread, earlier page on the right', (
    tester,
  ) async {
    await pumpMadarApp(
      tester,
      size: const Size(1280, 900),
      initialLocation: AppRoutes.verse(2, 255),
    );
    await tester.pumpAndSettle();
    final spread = find.byKey(const ValueKey('mushaf-spread-20'));
    expect(spread, findsOneWidget);
    final pages = tester
        .widgetList<MushafPageView>(
          find.descendant(of: spread, matching: find.byType(MushafPageView)),
        )
        .map((page) => page.index)
        .toList();
    expect(pages, [40, 41]);
    final right = tester.getCenter(
      find.byWidgetPredicate((w) => w is MushafPageView && w.index == 40),
    );
    final left = tester.getCenter(
      find.byWidgetPredicate((w) => w is MushafPageView && w.index == 41),
    );
    expect(right.dx, greaterThan(left.dx));
  });

  testWidgets('phones keep one page per row', (tester) async {
    await pumpMadarApp(tester, initialLocation: AppRoutes.verse(2, 255));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mushaf-spread-20')), findsNothing);
    expect(find.byType(MushafPageView), findsWidgets);
  });
}
