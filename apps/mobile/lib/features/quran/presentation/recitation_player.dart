import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/mushaf_edition.dart';
import '../data/quran_services.dart';
import '../domain/quran_storage_contracts.dart';

typedef _Track = ({int surah, int resource, String title, String reciter});

final _playerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  final errors = player.errorStream.listen((_) => unawaited(player.pause()));
  ref.onDispose(() {
    unawaited(errors.cancel());
    unawaited(player.dispose());
  });
  return player;
});

final _playbackProvider =
    NotifierProvider<_RecitationController, ({_Track? track, bool loading})>(
      _RecitationController.new,
    );

final pauseQuranRecitationProvider = Provider<Future<void> Function()>(
  (ref) => ref.read(_playbackProvider.notifier).pause,
);

class _RecitationController extends Notifier<({_Track? track, bool loading})> {
  int _request = 0;

  @override
  ({_Track? track, bool loading}) build() => (track: null, loading: false);

  Future<void> start(
    MushafSurah surah,
    QuranResource reciter,
    String language, {
    AyahRef? verse,
  }) async {
    if (state.loading) return;
    final request = ++_request;
    state = (track: state.track, loading: true);
    try {
      final api = ref.read(quranApiProvider);
      final recording = verse == null
          ? (url: await api.audio(surah.id, reciter.id), start: Duration.zero)
          : await api.audioAtVerse(verse, reciter.id);
      if (request != _request || !ref.mounted) return;
      final player = ref.read(_playerProvider);
      await player.pause();
      if (request != _request || !ref.mounted) return;
      state = (track: null, loading: true);
      final track = (
        surah: surah.id,
        resource: reciter.id,
        title: surah.name(language),
        reciter: reciter.name,
      );
      await player.setAudioSource(
        AudioSource.uri(
          recording.url,
          tag: MediaItem(
            id: '${track.surah}:${track.resource}',
            title: track.title,
            artist: track.reciter,
            album: 'Quran Foundation',
          ),
        ),
        initialPosition: recording.start,
      );
      if (request != _request || !ref.mounted) return;
      state = (track: track, loading: false);
      unawaited(player.play().catchError((Object _) {}));
    } finally {
      if (ref.mounted && request == _request) {
        state = (track: state.track, loading: false);
      }
    }
  }

  Future<void> pause() async {
    ++_request;
    try {
      if (state.track != null) await ref.read(_playerProvider).pause();
    } finally {
      if (ref.mounted) state = (track: state.track, loading: false);
    }
  }

  Future<void> stop() async {
    ++_request;
    await ref.read(_playerProvider).stop();
    if (ref.mounted) state = (track: null, loading: false);
  }
}

const reciterPreferenceKey = 'quran.reciter.v1';

QuranResource? selectedReciter(WidgetRef ref, List<QuranResource> reciters) {
  final id = int.tryParse(
    ref.read(keyValueStoreProvider).getString(reciterPreferenceKey) ?? '',
  );
  return reciters.where((resource) => resource.id == id).firstOrNull ??
      reciters.firstOrNull;
}

Future<void> playRecitation(
  BuildContext context,
  WidgetRef ref, {
  required MushafSurah surah,
  required QuranResource resource,
  AyahRef? verse,
}) async {
  try {
    await ref
        .read(_playbackProvider.notifier)
        .start(
          surah,
          resource,
          Localizations.localeOf(context).languageCode,
          verse: verse,
        );
  } catch (error) {
    if (context.mounted) {
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is VerseTimingUnavailable
                ? l10n.readerVerseAudioUnavailable
                : l10n.readerAudioUnavailable,
          ),
        ),
      );
    }
  }
}

class RecitationPlayer extends ConsumerStatefulWidget {
  const RecitationPlayer({
    required this.surah,
    required this.reciters,
    super.key,
  });

  final MushafSurah surah;
  final List<QuranResource> reciters;

  @override
  ConsumerState<RecitationPlayer> createState() => _RecitationPlayerState();
}

class _RecitationPlayerState extends ConsumerState<RecitationPlayer> {
  int? _reciterId;

  Future<void> _select(QuranResource resource) async {
    setState(() => _reciterId = resource.id);
    try {
      await ref
          .read(keyValueStoreProvider)
          .setString(reciterPreferenceKey, '${resource.id}');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.localSaveFailed)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected =
        widget.reciters.where((value) => value.id == _reciterId).firstOrNull ??
        selectedReciter(ref, widget.reciters);
    if (selected == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final playback = ref.watch(_playbackProvider);
    final track = playback.track;
    final matching =
        track?.surah == widget.surah.id && track?.resource == selected.id;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: DropdownButton<QuranResource>(
                isExpanded: true,
                value: selected,
                items: [
                  for (final resource in widget.reciters)
                    DropdownMenuItem(
                      value: resource,
                      child: Text(
                        resource.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: playback.loading
                    ? null
                    : (resource) {
                        if (resource != null) unawaited(_select(resource));
                      },
              ),
            ),
            if (!matching || playback.loading)
              IconButton(
                tooltip: l10n.readerListenChapter,
                onPressed: playback.loading
                    ? null
                    : () => playRecitation(
                        context,
                        ref,
                        surah: widget.surah,
                        resource: selected,
                      ),
                icon: playback.loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
              ),
          ],
        ),
      ),
    );
  }
}

class RecitationMiniPlayer extends ConsumerWidget {
  const RecitationMiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(_playbackProvider);
    final track = playback.track;
    if (track == null) return const SizedBox.shrink();
    final controller = ref.read(_playbackProvider.notifier);
    final player = ref.watch(_playerProvider);
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;

    Future<void> transport(Future<void> Function() action) async {
      try {
        await action();
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.readerAudioUnavailable)));
        }
      }
    }

    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      initialData: player.playerState,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final completed = state?.processingState == ProcessingState.completed;
        final playing = state?.playing == true && !completed;
        return Material(
          color: colors.primaryContainer,
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.headphones_outlined),
            title: Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              track.reciter,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: playing ? l10n.readerPause : l10n.readerResume,
                  onPressed: playback.loading
                      ? null
                      : () => transport(() async {
                          if (playing) {
                            await controller.pause();
                          } else {
                            if (completed) await player.seek(Duration.zero);
                            unawaited(player.play().catchError((Object _) {}));
                          }
                        }),
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                ),
                IconButton(
                  tooltip: l10n.readerStop,
                  onPressed: playback.loading
                      ? null
                      : () => transport(controller.stop),
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
