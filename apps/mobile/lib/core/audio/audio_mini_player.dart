import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_ui/material_ui.dart';

import '../localization/l10n_extension.dart';
import 'audio_playback.dart';

class AudioMiniPlayer extends ConsumerWidget {
  const AudioMiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(audioPlaybackProvider);
    final track = playback.track;
    if (track == null) return const SizedBox.shrink();

    final controller = ref.read(audioPlaybackProvider.notifier);
    final player = ref.watch(audioPlayerProvider);
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final live = track.isLive == true;
    final busy = playback.pending != null;

    Future<void> transport(Future<void> Function() action) async {
      try {
        await action();
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                live ? l10n.radioStreamFailed : l10n.readerAudioUnavailable,
              ),
            ),
          );
        }
      }
    }

    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      initialData: player.playerState,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final playing =
            state?.playing == true &&
            state?.processingState != ProcessingState.completed;
        return Material(
          color: colors.primaryContainer,
          child: ListTile(
            dense: true,
            leading: Icon(live ? Icons.radio : Icons.headphones_outlined),
            title: Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              track.artist ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!live || !playing)
                  IconButton(
                    tooltip: playing ? l10n.readerPause : l10n.readerResume,
                    onPressed: busy
                        ? null
                        : () => transport(
                            playing ? controller.pause : controller.resume,
                          ),
                    icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                  ),
                IconButton(
                  tooltip: live ? l10n.radioStop : l10n.readerStop,
                  onPressed: busy ? null : () => transport(controller.stop),
                  icon: const Icon(Icons.stop),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
