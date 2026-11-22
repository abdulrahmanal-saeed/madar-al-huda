import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/mushaf_edition.dart';
import '../data/quran_services.dart';

final _playerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(() => unawaited(player.dispose()));
  return player;
});

typedef _Track = ({int surah, int resource, String title, String reciter});

final _currentTrackProvider = NotifierProvider<_CurrentTrack, _Track?>(
  _CurrentTrack.new,
);

class _CurrentTrack extends Notifier<_Track?> {
  @override
  _Track? build() => null;

  void show(_Track? track) => state = track;
}

class RecitationPlayer extends ConsumerStatefulWidget {
  const RecitationPlayer({
    required this.surah,
    required this.reciters,
    required this.language,
    super.key,
  });

  final MushafSurah surah;
  final List<QuranResource> reciters;
  final String language;

  @override
  ConsumerState<RecitationPlayer> createState() => _RecitationPlayerState();
}

class _RecitationPlayerState extends ConsumerState<RecitationPlayer> {
  static const reciterKey = 'quran.reciter.v1';
  int? _reciterId;
  bool _loading = false;
  StreamSubscription<PlayerException>? _errors;

  @override
  void initState() {
    super.initState();
    _reciterId = int.tryParse(
      ref.read(keyValueStoreProvider).getString(reciterKey) ?? '',
    );
  }

  @override
  void dispose() {
    unawaited(_errors?.cancel());
    super.dispose();
  }

  Future<void> _select(QuranResource resource) async {
    setState(() => _reciterId = resource.id);
    try {
      await ref
          .read(keyValueStoreProvider)
          .setString(reciterKey, '${resource.id}');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.localSaveFailed)));
      }
    }
  }

  void _audioError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.readerAudioUnavailable)),
    );
  }

  Future<void> _play(AudioPlayer player, QuranResource resource) async {
    final track = (
      surah: widget.surah.id,
      resource: resource.id,
      title: widget.surah.name(widget.language),
      reciter: resource.name,
    );
    setState(() => _loading = true);
    try {
      _errors ??= player.errorStream.listen((_) {
        unawaited(player.pause());
        _audioError();
      });
      final url = await ref
          .read(quranApiProvider)
          .audio(track.surah, track.resource);
      if (!mounted) return;
      await player.pause();
      if (!mounted) return;
      ref.read(_currentTrackProvider.notifier).show(null);
      await player.setAudioSource(
        AudioSource.uri(
          url,
          tag: MediaItem(
            id: '${track.surah}:${track.resource}',
            title: track.title,
            artist: track.reciter,
            album: 'Quran Foundation',
          ),
        ),
      );
      if (!mounted) return;
      ref.read(_currentTrackProvider.notifier).show(track);
      unawaited(player.play().catchError((Object _) => _audioError()));
    } catch (_) {
      _audioError();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(AudioPlayer player, PlayerState? status) async {
    try {
      if (status?.processingState == ProcessingState.completed) {
        await player.seek(Duration.zero);
        unawaited(player.play().catchError((Object _) => _audioError()));
      } else if (status?.playing == true) {
        await player.pause();
      } else {
        unawaited(player.play().catchError((Object _) => _audioError()));
      }
    } catch (_) {
      _audioError();
    }
  }

  Future<void> _stop(AudioPlayer player) async {
    try {
      await player.stop();
      if (mounted) ref.read(_currentTrackProvider.notifier).show(null);
    } catch (_) {
      _audioError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final track = ref.watch(_currentTrackProvider);
    final selected =
        widget.reciters.where((value) => value.id == _reciterId).firstOrNull ??
        widget.reciters.firstOrNull;
    if (selected == null && track == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final player = ref.watch(_playerProvider);
    final matching =
        track != null &&
        track.surah == widget.surah.id &&
        track.resource == selected?.id;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            if (selected != null)
              Row(
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
                      onChanged: _loading
                          ? null
                          : (resource) {
                              if (resource != null) {
                                unawaited(_select(resource));
                              }
                            },
                    ),
                  ),
                  if (!matching)
                    IconButton(
                      tooltip: l10n.readerPlay,
                      onPressed: _loading
                          ? null
                          : () => _play(player, selected),
                      icon: const Icon(Icons.play_arrow),
                    ),
                  if (_loading)
                    const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            if (track != null)
              StreamBuilder<PlayerState>(
                stream: player.playerStateStream,
                initialData: player.playerState,
                builder: (context, snapshot) {
                  final state = snapshot.data;
                  final playing =
                      state?.playing == true &&
                      state?.processingState != ProcessingState.completed;
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${track.title} · ${track.reciter}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: playing ? l10n.readerPause : l10n.readerResume,
                        onPressed: _loading
                            ? null
                            : () => _toggle(player, state),
                        icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                      ),
                      IconButton(
                        tooltip: l10n.readerStop,
                        onPressed: _loading ? null : () => _stop(player),
                        icon: const Icon(Icons.stop),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
