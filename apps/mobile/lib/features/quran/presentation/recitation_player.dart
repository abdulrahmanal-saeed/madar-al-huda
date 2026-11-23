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
  required MushafEdition edition,
  required MushafSurah surah,
  required ChapterReciter reader,
  AyahRef? verse,
  bool offlineOnly = false,
}) async {
  try {
    final chapters = edition.surahs
        .skip(surah.id - 1)
        .where((item) => reader.covers(item.id))
        .toList(growable: false);
    if (chapters.isEmpty || chapters.first.id != surah.id) {
      throw StateError('Recording unavailable');
    }
    final language = Localizations.localeOf(context).languageCode;
    final playback = ref.read(audioPlaybackProvider.notifier);
    final foundation = reader.foundationId;
    final api = foundation == null ? null : ref.read(quranApiProvider);

    MediaItem track(MushafSurah item, {bool fromFoundation = false}) =>
        MediaItem(
          id: _recitationId(item.id, reader),
          title: item.name(language),
          artist: reader.name(language),
          album: fromFoundation ? 'Quran Foundation' : 'MP3Quran',
        );

    if (!offlineOnly &&
        !reader.hasOfflineAudio &&
        api != null &&
        foundation != null) {
      await playback.startDeferredQueue([
        for (final item in chapters)
          (
            track: track(item, fromFoundation: true),
            resolve: () async => verse != null && item.id == surah.id
                ? api.audioAtVerse(verse, foundation)
                : (
                    url: await api.audio(item.id, foundation),
                    start: Duration.zero,
                  ),
          ),
      ]);
      return;
    }

    Map<int, Uri> saved = const {};
    if (reader.hasOfflineAudio) {
      try {
        saved = await ref
            .read(offlineAudioStoreProvider)
            .filesFor(reader, chapters.map((chapter) => chapter.id));
      } on Exception {
        // Playback can still stream when app-private storage is unavailable.
      }
    }
    if (!context.mounted) return;
    final firstFile = saved[surah.id];
    if (offlineOnly && firstFile == null) throw StateError('Download missing');

    final useFoundation =
        !offlineOnly &&
        foundation != null &&
        (verse != null || firstFile == null);
    final first = track(surah, fromFoundation: useFoundation);
    await playback.startQueue(first, () async {
      final PlaybackSource firstSource;
      if (useFoundation && verse != null) {
        firstSource = await api!.audioAtVerse(verse, foundation);
      } else {
        final url = useFoundation
            ? await api!.audio(surah.id, foundation)
            : firstFile ?? reader.publisherAudio(surah.id);
        if (url == null) throw StateError('Recording unavailable');
        firstSource = (url: url, start: Duration.zero);
      }
      return [
        (track: first, source: firstSource),
        for (final item in chapters.skip(1))
          if ((saved[item.id] ??
                  (offlineOnly ? null : reader.publisherAudio(item.id)))
              case final url?)
            (track: track(item), source: (url: url, start: Duration.zero)),
      ];
    });
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
    final playback = ref.read(audioPlaybackProvider.notifier);
    if (playback.containsTrack(_recitationId(chapter, reader))) {
      await playback.stop();
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
    required this.edition,
    required this.surah,
    required this.reciters,
    super.key,
  });

  final MushafEdition edition;
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
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
                          edition: widget.edition,
                          surah: widget.surah,
                          reader: selected,
                        ),
                  icon: loading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          saved ? Icons.offline_pin_outlined : Icons.play_arrow,
                        ),
                ),
                if (downloadProgress != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 8,
                      end: 12,
                    ),
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
                    onPressed:
                        batch || download != null || playback.pending != null
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
            if (selected.hasOfflineAudio)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: () => showRecitationDownloads(
                    context,
                    widget.edition,
                    initialReaderKey: selected.key,
                  ),
                  icon: const Icon(Icons.download_for_offline_outlined),
                  label: Text(
                    widget.edition.surahs.every(
                          (item) => selected.covers(item.id),
                        )
                        ? l10n.recitationDownloadMushaf
                        : l10n.recitationDownloadAvailable,
                  ),
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
  MushafEdition edition, {
  String? initialReaderKey,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => FractionallySizedBox(
    heightFactor: .68,
    child: _RecitationDownloads(
      edition: edition,
      initialReaderKey: initialReaderKey,
    ),
  ),
);

class _RecitationDownloads extends ConsumerStatefulWidget {
  const _RecitationDownloads({required this.edition, this.initialReaderKey});

  final MushafEdition edition;
  final String? initialReaderKey;

  @override
  ConsumerState<_RecitationDownloads> createState() =>
      _RecitationDownloadsState();
}

class _RecitationDownloadsState extends ConsumerState<_RecitationDownloads> {
  String? _readerKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final library = ref.watch(offlineAudioLibraryProvider);
    final selection = ref.watch(reciterSelectionProvider);
    final busy =
        ref.watch(collectionDownloadsProvider)?.running == true ||
        ref.watch(audioDownloadProvider) != null;
    final edition = widget.edition;
    final readers = {for (final reader in selection.all) reader.key: reader};
    final downloadable = selection.active
        .where((reader) => reader.hasOfflineAudio)
        .toList(growable: false);
    final selected =
        downloadable
            .where(
              (reader) => reader.key == (_readerKey ?? widget.initialReaderKey),
            )
            .firstOrNull ??
        selectedReciter(ref, downloadable);
    final covered = selected == null
        ? const <MushafSurah>[]
        : edition.surahs.where((surah) => selected.covers(surah.id)).toList();
    final saved = library.asData?.value ?? const <OfflineAudioKey>{};
    final remaining = selected == null
        ? const <MushafSurah>[]
        : covered
              .where(
                (surah) => !saved.contains(offlineAudioKey(selected, surah.id)),
              )
              .toList();
    final canRemove = !busy && ref.watch(audioPlaybackProvider).pending == null;
    return Column(
      children: [
        Text(
          l10n.recitationDownloads,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const CollectionDownloadStatus(),
        if (selected != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.readerReciter),
                DropdownButton<ChapterReciter>(
                  value: selected,
                  isExpanded: true,
                  onChanged: busy
                      ? null
                      : (reader) => setState(() => _readerKey = reader?.key),
                  items: [
                    for (final reader in downloadable)
                      DropdownMenuItem(
                        value: reader,
                        child: Text(
                          reader.name(language),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.download_for_offline_outlined),
                  label: Text(l10n.recitationDownloadSurahs(covered.length)),
                  onPressed: busy || remaining.isEmpty || library.isLoading
                      ? null
                      : () {
                          final controller = ref.read(
                            audioDownloadProvider.notifier,
                          );
                          unawaited(
                            ref
                                .read(collectionDownloadsProvider.notifier)
                                .start(selected.name(language), [
                                  for (final surah in remaining)
                                    () =>
                                        controller.download(selected, surah.id),
                                ]),
                          );
                        },
                ),
              ],
            ),
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
              final entries =
                  saved
                      .where((entry) => readers.containsKey(entry.reciterKey))
                      .toList()
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
                      edition: edition,
                      surah: surah,
                      reader: reader,
                      offlineOnly: true,
                    ),
                    trailing: IconButton(
                      tooltip: l10n.recitationRemoveDownload,
                      onPressed: canRemove
                          ? () =>
                                _removeDownload(context, ref, reader, surah.id)
                          : null,
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
