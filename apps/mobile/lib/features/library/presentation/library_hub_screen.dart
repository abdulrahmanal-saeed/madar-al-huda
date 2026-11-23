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
import '../domain/library_sections.dart';

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
                // Order and visibility come from the dashboard's «أقسام
                // المكتبة» page; the app's own order applies until then.
                for (final entry in ref.watch(librarySectionsProvider))
                  ..._entry(context, entry, feed),
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

List<Widget> _entry(
  BuildContext context,
  LibraryEntry entry,
  Map<String, Object?>? feed,
) {
  final l10n = context.l10n;
  final language = Localizations.localeOf(context).languageCode;
  Widget tile(AppSection section) => _LibraryTile(
    key: ValueKey('section-card-$section'),
    route: section.path,
    icon: section.icon,
    title: section.title(l10n),
    subtitle: section.subtitle(l10n),
  );
  return switch (entry) {
    LinksEntry(:final id, :final title, :final subtitle) => [
      _LibraryTile(
        key: ValueKey('library-section-$id'),
        route: AppRoutes.librarySection(id),
        icon: Icons.video_library_outlined,
        title: title.inLanguage(language),
        subtitle: subtitle?.inLanguage(language) ?? '',
      ),
    ],
    BuiltinEntry(id: 'radio') => const [
      CairoRadioCard(),
      SizedBox(height: AppSpacing.md),
    ],
    BuiltinEntry(id: 'duas') => [
      _LibraryTile(
        route: AppRoutes.quranDuas,
        icon: Icons.volunteer_activism_outlined,
        title: l10n.duaTitle,
        subtitle: l10n.sectionAdhkarTitle,
      ),
    ],
    BuiltinEntry(id: 'hadith') => [tile(AppSection.hadith)],
    BuiltinEntry(id: 'fiqh') => [
      if (LibraryHubScreen._published(AppSection.fiqh, feed))
        tile(AppSection.fiqh),
    ],
    BuiltinEntry(id: 'articles') => [
      if (LibraryHubScreen._published(AppSection.articles, feed))
        tile(AppSection.articles),
    ],
    BuiltinEntry(id: 'stories') => [
      const SizedBox(height: AppSpacing.lg),
      _LibraryCollection(
        title: l10n.libraryStories,
        section: AppSection.stories,
      ),
    ],
    BuiltinEntry(id: 'lessons') => [
      if (LibraryHubScreen._published(AppSection.lessons, feed)) ...[
        const SizedBox(height: AppSpacing.md),
        _LibraryCollection(
          title: l10n.libraryAcademy,
          section: AppSection.lessons,
        ),
      ],
    ],
    BuiltinEntry() => const [],
  };
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
