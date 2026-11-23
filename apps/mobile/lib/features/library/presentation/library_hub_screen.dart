import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/content/collection_downloads.dart';
import '../../../core/content/feature_preview.dart';
import '../../../core/content/managed_library.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../core/widgets/settings_button.dart';
import '../../adhkar/data/adhkar_catalog.dart';
import '../../worship/presentation/cairo_radio_card.dart';

class LibraryHubScreen extends StatelessWidget {
  const LibraryHubScreen({super.key});

  static const sections = [
    AppSection.hadith,
    AppSection.fiqh,
    AppSection.articles,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                if (managedReleaseEnabled) const _SaveLibrary(),
                for (final section in sections)
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
                const SizedBox(height: AppSpacing.md),
                _LibraryCollection(
                  title: l10n.libraryAcademy,
                  section: AppSection.lessons,
                ),
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

class _SaveLibrary extends ConsumerWidget {
  const _SaveLibrary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final busy = ref.watch(collectionDownloadsProvider)?.running ?? false;
    final label = ar ? 'تنزيل محتوى المكتبة' : 'Download library content';
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: Text(label),
          subtitle: Text(
            ar
                ? 'المحتوى النصّي والأدعية والأذكار'
                : 'Articles, lessons, supplications and remembrance',
          ),
          enabled: !busy,
          onTap: () {
            final manager = ref.read(collectionDownloadsProvider.notifier);
            unawaited(
              manager.start(label, [
                () async {
                  if (await ref.refresh(managedLibraryProvider.future) ==
                      null) {
                    throw StateError('Hosted library is unavailable');
                  }
                },
                () async => ref.refresh(adhkarCatalogProvider.future),
              ]),
            );
          },
        ),
        const CollectionDownloadStatus(),
      ],
    );
  }
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
