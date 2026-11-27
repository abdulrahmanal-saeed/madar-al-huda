import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:madar_al_huda/core/localization/app_locales.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:madar_al_huda/features/downloads/data/download_usage.dart';
import 'package:madar_al_huda/features/learning/data/learning_catalog.dart';
import 'package:madar_al_huda/features/learning/data/learning_files.dart';
import 'package:madar_al_huda/features/learning/data/prophet_stories.dart';
import 'package:madar_al_huda/features/quran/data/chapter_reciters.dart';
import 'package:madar_al_huda/features/quran/data/offline_recitations.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

/// Lets real file I/O finish between frames; widget tests run on fake time.
Future<void> _settleIo(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  test('sizes read as people say them', () {
    String fmt(int bytes, String language) =>
        formatBytes(bytes, language, (value) => '$value');
    expect(fmt(512, 'en'), '512 B');
    expect(fmt(340 * 1024 * 1024, 'en'), '340 MB');
    expect(fmt((1.25 * 1024 * 1024 * 1024).round(), 'en'), '1.3 GB');
    expect(fmt(5 * 1024 * 1024, 'ar'), '5 ميجابايت');
  });

  testWidgets('shows what is saved and removes a reciter after confirming', (
    tester,
  ) async {
    final root = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('madar-downloads'),
    ))!;
    addTearDown(() => root.delete(recursive: true));
    final reader = publishedChapterReciters.firstWhere(
      (reader) => reader.hasOfflineAudio,
    );
    final audio = File('${root.path}/recitation-audio-v1/${reader.key}_1.mp3');
    await tester.runAsync(() async {
      await audio.parent.create(recursive: true);
      await audio.writeAsBytes([73, 68, 51, 0, 0, 0, 0, 0]);
    });
    final stories = (await tester.runAsync(
      () async => parseLearningSeries(
        await rootBundle.loadString('assets/learning/prophet_stories.json'),
      ),
    ))!;
    final client = http.Client();
    addTearDown(client.close);

    await pumpMadarApp(
      tester,
      initialLocation: AppRoutes.downloads,
      additionalOverrides: [
        downloadRootProvider.overrideWithValue(() async => root),
        offlineAudioStoreProvider.overrideWithValue(
          OfflineAudioStore(
            () async => Directory('${root.path}/recitation-audio-v1'),
            client,
          ),
        ),
        learningFilesProvider.overrideWithValue(
          LearningFiles(() async => root, client),
        ),
        prophetStoriesProvider.overrideWith((_) => stories),
      ],
    );
    await _settleIo(tester);

    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(find.text(l10n.downloadsTitle), findsOneWidget);
    expect(find.byKey(const ValueKey('downloads-used')), findsNothing);
    final row = find.byKey(ValueKey('downloads-reciter-${reader.key}'));
    expect(
      find.descendant(
        of: row,
        matching: find.textContaining(RegExp(r'^1 of \d+ surahs saved$')),
      ),
      findsOneWidget,
    );
    // Library content and online-only items sit in their own tab.
    expect(find.text(l10n.downloadsOnlineOnlyBody), findsNothing);
    await tester.tap(find.text(l10n.downloadsLibraryTab));
    await tester.pumpAndSettle();
    expect(find.text(l10n.downloadsOnlineOnlyBody), findsNWidgets(2));
    await tester.tap(find.text(l10n.downloadsRecitations).first);
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(of: row, matching: find.byIcon(Icons.delete_outline)),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.downloadsRemoveConfirm(reader.name('en'))),
      findsOneWidget,
    );
    await tester.tap(find.text(l10n.downloadsConfirmRemove));
    await _settleIo(tester);

    expect(await tester.runAsync(audio.exists), isFalse);
  });
}
