import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/audio/audio_playback.dart';
import '../../../core/content/collection_downloads.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../../core/localization/search_text.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../data/chapter_reciters.dart';
import '../data/mushaf_edition.dart';
import '../data/offline_recitations.dart';
import '../data/quran_services.dart';
import '../data/recitation_resume.dart';
import '../data/verse_timings.dart';
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
  // Continues a recitation from where it stopped (the first surah only).
  Duration? resumeAt,
  int? resumeAyah,
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

    MediaItem track(MushafSurah item, {bool fromFoundation = false}) {
      final folder = reader.audioFolder;
      // Where the Mushaf finds when each verse starts, to follow the reciter.
      final timing = fromFoundation && foundation != null
          ? foundationTiming(foundation)
          : folder == null
          ? null
          : mp3QuranTiming(folder);
      return MediaItem(
        id: _recitationId(item.id, reader),
        title: item.name(language),
        artist: reader.name(language),
        album: reader.name(language),
        extras: {
          ...recitationExtras(item.id, timing),
          if (verse != null && item.id == surah.id) 'fromAyah': verse.ayah,
          if (verse == null && resumeAyah != null && item.id == surah.id)
            'fromAyah': resumeAyah,
        },
      );
    }

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
                    start: item.id == surah.id
                        ? resumeAt ?? Duration.zero
                        : Duration.zero,
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
        firstSource = (url: url, start: resumeAt ?? Duration.zero);
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

  Future<void> _pickReciter(ChapterReciter selected) async {
    final reader = await showModalBottomSheet<ChapterReciter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _ReciterSheet(
        reciters: widget.reciters,
        selected: selected,
        onDownloads: () => showRecitationDownloads(
          context,
          widget.edition,
          initialReaderKey: selected.key,
        ),
      ),
    );
    if (reader != null && mounted) unawaited(_select(reader));
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    final playback = ref.watch(audioPlaybackProvider);
    final download = ref.watch(audioDownloadProvider);
    final batch = ref.watch(collectionDownloadsProvider)?.running == true;
    final key = offlineAudioKey(selected, widget.surah.id);
    final saved =
        ref.watch(offlineAudioLibraryProvider).asData?.value.contains(key) ==
        true;
    final id = _recitationId(widget.surah.id, selected);
    // One player at a time: while anything is loaded (this surah, another
    // one, a lesson or the radio) the shared mini player below is the only
    // player on screen. Stopping it brings this bar back.
    if (playback.track != null) return const SizedBox.shrink();
    final loading = playback.pending?.id == id;
    final downloadProgress = download?.key == key ? download : null;
    final busy = playback.pending != null;
    // The place this reciter stopped last time, to continue from it.
    final resume = ref.watch(savedRecitationProvider);
    final resumeSurah =
        resume != null &&
            resume.reader == selected.key &&
            resume.surah <= widget.edition.surahs.length &&
            selected.covers(resume.surah)
        ? widget.edition.surahs[resume.surah - 1]
        : null;
    final number = decimalFormat(language).format;
    String clock(int ms) {
      final seconds = ms ~/ 1000;
      return '${number(seconds ~/ 60)}:'
          '${number(seconds % 60).padLeft(2, number(0))}';
    }

    return Material(
      color: scheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (resume != null && resumeSurah != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: FilledButton.tonalIcon(
                  key: const Key('recitation-resume'),
                  onPressed: busy
                      ? null
                      : () => playRecitation(
                          context,
                          ref,
                          edition: widget.edition,
                          surah: resumeSurah,
                          reader: selected,
                          resumeAt: Duration(milliseconds: resume.ms),
                          resumeAyah: resume.ayah,
                        ),
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(
                    resume.ayah != null
                        ? l10n.recitationResumeVerse(
                            resumeSurah.name(language),
                            number(resume.ayah),
                          )
                        : l10n.recitationResumeTime(
                            resumeSurah.name(language),
                            clock(resume.ms),
                          ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    key: const Key('reciter-picker'),
                    borderRadius: AppRadii.lgAll,
                    onTap: busy ? null : () => _pickReciter(selected),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: scheme.primaryContainer,
                            foregroundColor: scheme.onPrimaryContainer,
                            child: const Icon(Icons.record_voice_over_outlined),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  selected.name(language),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall,
                                ),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.surah.name(language),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                    if (saved) ...[
                                      const SizedBox(width: AppSpacing.xs),
                                      Icon(
                                        Icons.offline_pin,
                                        size: 14,
                                        color: scheme.primary,
                                        semanticLabel:
                                            l10n.recitationPlayOffline,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.unfold_more,
                            size: 20,
                            color: scheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (downloadProgress != null)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
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
                    onPressed: batch || download != null || busy
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
                      saved ? Icons.download_done : Icons.download_outlined,
                    ),
                  ),
                const SizedBox(width: AppSpacing.xs),
                IconButton.filled(
                  key: const Key('recitation-play'),
                  tooltip: saved
                      ? l10n.recitationPlayOffline
                      : l10n.readerListenChapter,
                  iconSize: 30,
                  onPressed: busy
                      ? null
                      : () => playRecitation(
                          context,
                          ref,
                          edition: widget.edition,
                          surah: widget.surah,
                          reader: selected,
                        ),
                  icon: loading
                      ? SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Chooses a reciter from the full list, with search.
class _ReciterSheet extends StatefulWidget {
  const _ReciterSheet({
    required this.reciters,
    required this.selected,
    required this.onDownloads,
  });

  final List<ChapterReciter> reciters;
  final ChapterReciter selected;
  final VoidCallback onDownloads;

  @override
  State<_ReciterSheet> createState() => _ReciterSheetState();
}

class _ReciterSheetState extends State<_ReciterSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final needle = normalizeSearch(_query);
    final matches = needle.isEmpty
        ? widget.reciters
        : widget.reciters
              .where(
                (reader) =>
                    normalizeSearch(reader.name('ar')).contains(needle) ||
                    normalizeSearch(reader.name('en')).contains(needle),
              )
              .toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.recitationReciter, style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                if (widget.reciters.length > 6)
                  TextField(
                    key: const Key('reciter-search'),
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: l10n.recitationSearchReciter,
                      isDense: true,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(28)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ListView.builder(
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final reader = matches[index];
                final selected = reader.key == widget.selected.key;
                return ListTile(
                  key: ValueKey('reciter-${reader.key}'),
                  leading: Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected ? theme.colorScheme.primary : null,
                  ),
                  title: Text(reader.name(language)),
                  trailing: reader.hasOfflineAudio
                      ? Icon(
                          Icons.download_for_offline_outlined,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        )
                      : null,
                  selected: selected,
                  onTap: () => Navigator.of(context).pop(reader),
                );
              },
            ),
          ),
          if (widget.selected.hasOfflineAudio)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onDownloads();
                  },
                  icon: const Icon(Icons.download_for_offline_outlined),
                  label: Text(l10n.recitationDownloads),
                ),
              ),
            ),
        ],
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
                  label: Text(
                    l10n.recitationDownloadSurahs(
                      decimalFormat(
                        Localizations.localeOf(context).languageCode,
                      ).format(covered.length),
                    ),
                  ),
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
                    subtitle: Text(reader.name(language)),
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
