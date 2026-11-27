import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../learning/presentation/episode_series_screen.dart';
import '../domain/library_sections.dart';

/// A section added on the dashboard: its titled links open in an in-app
/// browser view (videos play there), or in the browser as a fallback.
class LinksSectionScreen extends ConsumerWidget {
  const LinksSectionScreen({
    required this.id,
    this.seasonId,
    this.episodeNumber,
    super.key,
  });

  final String id;
  final String? seasonId;
  final int? episodeNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final entry = ref
        .watch(librarySectionsProvider)
        .whereType<LinksEntry>()
        .where((entry) => entry.id == id)
        .firstOrNull;
    final requested = entry?.seasons
        .where((season) => season.id == seasonId)
        .firstOrNull;
    if (requested != null) {
      return EpisodeSeriesScreen(
        series: requested,
        highlightedEpisode: episodeNumber,
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(entry?.title.inLanguage(language) ?? '')),
      body: entry == null || (entry.links.isEmpty && entry.seasons.isEmpty)
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  l10n.librarySectionEmpty,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              children: [
                ResponsiveContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (entry.subtitle case final subtitle?) ...[
                        Text(
                          subtitle.inLanguage(language),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      for (final season in entry.seasons)
                        Card(
                          child: ListTile(
                            key: ValueKey(season.id),
                            leading: const Icon(Icons.folder_open_outlined),
                            title: Text(season.title(language)),
                            subtitle: Text(
                              l10n.learningEpisodeCount(
                                decimalFormat(language)
                                    .format(season.episodes.length),
                                season.episodes.length,
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (_) =>
                                    EpisodeSeriesScreen(series: season),
                              ),
                            ),
                          ),
                        ),
                      if (entry.links.isNotEmpty)
                        Card(
                          child: Column(
                            children: [
                              for (final (index, link) in entry.links.indexed)
                                ListTile(
                                  key: ValueKey('section-link-$index'),
                                  leading: Icon(_iconFor(link.url)),
                                  title: Text(link.title.inLanguage(language)),
                                  trailing: const Icon(Icons.open_in_new),
                                  onTap: () => _open(context, link.url),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  static IconData _iconFor(Uri url) {
    final path = url.path.toLowerCase();
    if (path.endsWith('.mp4') ||
        url.host.contains('youtube.') ||
        url.host == 'youtu.be') {
      return Icons.play_circle_outline;
    }
    if (path.endsWith('.mp3')) return Icons.headphones_outlined;
    return Icons.article_outlined;
  }

  static Future<void> _open(BuildContext context, Uri url) async {
    final failed = context.l10n.librarySectionOpenFailed;
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (await launchUrl(url, mode: LaunchMode.inAppBrowserView)) return;
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) return;
    } on Object {
      // Falls through to the message below.
    }
    messenger.showSnackBar(SnackBar(content: Text(failed)));
  }
}
