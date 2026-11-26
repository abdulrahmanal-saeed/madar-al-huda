import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/content/collection_downloads.dart';
import '../../../core/content/managed_library.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../../core/localization/search_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../adhkar/data/adhkar_catalog.dart';
import '../../learning/data/learning_catalog.dart';
import '../../learning/data/learning_files.dart';
import '../../learning/data/prophet_stories.dart';
import '../../library/domain/library_sections.dart';
import '../../quran/data/chapter_reciters.dart';
import '../../quran/data/offline_recitations.dart';
import '../data/download_usage.dart';

/// One place to keep the app working without internet: what is always on
/// the device, what can be downloaded, and what stays online for rights
/// reasons.
enum _DownloadsTab { recitations, stories, library }

class DownloadCenterScreen extends ConsumerStatefulWidget {
  const DownloadCenterScreen({super.key});

  @override
  ConsumerState<DownloadCenterScreen> createState() =>
      _DownloadCenterScreenState();
}

class _DownloadCenterScreenState extends ConsumerState<DownloadCenterScreen> {
  _DownloadsTab _tab = _DownloadsTab.recitations;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final number = decimalFormat(language).format;
    final usage = ref.watch(downloadUsageProvider).asData?.value;
    final busy = ref.watch(collectionDownloadsProvider)?.running == true;
    final selection = ref.watch(reciterSelectionProvider);
    final saved =
        ref.watch(offlineAudioLibraryProvider).asData?.value ??
        const <OfflineAudioKey>{};
    int savedFor(ChapterReciter reader) => saved
        .where(
          (key) => [
            for (var chapter = 1; chapter <= 114; chapter++)
              offlineAudioKey(reader, chapter),
          ].contains(key),
        )
        .length;
    final needle = normalizeSearch(_query);
    // Reciters with downloads first; the search narrows a long list.
    final readers =
        selection.active
            .where((reader) => reader.hasOfflineAudio)
            .where(
              (reader) =>
                  needle.isEmpty ||
                  normalizeSearch(reader.name('ar')).contains(needle) ||
                  normalizeSearch(reader.name('en')).contains(needle),
            )
            .toList()
          ..sort((a, b) => savedFor(b).compareTo(savedFor(a)));
    final allReaders = selection.active
        .where((reader) => reader.hasOfflineAudio)
        .length;
    final stories = ref.watch(prophetStoriesProvider).asData?.value;
    final libraryFeed = ref.watch(managedLibraryProvider).asData?.value;
    final librarySections = ref
        .watch(librarySectionsProvider)
        .whereType<LinksEntry>();

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.xl,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.downloadsTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.md),
                _DeviceSummary(
                  used: usage == null
                      ? null
                      : formatBytes(usage.total, language, number),
                ),
                const CollectionDownloadStatus(),
                const SizedBox(height: AppSpacing.lg),
                SegmentedButton<_DownloadsTab>(
                  key: const Key('downloads-tabs'),
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: _DownloadsTab.recitations,
                      icon: const Icon(Icons.headphones_outlined),
                      label: Text(l10n.downloadsRecitations),
                    ),
                    if (stories != null && stories.isNotEmpty)
                      ButtonSegment(
                        value: _DownloadsTab.stories,
                        icon: const Icon(Icons.auto_stories_outlined),
                        label: Text(l10n.downloadsStoriesTab),
                      ),
                    ButtonSegment(
                      value: _DownloadsTab.library,
                      icon: const Icon(Icons.library_books_outlined),
                      label: Text(l10n.downloadsLibraryTab),
                    ),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (value) =>
                      setState(() => _tab = value.single),
                ),
                if (_tab == _DownloadsTab.recitations) ...[
                  if (allReaders > 6) ...[
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      key: const Key('downloads-search'),
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
                  heading(l10n.downloadsRecitations),
                  Card(
                    child: Column(
                      children: [
                        if (readers.isEmpty)
                          ListTile(title: Text(l10n.downloadsNoReciters)),
                        for (final reader in readers)
                          _ReciterRow(
                            reader: reader,
                            saved: saved,
                            busy: busy,
                            number: number,
                          ),
                      ],
                    ),
                  ),
                ],
                if (_tab == _DownloadsTab.stories &&
                    stories != null &&
                    stories.isNotEmpty) ...[
                  heading(l10n.downloadsStories),
                  Card(
                    child: Column(
                      children: [
                        for (final series in stories)
                          _SeriesRow(
                            series: series,
                            busy: busy,
                            number: number,
                          ),
                      ],
                    ),
                  ),
                ],
                if (_tab == _DownloadsTab.library) ...[
                  heading(l10n.downloadsLibrary),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        libraryFeed != null
                            ? Icons.offline_pin
                            : Icons.cloud_download_outlined,
                        color: libraryFeed != null
                            ? theme.colorScheme.primary
                            : null,
                      ),
                      title: Text(l10n.downloadsLibraryBody),
                      subtitle: Text(
                        libraryFeed != null
                            ? l10n.downloadsLibrarySaved
                            : l10n.downloadsLibraryMissing,
                      ),
                      trailing: TextButton(
                        onPressed: busy
                            ? null
                            : () => unawaited(
                                ref
                                    .read(collectionDownloadsProvider.notifier)
                                    .start(l10n.downloadsLibrary, [
                                      () async {
                                        if (await ref.refresh(
                                              managedLibraryProvider.future,
                                            ) ==
                                            null) {
                                          throw StateError(
                                            'Library unavailable',
                                          );
                                        }
                                      },
                                      () async => ref.refresh(
                                        adhkarCatalogProvider.future,
                                      ),
                                    ])
                                    .whenComplete(
                                      () =>
                                          ref.invalidate(downloadUsageProvider),
                                    ),
                              ),
                        child: Text(l10n.downloadsUpdate),
                      ),
                    ),
                  ),
                  for (final section in librarySections)
                    if (section.seasons.isNotEmpty) ...[
                      heading(section.title.inLanguage(language)),
                      Card(
                        child: Column(
                          children: [
                            for (final series in section.seasons)
                              _SeriesRow(
                                series: series,
                                busy: busy,
                                number: number,
                              ),
                          ],
                        ),
                      ),
                    ],
                  heading(l10n.downloadsOnlineOnly),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.cloud_outlined),
                          title: Text(l10n.sectionTafsirTitle),
                          subtitle: Text(l10n.downloadsOnlineOnlyBody),
                        ),
                        ListTile(
                          leading: const Icon(Icons.cloud_outlined),
                          title: Text(l10n.sectionHadithTitle),
                          subtitle: Text(l10n.downloadsOnlineOnlyBody),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceSummary extends StatelessWidget {
  const _DeviceSummary({required this.used});

  final String? used;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // The card keeps the brand green in light and dark themes alike.
    const onPrimary = BrandColors.ivory;
    final always = [
      l10n.navQuran,
      l10n.sectionAdhkarTitle,
      l10n.sectionPrayerTimesTitle,
      l10n.sectionQiblaTitle,
    ];
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: AppRadii.xlAll,
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [BrandColors.primaryGreen, BrandColors.heroGreenEnd],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.downloadsOnDevice,
              style: theme.textTheme.titleMedium?.copyWith(color: onPrimary),
            ),
            if (used != null)
              Text(
                l10n.downloadsUsed(used!),
                key: const ValueKey('downloads-used'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: onPrimary.withValues(alpha: 0.85),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.downloadsAlwaysOffline,
              style: theme.textTheme.labelLarge?.copyWith(color: onPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final item in always)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: onPrimary.withValues(alpha: 0.14),
                      borderRadius: AppRadii.xlAll,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs + 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 18,
                            color: BrandColors.goldBright,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            item,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReciterRow extends ConsumerWidget {
  const _ReciterRow({
    required this.reader,
    required this.saved,
    required this.busy,
    required this.number,
  });

  final ChapterReciter reader;
  final Set<OfflineAudioKey> saved;
  final bool busy;
  final String Function(num) number;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final chapters = [
      for (var chapter = 1; chapter <= 114; chapter++)
        if (reader.covers(chapter)) chapter,
    ];
    final done = chapters
        .where((chapter) => saved.contains(offlineAudioKey(reader, chapter)))
        .toList();
    final remaining = chapters
        .where((chapter) => !done.contains(chapter))
        .toList();
    final store = ref.read(offlineAudioStoreProvider);

    void refresh() {
      ref
        ..invalidate(offlineAudioLibraryProvider)
        ..invalidate(downloadUsageProvider);
    }

    return ListTile(
      key: ValueKey('downloads-reciter-${reader.key}'),
      leading: const Icon(Icons.headphones_outlined),
      title: Text(reader.name(language)),
      subtitle: Text(
        l10n.downloadsReciterProgress(
          number(done.length),
          number(chapters.length),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (done.isNotEmpty)
            IconButton(
              tooltip: l10n.downloadsRemoveAll,
              icon: const Icon(Icons.delete_outline),
              onPressed: busy
                  ? null
                  : () async {
                      if (!await _confirmRemoval(
                        context,
                        reader.name(language),
                      )) {
                        return;
                      }
                      for (final chapter in done) {
                        await store.remove(reader, chapter);
                      }
                      refresh();
                    },
            ),
          if (remaining.isNotEmpty)
            IconButton.filledTonal(
              tooltip: l10n.downloadsAll,
              icon: const Icon(Icons.download),
              onPressed: busy
                  ? null
                  : () => unawaited(
                      ref
                          .read(collectionDownloadsProvider.notifier)
                          .start(reader.name(language), [
                            for (final chapter in remaining)
                              () => store.download(reader, chapter, (_) {}),
                          ])
                          .whenComplete(refresh),
                    ),
            ),
        ],
      ),
    );
  }
}

class _SeriesRow extends ConsumerStatefulWidget {
  const _SeriesRow({
    required this.series,
    required this.busy,
    required this.number,
  });

  final LearningSeries series;
  final bool busy;
  final String Function(num) number;

  @override
  ConsumerState<_SeriesRow> createState() => _SeriesRowState();
}

class _SeriesRowState extends ConsumerState<_SeriesRow> {
  int? _saved;

  /// Audio is offered for offline use: it is far smaller than video.
  List<LessonMedia> get _media => [
    for (final episode in widget.series.episodes)
      ?episode.media[LessonFormat.audio],
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_count());
  }

  Future<void> _count() async {
    final files = ref.read(learningFilesProvider);
    var saved = 0;
    for (final media in _media) {
      try {
        if (await files.saved(media) != null) saved++;
      } on Object {
        // Unreadable storage counts as not saved.
      }
    }
    if (mounted) setState(() => _saved = saved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final media = _media;
    final saved = _saved;
    final files = ref.read(learningFilesProvider);
    Future<void> after() async {
      await _count();
      ref.invalidate(downloadUsageProvider);
    }

    return ListTile(
      leading: const Icon(Icons.auto_stories_outlined),
      title: Text(widget.series.title(language)),
      subtitle: Text(
        saved == null
            ? ''
            : l10n.downloadsEpisodeProgress(
                widget.number(saved),
                widget.number(media.length),
              ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if ((saved ?? 0) > 0)
            IconButton(
              tooltip: l10n.downloadsRemoveAll,
              icon: const Icon(Icons.delete_outline),
              onPressed: widget.busy
                  ? null
                  : () async {
                      if (!await _confirmRemoval(
                        context,
                        widget.series.title(language),
                      )) {
                        return;
                      }
                      for (final item in media) {
                        await files.remove(item);
                      }
                      await after();
                    },
            ),
          if (saved != null && saved < media.length && files.base != null)
            IconButton.filledTonal(
              tooltip: l10n.downloadsAll,
              icon: const Icon(Icons.download),
              onPressed: widget.busy
                  ? null
                  : () => unawaited(
                      ref
                          .read(collectionDownloadsProvider.notifier)
                          .start(widget.series.title(language), [
                            for (final item in media)
                              () => files.download(item),
                          ])
                          .whenComplete(after),
                    ),
            ),
        ],
      ),
    );
  }
}

Future<bool> _confirmRemoval(BuildContext context, String name) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(l10n.downloadsRemoveConfirm(name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.downloadsCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.downloadsConfirmRemove),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
