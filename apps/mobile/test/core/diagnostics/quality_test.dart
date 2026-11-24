import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/diagnostics/error_log.dart';
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

void main() {
  test('errors are kept on the phone, newest 40, without full paths', () async {
    final folder = await Directory.systemTemp.createTemp('errors');
    addTearDown(() => folder.delete(recursive: true));
    final log = ErrorLog(() async => folder);
    for (var i = 0; i < 45; i++) {
      await log.record(
        StateError('failure $i'),
        StackTrace.fromString(
          '#0 main (file:///home/someone/app/lib/main.dart:10:3)',
        ),
      );
    }
    final entries = await log.entries();
    expect(entries, hasLength(ErrorLog.keep));
    expect(entries.last['message'], contains('failure 44'));
    expect(entries.first['message'], contains('failure 5'));
    expect((entries.last['stack']! as List).single, contains('lib/main.dart'));
    expect(
      (entries.last['stack']! as List).single,
      isNot(contains('/home/someone')),
    );
    await log.clear();
    expect(await log.entries(), isEmpty);
  });

  testWidgets('the offline banner shows only without a network', (
    tester,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    await pumpMadarApp(tester, initialLocation: AppRoutes.home);
    expect(find.text(l10n.offlineBanner), findsNothing);
    await pumpMadarApp(tester, initialLocation: AppRoutes.home, offline: true);
    expect(find.text(l10n.offlineBanner), findsOneWidget);
  });
}
