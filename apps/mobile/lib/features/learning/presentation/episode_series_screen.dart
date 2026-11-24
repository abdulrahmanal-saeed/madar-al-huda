import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/audio/audio_playback.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/responsive_content.dart';
import '../data/learning_catalog.dart';
import '../data/learning_files.dart';
import 'episode_video_screen.dart';
import 'prophet_stories_screen.dart';

/// Ordered media player shared by stories and future lesson collections.
class EpisodeSeriesScreen extends ConsumerStatefulWidget {
  const EpisodeSeriesScreen({required this.series, super.key});

  final LearningSeries series;

  @override
  ConsumerState<EpisodeSeriesScreen> createState() =>
      _EpisodeSeriesScreenState();
}

class _EpisodeSeriesScreenState extends ConsumerState<EpisodeSeriesScreen> {
  late LessonFormat _format = LessonFormat.values.firstWhere(
    (format) => widget.series.queue(format, 1).isNotEmpty,
    orElse: () => LessonFormat.audio,
  );
  final _saving = <String>{};
  bool _openingVideo = false;

  Future<void> _play(int number) async {
    final format = _format;
    final series = widget.series;
    final files = ref.read(learningFilesProvider);
    final queue = series.queue(format, number).where((episode) {
      final media = episode.media[format]!;
      return files.source(media) != null ||
          ref.read(lessonSavedProvider(media)).asData?.value == true;
    }).toList();
    if (queue.isEmpty || _openingVideo) return;
    final player = ref.read(audioPlaybackProvider.notifier);
    final l10n = context.l10n;
    final title = series.title(Localizations.localeOf(context).languageCode);

    try {
      if (format == LessonFormat.video) {
        setState(() => _openingVideo = true);
        await player.stop();
        if (!mounted) return;
        await Navigator.of(context, rootNavigator: true).push<void>(
          MaterialPageRoute(
            builder: (_) =>
                EpisodeVideoScreen(title: title, queue: queue, files: files),
          ),
        );
      } else {
        final tracks = [
          for (final episode in queue)
            MediaItem(
              id: series.trackId(episode),
              title: l10n.learningEpisodeNumber(
                decimalFormat(Localizations.localeOf(context).languageCode)
                    .format(episode.number),
              ),
              artist: title,
            ),
        ];
        await player.startQueue(
          tracks.first,
          () async => Future.wait([
            for (final (index, episode) in queue.indexed)
              files
                  .playable(episode.media[format]!)
                  .then(
                    (uri) => (
                      track: tracks[index],
                      source: (url: uri, start: Duration.zero),
                    ),
                  ),
          ]),
        );
      }
    } catch (_) {
      _showError(l10n.learningPlaybackFailed);
    } finally {
      if (mounted && format == LessonFormat.video) {
        setState(() => _openingVideo = false);
      }
    }
  }

