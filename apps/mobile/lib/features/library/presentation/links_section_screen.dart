import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/responsive_content.dart';
import '../domain/library_sections.dart';

/// A section added on the dashboard: its titled links open in an in-app
/// browser view (videos play there), or in the browser as a fallback.
class LinksSectionScreen extends ConsumerWidget {
  const LinksSectionScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final entry = ref
        .watch(librarySectionsProvider)
        .whereType<LinksEntry>()
        .where((entry) => entry.id == id)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(entry?.title.inLanguage(language) ?? '')),
      body: entry == null || entry.links.isEmpty
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
