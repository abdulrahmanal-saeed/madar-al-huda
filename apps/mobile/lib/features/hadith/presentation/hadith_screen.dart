import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/content/feature_preview.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_detail_scaffold.dart';
import '../data/hadeeth_enc.dart';
import '../data/hadith_favorites.dart';

/// Hadith library backed by the publisher's live HadeethEnc API.
class HadithScreen extends ConsumerStatefulWidget {
  const HadithScreen({super.key});

  @override
  ConsumerState<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends ConsumerState<HadithScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    if (AppSection.hadith.status.isGated && !managedReleaseEnabled) {
      return const SectionDetailScaffold(section: AppSection.hadith);
    }
    final language = Localizations.localeOf(context).languageCode;
    final categories = hadithCategoriesProvider(language);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sectionHadithTitle),
        actions: [
          IconButton(
            tooltip: l10n.hadithFavoritesTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const _HadithFavoritesScreen(),
              ),
            ),
            icon: const Icon(Icons.favorite_border),
          ),
        ],
      ),
      body: ref
          .watch(categories)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                _HadithUnavailable(onRetry: () => ref.invalidate(categories)),
            data: (items) {
              final matches = items
                  .where((item) => item.title.toLowerCase().contains(_query))
                  .toList();
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextFormField(
                      initialValue: _query,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        labelText: l10n.hadithSearchTopics,
                      ),
                      onChanged: (value) =>
                          setState(() => _query = value.trim().toLowerCase()),
                    ),
                  ),
                  Expanded(
                    child: matches.isEmpty
                        ? Center(child: Text(l10n.hadithNoTopics))
                        : ListView.builder(
                            itemCount: matches.length,
                            itemBuilder: (context, index) {
                              final category = matches[index];
                              return ListTile(
                                title: Text(category.title),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        _HadithCategory(category: category),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
    );
  }
}

class _HadithCategory extends ConsumerStatefulWidget {
  const _HadithCategory({required this.category});
  final HadithItem category;

  @override
  ConsumerState<_HadithCategory> createState() => _HadithCategoryState();
}

class _HadithCategoryState extends ConsumerState<_HadithCategory> {
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final numbers = NumberFormat.decimalPattern(language);
    final l10n = context.l10n;
    final source = hadithPageProvider((
      language: language,
      category: widget.category.id,
      page: _page,
    ));
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.title)),
      body: ref
          .watch(source)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                _HadithUnavailable(onRetry: () => ref.invalidate(source)),
            data: (data) => Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    key: ValueKey(_page),
                    itemCount: data.items.length,
                    itemBuilder: (context, index) {
                      final item = data.items[index];
                      return ListTile(
                        title: Text(item.title),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _HadithEntry(id: item.id),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: l10n.hadithPrevious,
                      onPressed: _page > 1
                          ? () => setState(() => _page--)
                          : null,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Text(l10n.readerPageLabel(numbers.format(_page))),
                    IconButton(
                      tooltip: l10n.hadithNext,
                      onPressed: _page < data.lastPage
                          ? () => setState(() => _page++)
                          : null,
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }
}

class _HadithEntry extends ConsumerWidget {
  const _HadithEntry({required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = Localizations.localeOf(context).languageCode;
    final l10n = context.l10n;
    final source = hadithDetailProvider((language: language, id: id));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sectionHadithTitle)),
      body: ref
          .watch(source)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                _HadithUnavailable(onRetry: () => ref.invalidate(source)),
            data: (hadith) {
              final theme = Theme.of(context);
              final favorite = ref.watch(hadithFavoritesProvider).contains(id);
              final arabic = language == 'ar'
                  ? hadith
                  : ref
                        .watch(hadithDetailProvider((language: 'ar', id: id)))
                        .asData
                        ?.value;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(hadith.title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Card(
                    color: theme.colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (arabic != null)
                            Text(
                              arabic.text,
                              textDirection: TextDirection.rtl,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontFamily: AppTheme.readingFontFamily,
                                fontSize: 23,
                                height: 1.75,
                              ),
                            ),
                          if (language != 'ar') ...[
                            const SizedBox(height: 8),
                            Text(hadith.text),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (hadith.grade.isNotEmpty)
                        Chip(
                          label: Text(l10n.hadithProviderGrade(hadith.grade)),
                        ),
                      if (hadith.attribution.isNotEmpty)
                        Chip(label: Text(hadith.attribution)),
                    ],
                  ),
                  if (hadith.reference case final reference?
                      when reference.isNotEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.hadithSourceTitle),
                      subtitle: Text(reference),
                    ),
                  if (hadith.explanation.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      l10n.hadithExplanationTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(hadith.explanation),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await ref
                            .read(hadithFavoritesProvider.notifier)
                            .toggle(id);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.localSaveFailed)),
                          );
                        }
                      }
                    },
                    icon: Icon(
                      favorite ? Icons.favorite : Icons.favorite_border,
                    ),
                    label: Text(
                      favorite
                          ? l10n.hadithRemoveFavorite
                          : l10n.hadithAddFavorite,
                    ),
                  ),
                  TextButton(
                    onPressed: () => launchUrl(
                      Uri.https(
                        'hadeethenc.com',
                        '/$language/browse/hadith/$id',
                      ),
                    ),
                    child: const Text('HadeethEnc'),
                  ),
                ],
              );
            },
          ),
    );
  }
}

class _HadithFavoritesScreen extends ConsumerWidget {
  const _HadithFavoritesScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(hadithFavoritesProvider).toList();
    final language = Localizations.localeOf(context).languageCode;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.hadithFavoritesTitle)),
      body: ids.isEmpty
          ? Center(child: Text(l10n.hadithNoFavorites))
          : ListView.builder(
              itemCount: ids.length,
              itemBuilder: (context, index) {
                final id = ids[index];
                final entry = ref.watch(
                  hadithDetailProvider((language: language, id: id)),
                );
                return ListTile(
                  leading: const Icon(Icons.favorite_border),
                  title: Text(entry.asData?.value.title ?? '#$id'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _HadithEntry(id: id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _HadithUnavailable extends StatelessWidget {
  const _HadithUnavailable({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.hadithUnavailable),
        TextButton(onPressed: onRetry, child: Text(context.l10n.readerRetry)),
      ],
    ),
  );
}
