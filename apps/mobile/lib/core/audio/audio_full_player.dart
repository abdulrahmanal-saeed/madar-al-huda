import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_ui/material_ui.dart';

import '../localization/l10n_extension.dart';
import '../localization/numbers.dart';
import '../theme/app_tokens.dart';
import 'audio_playback.dart';

/// Minutes left on the sleep timer's choices; null turns it off.
const sleepTimerChoices = <int?>[null, 15, 30, 60];
const playbackSpeeds = [0.75, 1.0, 1.25, 1.5];

typedef SleepTimerState = ({DateTime at, int minutes});

/// Pauses playback when it runs out.
final sleepTimerProvider = NotifierProvider<SleepTimer, SleepTimerState?>(
  SleepTimer.new,
);

class SleepTimer extends Notifier<SleepTimerState?> {
  Timer? _timer;

  @override
  SleepTimerState? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  void set(int? minutes) {
    _timer?.cancel();
    _timer = null;
    if (minutes == null) {
      state = null;
      return;
    }
    final duration = Duration(minutes: minutes);
    state = (at: DateTime.now().add(duration), minutes: minutes);
    _timer = Timer(duration, () {
      state = null;
      unawaited(ref.read(audioPlaybackProvider.notifier).pause());
    });
  }
}

String _clock(Duration value, String Function(num) number) {
  final minutes = value.inMinutes;
  final seconds = value.inSeconds % 60;
  return '${number(minutes)}:${number(seconds).padLeft(2, number(0))}';
}

Future<void> showFullPlayer(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => const AudioFullPlayer(),
);

/// Seek bar, speed and sleep timer for the current recording.
class AudioFullPlayer extends ConsumerWidget {
  const AudioFullPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(audioPlaybackProvider);
    final track = playback.track;
    final player = ref.watch(audioPlayerProvider);
    final controller = ref.read(audioPlaybackProvider.notifier);
    final sleep = ref.watch(sleepTimerProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final number = decimalFormat(language).format;
    if (track == null) return const SizedBox.shrink();
    final live = track.isLive == true;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              track.title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (track.artist case final artist?)
              Text(
                artist,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: AppSpacing.lg),
            if (!live)
              StreamBuilder<Duration>(
                stream: player.positionStream,
                initialData: player.position,
                builder: (context, snapshot) {
                  final total = player.duration ?? Duration.zero;
                  final position = snapshot.data ?? Duration.zero;
                  final max = total.inMilliseconds.toDouble();
                  return Column(
                    children: [
                      Slider(
                        key: const ValueKey('player-seek'),
                        max: max <= 0 ? 1 : max,
                        value: max <= 0
                            ? 0
                            : position.inMilliseconds.clamp(0, max).toDouble(),
                        onChanged: max <= 0
                            ? null
                            : (value) => player.seek(
                                Duration(milliseconds: value.round()),
                              ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_clock(position, number)),
                          Text(_clock(total, number)),
                        ],
                      ),
                    ],
                  );
                },
              ),
            StreamBuilder<PlayerState>(
              stream: player.playerStateStream,
              initialData: player.playerState,
              builder: (context, snapshot) {
                final playing = snapshot.data?.playing == true;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!live)
                      IconButton(
                        tooltip: l10n.playerBack,
                        iconSize: 32,
                        onPressed: () => player.seek(
                          player.position - const Duration(seconds: 10),
                        ),
                        icon: const Icon(Icons.replay_10),
                      ),
                    const SizedBox(width: AppSpacing.md),
                    IconButton.filled(
                      tooltip: playing ? l10n.readerPause : l10n.readerResume,
                      iconSize: 40,
                      onPressed: playing ? controller.pause : controller.resume,
                      icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    if (!live)
                      IconButton(
                        tooltip: l10n.playerForward,
                        iconSize: 32,
                        onPressed: () => player.seek(
                          player.position + const Duration(seconds: 10),
                        ),
                        icon: const Icon(Icons.forward_10),
                      ),
                  ],
                );
              },
            ),
            if (!live) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.playerSpeed, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              StreamBuilder<double>(
                stream: player.speedStream,
                initialData: player.speed,
                builder: (context, snapshot) => SegmentedButton<double>(
                  key: const ValueKey('player-speed'),
                  showSelectedIcon: false,
                  segments: [
                    for (final speed in playbackSpeeds)
                      ButtonSegment(
                        value: speed,
                        label: Text('${number(speed)}×'),
                      ),
                  ],
                  selected: {
                    playbackSpeeds.contains(snapshot.data)
                        ? snapshot.data!
                        : 1.0,
                  },
                  onSelectionChanged: (choice) => player.setSpeed(choice.first),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.playerSleep, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<int?>(
              key: const ValueKey('player-sleep'),
              showSelectedIcon: false,
              segments: [
                for (final minutes in sleepTimerChoices)
                  ButtonSegment(
                    value: minutes,
                    label: Text(
                      minutes == null
                          ? l10n.playerSleepOff
                          : l10n.playerSleepMinutes(number(minutes)),
                    ),
                  ),
              ],
              selected: {sleep?.minutes},
              onSelectionChanged: (choice) =>
                  ref.read(sleepTimerProvider.notifier).set(choice.first),
            ),
            if (sleep != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.playerSleepUntil(
                  TimeOfDay.fromDateTime(sleep.at).format(context),
                ),
                key: const ValueKey('player-sleep-until'),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