  Future<void> _save(LessonMedia media, {required bool saved}) async {
    final l10n = context.l10n;
    final files = ref.read(learningFilesProvider);
    setState(() => _saving.add(media.fileName));
    try {
      if (saved) {
        final track = ref.read(audioPlaybackProvider).track;
        if (media.format == LessonFormat.audio &&
            track?.id.startsWith('learning:${widget.series.id}:') == true) {
          await ref.read(audioPlaybackProvider.notifier).stop();
        }
        await files.remove(media);
      } else {
        await files.download(media);
      }
      if (mounted) ref.invalidate(lessonSavedProvider(media));
    } catch (_) {
      _showError(l10n.learningDownloadFailed);
    } finally {
      if (mounted) setState(() => _saving.remove(media.fileName));
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final series = widget.series;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final numbers = decimalFormat(language);
    final title = series.title(language);
    final files = ref.watch(learningFilesProvider);
    final playback = ref.watch(audioPlaybackProvider);
    final episodes = series.queue(_format, 1);
    final formats = [
      for (final format in LessonFormat.values)
        if (series.queue(format, 1).isNotEmpty) format,
    ];
    final firstAvailable = episodes.where((episode) {
      final media = episode.media[_format]!;
      return files.source(media) != null ||
          ref.watch(lessonSavedProvider(media)).asData?.value == true;
    }).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        children: [
          ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    ProphetBadge(title: title, size: 72),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            series.episodes.isEmpty
                                ? l10n.learningSoon
                                : l10n.learningEpisodeCount(
                                    numbers.format(series.episodes.length),
                                    series.episodes.length,
                                  ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (series.description case final description?) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    localizedIn(description, language),
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                if (series.episodes.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 40,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            l10n.learningNoEpisodes,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  if (formats.length > 1)
                    SegmentedButton<LessonFormat>(
                      key: const Key('episode-format'),
                      showSelectedIcon: false,
                      segments: [
                        for (final format in formats)
                          ButtonSegment(
                            value: format,
                            icon: Icon(
                              format == LessonFormat.audio
                                  ? Icons.headphones_outlined
                                  : Icons.videocam_outlined,
                            ),
                            label: Text(
                              format == LessonFormat.audio
                                  ? l10n.learningFormatAudio
                                  : l10n.learningFormatVideo,
                            ),
                          ),
                      ],
                      selected: {_format},
                      onSelectionChanged: (value) =>
                          setState(() => _format = value.single),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  if (firstAvailable == null)
                    Text(l10n.learningMediaUnavailable)
                  else
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      onPressed: _openingVideo || playback.pending != null
                          ? null
                          : () => _play(firstAvailable.number),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(l10n.learningPlaySeries),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  for (final episode in episodes)
                    _episodeTile(episode, playback, files),
                ],
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _episodeTile(
    LessonEpisode episode,
    Playback playback,
    LearningFiles files,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    final numbers = decimalFormat(language);
    final media = episode.media[_format]!;
    final saved = ref.watch(lessonSavedProvider(media)).asData?.value == true;
    final saving = _saving.contains(media.fileName);
    final available = files.source(media) != null;
    final playing =
        _format == LessonFormat.audio &&
        playback.track?.id == widget.series.trackId(episode);
    final size = NumberFormat(
      '0.0',
      numberLocale(language),
    ).format(media.bytes / (1024 * 1024));
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: playing ? scheme.primaryContainer : null,
      child: ListTile(
        key: ValueKey(episode.number),
        contentPadding: const EdgeInsetsDirectional.only(
          start: AppSpacing.md,
          end: AppSpacing.xs,
        ),
        leading: CircleAvatar(
          backgroundColor: playing ? scheme.primary : scheme.secondaryContainer,
          foregroundColor: playing
              ? scheme.onPrimary
              : scheme.onSecondaryContainer,
          child: playing
              ? const Icon(Icons.graphic_eq)
              : Text(numbers.format(episode.number)),
        ),
        title: Text(
          episode.title == null
              ? l10n.learningEpisodeNumber(numbers.format(episode.number))
              : localizedIn(episode.title!, language),
        ),
        subtitle: Row(
          children: [
            Icon(
              _format == LessonFormat.video
                  ? Icons.videocam_outlined
                  : Icons.headphones_outlined,
              size: 14,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                playing ? l10n.learningNowPlaying : l10n.learningFileSize(size),
              ),
            ),
            if (saved) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.offline_pin,
                size: 16,
                color: scheme.primary,
                semanticLabel: l10n.learningDownloaded,
              ),
            ],
          ],
        ),
        onTap:
            (!available && !saved) || _openingVideo || playback.pending != null
            ? null
            : () => _play(episode.number),
        trailing: saving
            ? const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : saved
            ? PopupMenuButton<void>(
                tooltip: l10n.learningEpisodeOptions,
                icon: const Icon(Icons.more_vert),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    onTap: () => _save(media, saved: true),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.delete_outline),
                      title: Text(l10n.learningRemoveDownload),
                    ),
                  ),
                ],
              )
            : available
            ? IconButton(
                tooltip: l10n.learningDownload,
                onPressed: () => _save(media, saved: false),
                icon: const Icon(Icons.download_outlined),
              )
            : null,
      ),
    );
  }
}
