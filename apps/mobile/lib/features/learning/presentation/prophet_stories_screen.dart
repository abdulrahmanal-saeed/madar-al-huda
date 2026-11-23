import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/content/feature_preview.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../core/widgets/section_detail_scaffold.dart';
import '../data/learning_catalog.dart';
import 'episode_series_screen.dart';

class ProphetStoriesScreen extends ConsumerWidget {
  const ProphetStoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (AppSection.stories.status.isGated && !featurePreviewEnabled) {
      return const SectionDetailScaffold(section: AppSection.stories);
    }
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final stories = ref.watch(prophetStoriesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sectionStoriesTitle)),
      body: stories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.learningMediaUnavailable)),
        data: (series) => ListView(
          children: [
            ResponsiveContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                            builder: (_) => EpisodeSeriesScreen(series: story),
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
    );
  }
}
