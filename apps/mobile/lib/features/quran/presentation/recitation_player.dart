import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/audio/audio_playback.dart';
import '../../../core/content/collection_downloads.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/chapter_reciters.dart';
import '../data/mushaf_edition.dart';
import '../data/offline_recitations.dart';
import '../data/quran_services.dart';
import '../domain/quran_storage_contracts.dart';

String _recitationId(int surah, ChapterReciter reader) =>
    '$surah:${reader.key}';

const reciterPreferenceKey = 'quran.reciter.v1';

ChapterReciter? selectedReciter(WidgetRef ref, List<ChapterReciter> reciters) {
  final id = ref.read(keyValueStoreProvider).getString(reciterPreferenceKey);
  return reciters.where((resource) => resource.key == id).firstOrNull ??
      reciters.firstOrNull;
}

Future<void> playRecitation(
  BuildContext context,
  WidgetRef ref, {
  required MushafSurah surah,
  required ChapterReciter reader,
  AyahRef? verse,
  bool offlineOnly = false,
}) async {
  try {
    Uri? saved;
    if (verse == null && reader.hasOfflineAudio) {
      try {
        final file = await ref
            .read(offlineAudioStoreProvider)
            .fileFor(reader, surah.id);
        saved = file?.uri;
      } on Exception {
        // Playback can still stream when app-private storage is unavailable.
      }
    }
    if (!context.mounted) return;
    if (offlineOnly && saved == null) throw StateError('Download missing');

    final language = Localizations.localeOf(context).languageCode;
    final foundation = reader.foundationId;
    final useFoundation = saved == null && foundation != null;
    final api = useFoundation ? ref.read(quranApiProvider) : null;
    await ref.read(audioPlaybackProvider.notifier).start(
      MediaItem(
        id: _recitationId(surah.id, reader),
        title: surah.name(language),
        artist: reader.name(language),
        album: useFoundation ? 'Quran Foundation' : 'MP3Quran',
      ),
      () async {
        if (verse != null && foundation != null) {
          return api!.audioAtVerse(verse, foundation);
        }
        final url =
            saved ??
            (foundation != null
                ? await api!.audio(surah.id, foundation)
                : reader.publisherAudio(surah.id));
        if (url == null) throw StateError('Recording unavailable');
        return (url: url, start: Duration.zero);
      },
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

Future<void> _removeDownload(
  BuildContext context,
  WidgetRef ref,
  ChapterReciter reader,
  int chapter,
) async {
  try {
    final playback = ref.read(audioPlaybackProvider);
    if (playback.track?.id == _recitationId(chapter, reader)) {
      await ref.read(audioPlaybackProvider.notifier).stop();
    }
    if (context.mounted) {
      await ref.read(audioDownloadProvider.notifier).remove(reader, chapter);
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.recitationDownloadFailed)),
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
  final List<ChapterReciter> reciters;

  @override
  ConsumerState<RecitationPlayer> createState() => _RecitationPlayerState();
}

class _RecitationPlayerState extends ConsumerState<RecitationPlayer> {
  String? _reciterKey;

  Future<void> _select(ChapterReciter reader) async {
    setState(() => _reciterKey = reader.key);
    try {
      await ref
          .read(keyValueStoreProvider)
          .setString(reciterPreferenceKey, reader.key);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.localSaveFailed)));
      }
    }
  }

  Future<void> _download(ChapterReciter reader) async {
    try {
      await ref
          .read(audioDownloadProvider.notifier)
          .download(reader, widget.surah.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.recitationDownloadFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected =
        widget.reciters
            .where((value) => value.key == _reciterKey)
            .firstOrNull ??
        selectedReciter(ref, widget.reciters);
    if (selected == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final playback = ref.watch(audioPlaybackProvider);
    final download = ref.watch(audioDownloadProvider);
    final batch = ref.watch(collectionDownloadsProvider)?.running == true;
    final key = offlineAudioKey(selected, widget.surah.id);
    final saved =
        ref.watch(offlineAudioLibraryProvider).asData?.value.contains(key) ==
        true;
    final loading =
        playback.pending?.id == _recitationId(widget.surah.id, selected);
    final downloadProgress = download?.key == key ? download : null;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: DropdownButton<ChapterReciter>(
                isExpanded: true,
                value: selected,
                items: [
                  for (final reader in widget.reciters)
                    DropdownMenuItem(
                      value: reader,
                      child: Text(
                        reader.name(language),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: playback.pending != null
                    ? null
                    : (reader) {
                        if (reader != null) unawaited(_select(reader));
                      },
              ),
            ),
            IconButton(
              tooltip: saved
                  ? l10n.recitationPlayOffline
                  : l10n.readerListenChapter,
              onPressed: playback.pending != null
                  ? null
                  : () => playRecitation(
                      context,
                      ref,
                      surah: widget.surah,
                      reader: selected,
                    ),
              icon: loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(saved ? Icons.offline_pin_outlined : Icons.play_arrow),
            ),
            if (downloadProgress != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 8, end: 12),
                child: SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    value: downloadProgress.progress,
                    semanticsLabel: l10n.recitationDownloading,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (selected.hasOfflineAudio)
              IconButton(
                tooltip: saved
                    ? l10n.recitationRemoveDownload
                    : l10n.recitationDownload,
                onPressed: batch || download != null || playback.pending != null
                    ? null
                    : saved
                    ? () => _removeDownload(
                        context,
                        ref,
                        selected,
                        widget.surah.id,
                      )
                    : () => _download(selected),
                icon: Icon(
                  saved ? Icons.delete_outline : Icons.download_outlined,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> showRecitationDownloads(
  BuildContext context,
  MushafEdition edition,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => FractionallySizedBox(
    heightFactor: .68,
    child: _RecitationDownloads(edition: edition),
  ),
);

class _RecitationDownloads extends ConsumerWidget {
  const _RecitationDownloads({required this.edition});

  final MushafEdition edition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final library = ref.watch(offlineAudioLibraryProvider);
    final selection = ref.watch(reciterSelectionProvider);
    final busy =
        ref.watch(collectionDownloadsProvider)?.running == true ||
        ref.watch(audioDownloadProvider) != null;
    final ar = language == 'ar';
    final readers = {for (final reader in selection.all) reader.key: reader};
    return Column(
      children: [
        Text(
          l10n.recitationDownloads,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const CollectionDownloadStatus(),
        if (selection.active.isNotEmpty)
          PopupMenuButton<ChapterReciter>(
            enabled: !busy,
            icon: const Icon(Icons.download_for_offline_outlined),
            tooltip: ar
                ? 'تنزيل تلاوات قارئ'
                : 'Download a reciter’s recordings',
            onSelected: (reader) {
              final controller = ref.read(audioDownloadProvider.notifier);
              final label = reader.name(language);
              unawaited(
                ref.read(collectionDownloadsProvider.notifier).start(label, [
                  for (final surah in edition.surahs)
                    if (reader.publisherAudio(surah.id) != null)
                      () => controller.download(reader, surah.id),
                ]),
              );
            },
            itemBuilder: (_) => [
              for (final reader in selection.active)
                PopupMenuItem(
                  value: reader,
                  child: Text(reader.name(language)),
                ),
            ],
          ),
        const SizedBox(height: 8),
        Expanded(
          child: library.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(child: Text(l10n.recitationDownloadFailed)),
            data: (saved) {
              if (saved.isEmpty) {
                return Center(child: Text(l10n.recitationNoDownloads));
              }
              final entries = saved.toList()
                ..sort((a, b) => a.chapter.compareTo(b.chapter));
              return ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final surah = edition.surahs[entry.chapter - 1];
                  final reader = readers[entry.reciterKey]!;
                  return ListTile(
                    leading: const Icon(Icons.play_circle_outline),
                    title: Text(surah.name(language)),
                    subtitle: Text('${reader.name(language)} · MP3Quran'),
                    onTap: () => playRecitation(
                      context,
                      ref,
                      surah: surah,
                      reader: reader,
                      offlineOnly: true,
                    ),
                    trailing: IconButton(
                      tooltip: l10n.recitationRemoveDownload,
                      onPressed: () =>
                          _removeDownload(context, ref, reader, surah.id),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
