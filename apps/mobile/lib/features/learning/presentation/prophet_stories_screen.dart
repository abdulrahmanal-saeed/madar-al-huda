import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/content/collection_downloads.dart';
import '../../../core/content/feature_preview.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../core/widgets/section_detail_scaffold.dart';
import '../data/learning_catalog.dart';
import '../data/learning_files.dart';
import '../data/prophet_stories.dart';
import 'episode_series_screen.dart';

class ProphetStoriesScreen extends ConsumerWidget {
  const ProphetStoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (AppSection.stories.status.isGated && !managedReleaseEnabled) {
      return const SectionDetailScaffold(section: AppSection.stories);
    }
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final stories = ref.watch(prophetStoriesProvider);
    final ar = language == 'ar';
    final title = ar ? 'تنزيل كل القصص' : 'Download all stories';
    final busy = ref.watch(collectionDownloadsProvider)?.running == true;
    final files = ref.watch(learningFilesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sectionStoriesTitle),
        actions: [
          if (stories.asData?.value.any((item) => item.episodes.isNotEmpty) ==
              true)
            IconButton(
              tooltip: title,
              icon: const Icon(Icons.download_for_offline_outlined),
              onPressed: busy
                  ? null
                  : () async {
                      final manager = ref.read(
                        collectionDownloadsProvider.notifier,
                      );
                      final scope = await showDialog<String>(
                        context: context,
                        builder: (dialog) => SimpleDialog(
                          title: Text(title),
                          children: [
                            for (final format in LessonFormat.values)
                              SimpleDialogOption(
                                onPressed: () =>
                                    Navigator.pop(dialog, format.name),
                                child: Text(
                                  format == LessonFormat.audio
                                      ? l10n.learningFormatAudio
                                      : l10n.learningFormatVideo,
                                ),
                              ),
                            SimpleDialogOption(
                              onPressed: () => Navigator.pop(dialog, 'both'),
                              child: Text(
                                ar ? 'الصوت والفيديو' : 'Audio and video',
                              ),
                            ),
                          ],
                        ),
                      );
                      if (scope == null || !context.mounted) return;
                      await manager.start(title, [
                        for (final item in stories.asData!.value)
                          for (final episode in item.episodes)
                            for (final media in episode.media.values)
                              if ((scope == 'both' ||
                                      scope == media.format.name) &&
                                  files.source(media) != null)
                                () => files.download(media),
                      ]);
                      if (context.mounted) ref.invalidate(lessonSavedProvider);
                    },
            ),
        ],
      ),
      body: stories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.learningMediaUnavailable)),
        data: (series) => RefreshIndicator(
          onRefresh: () => ref.refresh(prophetStoriesProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              ResponsiveContent(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CollectionDownloadStatus(),
                    const SizedBox(height: AppSpacing.md),
                    for (final story in series)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.auto_stories_outlined),
                          title: Text(story.title(language)),
                          subtitle: Text(
                            story.episodes.isEmpty
                                ? l10n.learningNoEpisodes
                                : l10n.learningEpisodeCount(
                                    story.episodes.length,
                                  ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) =>
                                  EpisodeSeriesScreen(series: story),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
