import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/audio/audio_playback.dart';
import '../../../core/content/app_settings.dart';
import '../../../core/content/feature_preview.dart';
import '../../../core/content/managed_library.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/madar_panel.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../core/widgets/settings_button.dart';
import '../../names/names_screen.dart';
import '../../worship/application/cairo_radio_control.dart';
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
    final radio =
        ref.watch(appSettingsProvider).shows(AppFeature.radio) &&
        entries.any((entry) => entry is BuiltinEntry && entry.id == 'radio');
    final settings = ref.watch(appSettingsProvider);
    final tiles = [
      for (final entry in entries)
        if (!(entry is BuiltinEntry &&
            ((entry.id == 'hadith' && !settings.shows(AppFeature.hadith)) ||
                (entry.id == 'stories' &&
                    !settings.shows(AppFeature.stories)))))
          ?_tile(context, entry, feed),
      if (settings.shows(AppFeature.zakat))
        _LibraryTile(
          key: const ValueKey('library-zakat'),
          route: AppRoutes.zakat,
          push: true,
          icon: Icons.calculate_outlined,
          title: l10n.zakatTitle,
          subtitle: l10n.zakatSubtitle,
          tone: 1,
        ),
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
      body: MadarBackdrop(
        child: CustomScrollView(
          slivers: [
            SliverResponsiveContent(
              sliver: SliverList.list(
                children: [
                  Center(
                    child: Image.asset(
                      'assets/brand/book-${theme.brightness == Brightness.dark ? 'dark' : 'light'}.png',
                      height: 176,
                      width: 286,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                  ),
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
                  mainAxisExtent: MediaQuery.textScalerOf(context).scale(130),
                ),
                itemCount: tiles.length,
                itemBuilder: (context, index) => tiles[index],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          ],
        ),
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
    // Shown once the dashboard publishes the names.
    BuiltinEntry(id: 'names') when divineNamesFrom(feed).isNotEmpty =>
      _LibraryTile(
        key: const ValueKey('library-names'),
        route: AppRoutes.names,
        icon: Icons.auto_awesome_outlined,
        title: l10n.namesTitle,
        subtitle: l10n.namesSubtitle,
        tone: 2,
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
class _RadioBanner extends ConsumerWidget {
  const _RadioBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(audioPlaybackProvider);
    final on = cairoRadioOn(playback);
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return MadarPanel(
      key: const ValueKey('library-radio'),
      radius: BorderRadius.circular(23),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xffff7959), Color(0xffd93f23)],
      ),
      onTap: () => toggleCairoRadio(context, ref),
      child: Row(
        children: [
          CircleAvatar(
            key: const Key('library-radio-play'),
            radius: 23,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xffd93f23),
            child: cairoRadioConnecting(playback)
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Color(0xffd93f23),
                    ),
                  )
                : Icon(
                    on ? Icons.stop_rounded : Icons.play_arrow_outlined,
                    size: 25,
                    semanticLabel: on ? l10n.radioStop : l10n.radioPlay,
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.libraryLive,
                  style: text.labelMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.radioTitle,
                  style: text.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    return MadarPanel(
      radius: const BorderRadiusDirectional.only(
        topStart: Radius.circular(20),
        topEnd: Radius.circular(20),
        bottomStart: Radius.circular(20),
        bottomEnd: Radius.circular(6),
      ),
      onTap: () => push ? context.push(route) : context.go(route),
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MadarPanel(
            radius: AppRadii.mdAll,
            padding: const EdgeInsets.all(9),
            child: Icon(
              icon,
              size: 20,
              color: tone.isEven ? scheme.primary : scheme.secondary,
            ),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
