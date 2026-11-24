import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/core/audio/audio_full_player.dart';
import 'package:madar_al_huda/core/audio/audio_playback.dart';

class _CountingPlayback extends AudioPlayback {
  int pauses = 0;

  @override
  Future<void> pause() async => pauses++;
}

void main() {
  testWidgets('the sleep timer pauses playback once it runs out', (
    tester,
  ) async {
    final playback = _CountingPlayback();
    final container = ProviderContainer(
      overrides: [audioPlaybackProvider.overrideWith(() => playback)],
    );
    addTearDown(container.dispose);

    container.read(sleepTimerProvider.notifier).set(15);
    expect(container.read(sleepTimerProvider)?.minutes, 15);

    await tester.pump(const Duration(minutes: 14));
    expect(playback.pauses, 0);
    await tester.pump(const Duration(minutes: 1, seconds: 1));
    expect(playback.pauses, 1);
    expect(container.read(sleepTimerProvider), isNull);
  });

  testWidgets('turning the timer off cancels it', (tester) async {
    final playback = _CountingPlayback();
    final container = ProviderContainer(
      overrides: [audioPlaybackProvider.overrideWith(() => playback)],
    );
    addTearDown(container.dispose);

    final timer = container.read(sleepTimerProvider.notifier)..set(15);
    timer.set(null);
    await tester.pump(const Duration(minutes: 20));
    expect(playback.pauses, 0);
    expect(container.read(sleepTimerProvider), isNull);
  });
}
