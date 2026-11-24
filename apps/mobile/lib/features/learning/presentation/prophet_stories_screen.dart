import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/content/collection_downloads.dart';
import '../../../core/content/feature_preview.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../core/widgets/section_detail_scaffold.dart';
import '../data/learning_catalog.dart';
import '../data/learning_files.dart';
import '../data/prophet_stories.dart';
import 'episode_series_screen.dart';

/// The prophet's name alone, for the round badge: «سيدنا آدم عليه السلام»
/// becomes «آدم», "Adam, peace be upon him" becomes "Adam".
String prophetShortName(String title) => title
    .replaceFirst(RegExp(r'^سيدنا\s+'), '')
    .replaceFirst(RegExp(r'\s+عليه(ا|م)?\s+السلام$'), '')
    .replaceFirst(RegExp(r',?\s+peace be upon (him|her|them)$'), '')
    .trim();

class ProphetStoriesScreen extends ConsumerWidget {
  const ProphetStoriesScreen({super.key});

  Future<void> _downloadAll(
    BuildContext context,
    WidgetRef ref,
    List<LearningSeries> series,
  ) async {
    final l10n = context.l10n;
    final manager = ref.read(collectionDownloadsProvider.notifier);
    final files = ref.read(learningFilesProvider);
    final scope = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                l10n.learningDownloadAllStories,
                style: Theme.of(sheet).textTheme.titleLarge,
              ),
            ),
            for (final (scope, icon, label) in [
              ('audio', Icons.headphones_outlined, l10n.learningFormatAudio),
              ('video', Icons.videocam_outlined, l10n.learningFormatVideo),
              ('both', Icons.perm_media_outlined, l10n.learningAudioAndVideo),
            ])
              ListTile(
                leading: Icon(icon),
                title: Text(label),
                onTap: () => Navigator.pop(sheet, scope),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (scope == null || !context.mounted) return;
    await manager.start(l10n.learningDownloadAllStories, [
      for (final item in series)
        for (final episode in item.episodes)
          for (final media in episode.media.values)
            if ((scope == 'both' || scope == media.format.name) &&
                files.source(media) != null)
              () => files.download(media),
    ]);
    if (context.mounted) ref.invalidate(lessonSavedProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (AppSection.stories.status.isGated && !managedReleaseEnabled) {
      return const SectionDetailScaffold(section: AppSection.stories);
    }
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final stories = ref.watch(prophetStoriesProvider);
    final busy = ref.watch(collectionDownloadsProvider)?.running == true;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sectionStoriesTitle)),
      body: stories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.learningMediaUnavailable)),
        data: (series) {
          final episodes = series.fold<int>(
            0,
            (sum, item) => sum + item.episodes.length,
          );
          return RefreshIndicator(
            onRefresh: () => ref.refresh(prophetStoriesProvider.future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                ResponsiveContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        color: theme.colorScheme.primary,
                        margin: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.learningStoriesIntro,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                l10n.learningEpisodeCount(
                                  decimalFormat(
                                    Localizations.localeOf(context)
                                        .languageCode,
                                  ).format(episodes),
                                  episodes,
                                ),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onPrimary.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                              if (episodes > 0) ...[
                                const SizedBox(height: AppSpacing.md),
                                FilledButton.tonalIcon(
                                  key: const Key('stories-download-all'),
                                  onPressed: busy
                                      ? null
                                      : () =>
                                            _downloadAll(context, ref, series),
                                  icon: const Icon(
                                    Icons.download_for_offline_outlined,
                                  ),
                                  label: Text(l10n.learningDownloadAllStories),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const CollectionDownloadStatus(),
                      const SizedBox(height: AppSpacing.md),
                      for (final story in series) _StoryCard(story: story),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.story});

  final LearningSeries story;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    final numbers = decimalFormat(language);
    final title = story.title(language);
    final empty = story.episodes.isEmpty;
    final formats = [
      for (final format in LessonFormat.values)
        if (story.queue(format, 1).isNotEmpty) format,
    ];
    return Card(
      key: ValueKey('story-${story.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => EpisodeSeriesScreen(series: story)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              ProphetBadge(title: title, size: 64, muted: empty),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            empty
                                ? l10n.learningSoon
                                : l10n.learningEpisodeCount(
                                    numbers.format(story.episodes.length),
                                    story.episodes.length,
                                  ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        for (final format in formats) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Icon(
                            format == LessonFormat.audio
                                ? Icons.headphones_outlined
                                : Icons.videocam_outlined,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                empty ? Icons.schedule : Icons.play_circle_fill,
                size: empty ? 24 : 40,
                color: empty ? scheme.outline : scheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A round badge with the prophet's name in the reading font.
class ProphetBadge extends StatelessWidget {
  const ProphetBadge({
    required this.title,
    this.size = 64,
    this.muted = false,
    super.key,
  });

  final String title;
  final double size;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = prophetShortName(title);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      padding: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: muted
            ? null
            : LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [scheme.primary, scheme.tertiary],
              ),
        color: muted ? scheme.surfaceContainerHighest : null,
      ),
      child: FittedBox(
        child: Text(
          name,
          style: TextStyle(
            fontFamily: AppTheme.readingFontFamily,
            fontSize: size * 0.32,
            height: 1.2,
            fontWeight: FontWeight.w700,
            color: muted ? scheme.onSurfaceVariant : scheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
