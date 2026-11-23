import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/content/feature_preview.dart';
import '../../../core/content/managed_library.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../core/widgets/settings_button.dart';
import '../../worship/presentation/cairo_radio_card.dart';

class LibraryHubScreen extends ConsumerWidget {
  const LibraryHubScreen({super.key});

  static const sections = [
    AppSection.hadith,
    AppSection.fiqh,
    AppSection.articles,
  ];

  /// Sections whose content comes only from the published library feed.
  static const _managed = {
    AppSection.fiqh,
    AppSection.articles,
    AppSection.lessons,
  };

  /// Hides a managed section once the feed is known and has nothing
  /// published for it, so the library never opens onto an empty screen.
  /// Without a feed (offline, first launch) the entry stays and its screen
  /// explains that the content could not be loaded.
  static bool _published(AppSection section, Map<String, Object?>? feed) {
    if (!managedReleaseEnabled || feed == null) return true;
    if (!_managed.contains(section)) return true;
    final library = feed['library'];
    final rows = library is Map ? library[section.name] : null;
    return rows is List && rows.isNotEmpty;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final feed = managedReleaseEnabled
        ? ref.watch(managedLibraryProvider).asData?.value
        : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navLibrary),
        actions: const [SettingsButton()],
      ),
      body: CustomScrollView(
        slivers: [
          SliverResponsiveContent(
            sliver: SliverList.list(
              children: [
                const CairoRadioCard(),
                const SizedBox(height: AppSpacing.md),
                _LibraryTile(
                  route: AppRoutes.quranDuas,
                  icon: Icons.volunteer_activism_outlined,
                  title: l10n.duaTitle,
                  subtitle: l10n.sectionAdhkarTitle,
                ),
                for (final section in sections)
                  if (_published(section, feed))
                    _LibraryTile(
                      key: ValueKey('section-card-$section'),
                      route: section.path,
                      icon: section.icon,
                      title: section.title(l10n),
                      subtitle: section.subtitle(l10n),
                    ),
                const SizedBox(height: AppSpacing.lg),
                _LibraryCollection(
                  title: l10n.libraryStories,
                  section: AppSection.stories,
                ),
                if (_published(AppSection.lessons, feed)) ...[
                  const SizedBox(height: AppSpacing.md),
                  _LibraryCollection(
                    title: l10n.libraryAcademy,
                    section: AppSection.lessons,
                  ),
                ],
                if (managedReleaseEnabled) ...[
                  const SizedBox(height: AppSpacing.md),
                  Card(
                    child: ListTile(
                      key: const ValueKey('library-downloads'),
                      leading: const Icon(Icons.download_for_offline_outlined),
                      title: Text(l10n.downloadsTitle),
                      subtitle: Text(l10n.downloadsSettingsSubtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(AppRoutes.downloads),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryCollection extends StatelessWidget {
  const _LibraryCollection({required this.title, required this.section});

  final String title;
  final AppSection section;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        trailing: TextButton(
          onPressed: () => context.go(section.path),
          child: Text(context.l10n.libraryMore),
        ),
      ),
      _LibraryTile(
        route: section.path,
        icon: section.icon,
        title: section.title(context.l10n),
        subtitle: section.subtitle(context.l10n),
      ),
    ],
  );
}

class _LibraryTile extends StatelessWidget {
  const _LibraryTile({
    required this.route,
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String route;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        child: Icon(icon),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go(route),
    ),
  );
}
