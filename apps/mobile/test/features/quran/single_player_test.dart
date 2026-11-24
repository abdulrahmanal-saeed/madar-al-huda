import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:madar_al_huda/core/audio/audio_playback.dart';
import 'package:madar_al_huda/core/routing/app_routes.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';

class _Playing extends AudioPlayback {
  @override
  Playback build() => (
    track: const MediaItem(id: 'quran:2:159', title: 'Al-Baqarah'),
    pending: null,
    failedId: null,
  );
}

void main() {
  testWidgets('while another surah plays, only one player shows', (
    tester,
  ) async {
    await pumpMadarApp(
      tester,
      initialLocation: AppRoutes.quran,
      additionalOverrides: [audioPlaybackProvider.overrideWith(_Playing.new)],
    );
    expect(find.byKey(const Key('reciter-picker')), findsNothing);
    expect(find.byKey(const Key('recitation-play')), findsNothing);
  });
}
