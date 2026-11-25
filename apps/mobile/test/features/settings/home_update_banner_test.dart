import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/features/settings/presentation/settings_updates.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  const release = {
    'version': 1,
    'release': {
      'code': 68,
      'name': '0.1.0-dev.68',
      'notes': {'ar': '', 'en': ''},
    },
  };

  test('only a newer published version is available', () {
    expect(PublishedAppUpdate.parse(release, 67)?.code, 68);
    expect(PublishedAppUpdate.parse(release, 68), isNull);
    expect(PublishedAppUpdate.parse(release, 69), isNull);
    expect(
      PublishedAppUpdate.parse({'version': 1, 'release': null}, 67),
      isNull,
    );
  });

  testWidgets('home banner appears only for an available update', (
    tester,
  ) async {
    Future<void> pump(AppUpdateStatus? status) async {
      final key = UniqueKey();
      final banner = HomeUpdateBanner(key: key, check: () async => status);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: banner)));
      await tester.pumpAndSettle();
    }

    final update = PublishedAppUpdate.parse(release, 67);
    await pump(AppUpdateStatus('dev', false, update, false));
    expect(find.text('New update available'), findsOneWidget);
    expect(find.text('0.1.0-dev.68'), findsOneWidget);
    expect(find.text('Update now'), findsOneWidget);

    await pump(const AppUpdateStatus('dev', false, null, false));
    expect(find.text('New update available'), findsNothing);

    await pump(const AppUpdateStatus('dev', false, null, true));
    expect(find.text('New update available'), findsNothing);

    await pump(null);
    expect(find.text('New update available'), findsNothing);
  });
}
