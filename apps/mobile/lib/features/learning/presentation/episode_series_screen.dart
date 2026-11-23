import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/audio/audio_playback.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/responsive_content.dart';
import '../data/learning_catalog.dart';
import '../data/learning_files.dart';
import 'episode_video_screen.dart';

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
              title: l10n.learningEpisodeNumber(episode.number),
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
    final title = series.title(Localizations.localeOf(context).languageCode);
    final files = ref.watch(learningFilesProvider);
    final playback = ref.watch(audioPlaybackProvider);
    final episodes = series.queue(_format, 1);
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
                const SizedBox(height: AppSpacing.md),
                if (series.episodes.isEmpty)
                  Text(l10n.learningNoEpisodes)
                else ...[
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final format in LessonFormat.values)
                        if (series.queue(format, 1).isNotEmpty)
                          ChoiceChip(
                            avatar: Icon(
                              format == LessonFormat.audio
                                  ? Icons.headphones_outlined
                                  : Icons.videocam_outlined,
                            ),
                            label: Text(
                              format == LessonFormat.audio
                                  ? l10n.learningFormatAudio
                                  : l10n.learningFormatVideo,
                            ),
                            selected: _format == format,
                            onSelected: (_) => setState(() => _format = format),
                          ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (firstAvailable == null)
                    Text(l10n.learningMediaUnavailable),
                  if (firstAvailable != null)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FilledButton.icon(
                        onPressed: _openingVideo || playback.pending != null
                            ? null
                            : () => _play(firstAvailable.number),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(l10n.learningPlaySeries),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
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
    final media = episode.media[_format]!;
    final saved = ref.watch(lessonSavedProvider(media)).asData?.value == true;
    final saving = _saving.contains(media.fileName);
    final available = files.source(media) != null;
    final selected =
        _format == LessonFormat.audio &&
        playback.track?.id == widget.series.trackId(episode);
    return Card(
      child: ListTile(
        key: ValueKey(episode.number),
        selected: selected,
        leading: Icon(
          _format == LessonFormat.video
              ? Icons.play_circle_outline
              : Icons.headphones_outlined,
        ),
        title: Text(l10n.learningEpisodeNumber(episode.number)),
        subtitle: saved ? Text(l10n.learningDownloaded) : null,
        onTap:
            (!available && !saved) || _openingVideo || playback.pending != null
            ? null
            : () => _play(episode.number),
        trailing: saving
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : (available || saved)
            ? IconButton(
                tooltip: saved
                    ? l10n.learningRemoveDownload
                    : l10n.learningDownload,
                onPressed: () => _save(media, saved: saved),
                icon: Icon(
                  saved ? Icons.delete_outline : Icons.download_outlined,
                ),
              )
            : null,
      ),
    );
  }
}
