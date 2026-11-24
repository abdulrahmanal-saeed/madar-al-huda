import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/features/names/names_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

Map<String, Object?> feedWith(List<Map<String, Object?>> names) => {
  'library': {'names': names},
};

void main() {
  test('reads the published names and skips incomplete ones', () {
    final names = divineNamesFrom(
      feedWith([
        {
          'id': 'a',
          'number': 1,
          'title': {'ar': 'الرحمن', 'en': 'Ar-Rahman'},
          'body': {'ar': 'شرح تجريبي', 'en': 'Test meaning'},
          'evidence': {'ar': 'دليل تجريبي'},
          'source': 'https://example.com/a',
        },
        {
          'id': 'b',
          'title': {'ar': 'اسم بلا شرح', 'en': ''},
          'body': {'ar': ''},
        },
      ]),
    );
    expect(names.single.name, 'الرحمن');
    expect(names.single.meaning('en'), 'Test meaning');
    expect(names.single.evidence, 'دليل تجريبي');
    expect(names.single.source, Uri.https('example.com', '/a'));
    expect(divineNamesFrom(null), isEmpty);
  });

  testWidgets('lists the names, searches, and opens one', (tester) async {
    await pumpMadarApp(
      tester,
      deviceLocales: const [AppLocales.arabic],
      initialLocation: AppRoutes.names,
      additionalOverrides: [
        divineNamesProvider.overrideWithValue(
          AsyncValue.data(
            divineNamesFrom(
              feedWith([
                for (final (i, name) in ['الرحمن', 'الرحيم', 'الملك'].indexed)
                  {
                    'id': 'n$i',
                    'number': i + 1,
                    'title': {'ar': name, 'en': 'Name $i'},
                    'body': {'ar': 'شرح تجريبي $i'},
                  },
              ]),
            ),
          ),
        ),
      ],
    );
    expect(find.byKey(const ValueKey('name-n0')), findsOneWidget);
    expect(find.byKey(const ValueKey('name-n2')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('names-search')), 'الملك');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('name-n0')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('name-n2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('name-detail-title')), findsOneWidget);
    expect(find.text('شرح تجريبي 2'), findsOneWidget);
  });

  testWidgets('says the names are coming when none are published', (
    tester,
  ) async {
    await pumpMadarApp(tester, initialLocation: AppRoutes.names);
    expect(find.byKey(const Key('names-empty')), findsOneWidget);
  });
}
