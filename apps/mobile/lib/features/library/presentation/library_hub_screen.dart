import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/content/feature_preview.dart';
import '../../../core/content/managed_library.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../core/widgets/settings_button.dart';
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
    final theme = Theme.of(context);
    final feed = managedReleaseEnabled
        ? ref.watch(managedLibraryProvider).asData?.value
        : null;
    // Order and visibility come from the dashboard's «أقسام المكتبة» page;
    // the app's own order applies until then.
    final entries = ref.watch(librarySectionsProvider);
    final radio = entries.any(
      (entry) => entry is BuiltinEntry && entry.id == 'radio',
    );
    final tiles = [
      for (final entry in entries) ?_tile(context, entry, feed),
      if (managedReleaseEnabled)
        _LibraryTile(
          key: const ValueKey('library-downloads'),
          route: AppRoutes.downloads,
          push: true,
          icon: Icons.download_for_offline_outlined,
          title: l10n.downloadsTitle,
          subtitle: l10n.downloadsSettingsSubtitle,
          tone: 2,
        ),
    ];
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
                if (radio) ...[
                  const _RadioBanner(),
                  const SizedBox(height: AppSpacing.lg),
                ],
                Text(l10n.libraryBrowse, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
          SliverResponsiveContent(
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                mainAxisExtent: MediaQuery.textScalerOf(context).scale(164),
              ),
              itemCount: tiles.length,
              itemBuilder: (context, index) => tiles[index],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        ],
      ),
    );
  }
}

Widget? _tile(
  BuildContext context,
  LibraryEntry entry,
  Map<String, Object?>? feed,
) {
  final l10n = context.l10n;
  final language = Localizations.localeOf(context).languageCode;
  Widget section(AppSection section, int tone) => _LibraryTile(
    key: ValueKey('section-card-$section'),
    route: section.path,
    icon: section.icon,
    title: section.title(l10n),
    subtitle: section.subtitle(l10n),
    tone: tone,
  );
  return switch (entry) {
    LinksEntry(:final id, :final title, :final subtitle) => _LibraryTile(
      key: ValueKey('library-section-$id'),
      route: AppRoutes.librarySection(id),
      icon: Icons.video_library_outlined,
      title: title.inLanguage(language),
      subtitle: subtitle?.inLanguage(language) ?? '',
      tone: 1,
    ),
    BuiltinEntry(id: 'duas') => _LibraryTile(
      route: AppRoutes.quranDuas,
      icon: Icons.volunteer_activism_outlined,
      title: l10n.duaTitle,
      subtitle: l10n.sectionAdhkarTitle,
      tone: 0,
    ),
    BuiltinEntry(id: 'hadith') => section(AppSection.hadith, 1),
    BuiltinEntry(id: 'fiqh')
        when LibraryHubScreen._published(AppSection.fiqh, feed) =>
      section(AppSection.fiqh, 2),
    BuiltinEntry(id: 'articles')
        when LibraryHubScreen._published(AppSection.articles, feed) =>
      section(AppSection.articles, 0),
    BuiltinEntry(id: 'stories') => section(AppSection.stories, 1),
    BuiltinEntry(id: 'lessons')
        when LibraryHubScreen._published(AppSection.lessons, feed) =>
      section(AppSection.lessons, 2),
    _ => null,
  };
}

/// The live Quran radio as a banner at the top of the library.
class _RadioBanner extends StatelessWidget {
  const _RadioBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return Material(
      key: const ValueKey('library-radio'),
      borderRadius: AppRadii.xlAll,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [BrandColors.primaryGreen, BrandColors.heroGreenEnd],
          ),
        ),
        child: InkWell(
          onTap: () => context.push(AppRoutes.cairoRadio),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: BrandColors.goldBright.withValues(alpha: 0.2),
                          borderRadius: AppRadii.lgAll,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.circle,
                                size: 8,
                                color: BrandColors.goldBright,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                l10n.libraryLive,
                                style: text.labelMedium?.copyWith(
                                  color: BrandColors.goldBright,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.radioTitle,
                        style: text.titleMedium?.copyWith(
                          color: BrandColors.ivory,
                        ),
                      ),
                      Text(
                        l10n.radioCairo,
                        style: text.bodySmall?.copyWith(
                          color: BrandColors.ivory.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: BrandColors.goldBright,
                  foregroundColor: BrandColors.primaryGreen,
                  child: Icon(Icons.play_arrow_rounded, size: 34),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryTile extends StatelessWidget {
  const _LibraryTile({
    required this.route,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.tone = 0,
    this.push = false,
    super.key,
  });

  final String route;
  final IconData icon;
  final String title;
  final String subtitle;
  final int tone;
  final bool push;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (background, foreground) = switch (tone % 3) {
      0 => (scheme.primaryContainer, scheme.onPrimaryContainer),
      1 => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      _ => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
    };
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => push ? context.push(route) : context.go(route),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: AppRadii.lgAll,
                ),
                child: Icon(icon, color: foreground),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
