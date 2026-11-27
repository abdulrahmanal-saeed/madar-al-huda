import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'audio_playback.dart';
import 'devotional_recording.dart';

class DevotionalAudioButton extends ConsumerWidget {
  const DevotionalAudioButton({
    required this.recording,
    required this.title,
    super.key,
  });

  final DevotionalRecording recording;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final playback = ref.watch(audioPlaybackProvider);
    final player = ref.watch(audioPlayerProvider);
    final id = recording.url.toString();
    final active = playback.track?.id == id;
    final controls = ref.read(audioPlaybackProvider.notifier);
    return StreamBuilder<bool>(
      stream: active ? player.playingStream : const Stream.empty(),
      initialData: active && player.playing,
      builder: (context, snapshot) {
        final playing = active && (snapshot.data ?? false);
        return IconButton(
          tooltip: playing
              ? (ar ? 'إيقاف مؤقت' : 'Pause')
              : (ar ? 'استمع' : 'Listen'),
          icon: Icon(
            playing ? Icons.pause_circle_outline : Icons.play_circle_outline,
          ),
          onPressed: playback.pending != null
              ? null
              : () async {
                  if (playing) {
                    await controls.pause();
                  } else if (active) {
                    await controls.resume();
                  } else {
                    await controls.start(
                      MediaItem(id: id, title: title),
                      () async => (url: recording.url, start: null),
                    );
                  }
                },
        );
      },
    );
  }
}
