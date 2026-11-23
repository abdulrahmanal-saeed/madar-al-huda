import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/audio/audio_playback.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/mushaf_edition.dart';
import '../data/quran_services.dart';
import '../domain/quran_storage_contracts.dart';

String _recitationId(int surah, int resource) => '$surah:$resource';

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
    final language = Localizations.localeOf(context).languageCode;
    final api = ref.read(quranApiProvider);
    await ref
        .read(audioPlaybackProvider.notifier)
        .start(
          MediaItem(
            id: _recitationId(surah.id, resource.id),
            title: surah.name(language),
            artist: resource.name,
            album: 'Quran Foundation',
          ),
          () async => verse == null
              ? (
                  url: await api.audio(surah.id, resource.id),
                  start: Duration.zero,
                )
              : api.audioAtVerse(verse, resource.id),
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
    final playback = ref.watch(audioPlaybackProvider);
    final track = playback.track;
    final matching = track?.id == _recitationId(widget.surah.id, selected.id);
    final busy = playback.pending != null;
    final loading =
        playback.pending?.id == _recitationId(widget.surah.id, selected.id);
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
                onChanged: busy
                    ? null
                    : (resource) {
                        if (resource != null) unawaited(_select(resource));
                      },
              ),
            ),
            if (!matching || loading)
              IconButton(
                tooltip: l10n.readerListenChapter,
                onPressed: busy
                    ? null
                    : () => playRecitation(
                        context,
                        ref,
                        surah: widget.surah,
                        resource: selected,
                      ),
                icon: loading
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
