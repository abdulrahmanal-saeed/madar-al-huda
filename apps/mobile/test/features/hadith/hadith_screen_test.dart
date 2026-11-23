import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/features/hadith/data/hadeeth_enc.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('the Hadith library displays its publisher catalogue', (
    tester,
  ) async {
    await pumpMadarApp(
      tester,
      initialLocation: AppRoutes.hadith,
      additionalOverrides: [
        hadithCategoriesProvider('en')
            .overrideWith((ref) => [(id: '1', title: 'Hadith sciences')]),
      ],
    );
    expect(find.text('Hadith sciences'), findsOneWidget);
    expect(find.text('Hadith'), findsWidgets);
  });
}
