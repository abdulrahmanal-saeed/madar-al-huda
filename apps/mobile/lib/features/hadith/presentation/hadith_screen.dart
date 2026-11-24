import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/content/feature_preview.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../../core/localization/search_text.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../core/widgets/section_detail_scaffold.dart';
import '../data/hadeeth_enc.dart';
import '../data/hadith_favorites.dart';
import '../domain/hadith_grade.dart';

String _language(BuildContext context) =>
    Localizations.localeOf(context).languageCode;

String _count(BuildContext context, int count) => context.l10n.hadithCount(
  decimalFormat(_language(context)).format(count),
  count,
);

IconData _topicIcon(String id) => switch (id) {
  '1' => Icons.menu_book_outlined,
  '2' => Icons.auto_stories_outlined,
  '3' => Icons.wb_sunny_outlined,
  '4' => Icons.balance_outlined,
  '5' => Icons.volunteer_activism_outlined,
  '6' => Icons.campaign_outlined,
  '7' => Icons.history_edu_outlined,
  _ => Icons.topic_outlined,
};

/// Hadith library backed by the publisher's HadeethEnc API, kept on the
/// device once read.
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
    final language = _language(context);
    final catalog = hadithCatalogProvider(language);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final favorites = ref.watch(hadithFavoritesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sectionHadithTitle),
        actions: [
          IconButton(
            tooltip: l10n.hadithFavoritesTitle,
            onPressed: () => _open(context, const _HadithFavoritesScreen()),
            icon: Badge(
              isLabelVisible: favorites.isNotEmpty,
              label: Text(decimalFormat(language).format(favorites.length)),
              child: const Icon(Icons.favorite_border),
            ),
          ),
        ],
      ),
      body: ref
          .watch(catalog)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                _HadithUnavailable(onRetry: () => ref.invalidate(catalog)),
            data: (data) {
              final needle = normalizeSearch(_query);
              final matches = needle.isEmpty
                  ? const <HadithCategory>[]
                  : data.categories
                        .where(
                          (category) =>
                              normalizeSearch(category.title).contains(needle),
                        )
                        .toList();
              return CustomScrollView(
                slivers: [
                  SliverResponsiveContent(
                    sliver: SliverList.list(
                      children: [
                        TextFormField(
                          key: const Key('hadith-search'),
                          initialValue: _query,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: l10n.hadithSearchHint,
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(28),
                              ),
                            ),
                            isDense: true,
                          ),
                          onChanged: (value) => setState(() => _query = value),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (needle.isNotEmpty) ...[
                          if (matches.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Text(
                                l10n.hadithNoTopics,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          for (final category in matches.take(60))
                            _TopicTile(
                              category: category,
                              parent: data.byId(category.parentId),
                              catalog: data,
                            ),
                        ] else ...[
                          Text(
                            l10n.hadithTopicsTitle,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ],
                    ),
                  ),
                  if (needle.isEmpty)
                    SliverResponsiveContent(
                      sliver: SliverGrid.builder(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 240,
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisExtent: MediaQuery.textScalerOf(context)
                              .scale(150),
                        ),
                        itemCount: data.roots.length,
                        itemBuilder: (context, index) => _RootTopicCard(
                          category: data.roots[index],
                          index: index,
                          catalog: data,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xl),
                  ),
                ],
              );
            },
          ),
    );
  }
}

void _open(BuildContext context, Widget screen) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

void _openTopic(
  BuildContext context,
  HadithCategory category,
  HadithCatalog catalog,
) => _open(
  context,
  catalog.childrenOf(category.id).isEmpty
      ? HadithListScreen(category: category)
      : _TopicScreen(category: category, catalog: catalog),
);

class _RootTopicCard extends StatelessWidget {
  const _RootTopicCard({
    required this.category,
    required this.index,
    required this.catalog,
  });

  final HadithCategory category;
  final int index;
  final HadithCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (background, foreground) = switch (index % 3) {
      0 => (scheme.primaryContainer, scheme.onPrimaryContainer),
      1 => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      _ => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
    };
    return Card(
      key: ValueKey('hadith-topic-${category.id}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openTopic(context, category, catalog),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: background,
                foregroundColor: foreground,
                child: Icon(_topicIcon(category.id)),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  category.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _count(context, category.count),
                maxLines: 1,
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

class _TopicTile extends StatelessWidget {
  const _TopicTile({
    required this.category,
    required this.catalog,
    this.parent,
  });

  final HadithCategory category;
  final HadithCategory? parent;
  final HadithCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasChildren = catalog.childrenOf(category.id).isNotEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        key: ValueKey('hadith-subtopic-${category.id}'),
        leading: Icon(
          hasChildren ? Icons.folder_outlined : Icons.article_outlined,
          color: theme.colorScheme.primary,
        ),
        title: Text(category.title),
        subtitle: Text(
          [?parent?.title, _count(context, category.count)].join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openTopic(context, category, catalog),
      ),
    );
  }
}

class _TopicScreen extends StatelessWidget {
  const _TopicScreen({required this.category, required this.catalog});

  final HadithCategory category;
  final HadithCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final children = catalog.childrenOf(category.id);
    return Scaffold(
      appBar: AppBar(title: Text(category.title)),
      body: CustomScrollView(
        slivers: [
          SliverResponsiveContent(
            sliver: SliverList.list(
              children: [
                Card(
                  color: theme.colorScheme.primaryContainer,
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    key: const Key('hadith-all-in-topic'),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    leading: Icon(
                      category.isRoot
                          ? _topicIcon(category.id)
                          : Icons.library_books_outlined,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    title: Text(
                      l10n.hadithAllIn(category.title),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    subtitle: Text(
                      _count(context, category.count),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    onTap: () =>
                        _open(context, HadithListScreen(category: category)),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.hadithSubtopics, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                for (final child in children)
                  _TopicTile(category: child, catalog: catalog),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Every hadith of a topic, loading more as the list scrolls.
class HadithListScreen extends ConsumerStatefulWidget {
  const HadithListScreen({required this.category, super.key});

  final HadithCategory category;

  @override
  ConsumerState<HadithListScreen> createState() => _HadithListScreenState();
}

class _HadithListScreenState extends ConsumerState<HadithListScreen> {
  int _pages = 1;

  @override
  Widget build(BuildContext context) {
    final language = _language(context);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final numbers = decimalFormat(language);
    final favorites = ref.watch(hadithFavoritesProvider);
    final items = <HadithItem>[];
    var lastPage = 1;
    var total = widget.category.count;
    AsyncValue<HadithPage>? pending;
    ({String language, String category, int page}) query(int page) =>
        (language: language, category: widget.category.id, page: page);
    for (var page = 1; page <= _pages; page++) {
      final result = ref.watch(hadithPageProvider(query(page)));
      if (result case AsyncData(:final value)) {
        items.addAll(value.items);
        lastPage = value.lastPage;
        if (value.total > 0) total = value.total;
      } else {
        pending = result;
        break;
      }
    }
    final more = pending == null && _pages < lastPage;

    Widget footer() {
      if (pending case AsyncError()) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Text(
                items.isEmpty
                    ? l10n.hadithUnavailable
                    : l10n.hadithLoadMoreFailed,
              ),
              TextButton(
                onPressed: () =>
                    ref.invalidate(hadithPageProvider(query(_pages))),
                child: Text(l10n.readerRetry),
              ),
            ],
          ),
        );
      }
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.category.title, overflow: TextOverflow.ellipsis),
            Text(_count(context, total), style: theme.textTheme.bodySmall),
          ],
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        itemCount: items.length + (pending != null || more ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            if (more) {
              // The footer is built as it nears the screen: load the
              // next page then.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _pages < lastPage) setState(() => _pages++);
              });
            }
            return footer();
          }
          final item = items[index];
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.maxContentWidth,
              ),
              child: Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: ValueKey('hadith-${item.id}'),
                  onTap: () => _open(
                    context,
                    HadithReaderScreen(items: items, initial: index),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          foregroundColor:
                              theme.colorScheme.onSecondaryContainer,
                          child: Text(
                            numbers.format(index + 1),
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontFamily: language == 'ar'
                                  ? AppTheme.readingFontFamily
                                  : null,
                              fontSize: language == 'ar' ? 19 : null,
                              height: 1.6,
                            ),
                          ),
                        ),
                        if (favorites.contains(item.id))
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: AppSpacing.sm,
                            ),
                            child: Icon(
                              Icons.favorite,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Reads one hadith; swipe or use the arrows for the rest of its list.
class HadithReaderScreen extends StatefulWidget {
  const HadithReaderScreen({
    required this.items,
    required this.initial,
    super.key,
  });

  final List<HadithItem> items;
  final int initial;

  @override
  State<HadithReaderScreen> createState() => _HadithReaderScreenState();
}

class _HadithReaderScreenState extends State<HadithReaderScreen> {
  late final _pages = PageController(initialPage: widget.initial);
  late int _index = widget.initial;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int index) => _pages.animateToPage(
    index,
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeOutCubic,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final numbers = decimalFormat(_language(context));
    final count = widget.items.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sectionHadithTitle),
        actions: [
          if (count > 1)
            Center(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpacing.lg),
                child: Text(
                  l10n.hadithPosition(
                    numbers.format(_index + 1),
                    numbers.format(count),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pages,
        itemCount: count,
        onPageChanged: (index) => setState(() => _index = index),
        itemBuilder: (context, index) =>
            _HadithEntry(id: widget.items[index].id),
      ),
      bottomNavigationBar: count < 2
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _index > 0 ? () => _go(_index - 1) : null,
                        icon: const Icon(Icons.arrow_back),
                        label: Text(l10n.hadithPrevious),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _index < count - 1
                            ? () => _go(_index + 1)
                            : null,
                        // Arrow after the label, pointing the reading way.
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(l10n.hadithNext),
                      ),
                    ),
                  ],
                ),
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
    final language = _language(context);
    final source = hadithDetailProvider((language: language, id: id));
    return ref
        .watch(source)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              _HadithUnavailable(onRetry: () => ref.invalidate(source)),
          data: (hadith) => _HadithBody(hadith: hadith, language: language),
        );
  }
}

class _HadithBody extends ConsumerWidget {
  const _HadithBody({required this.hadith, required this.language});

  final HadithDetail hadith;
  final String language;

  String get _shareText => [
    hadith.arabicText ?? hadith.text,
    if (language != 'ar') hadith.text,
    [hadith.attribution, hadith.grade].where((s) => s.isNotEmpty).join(' · '),
    'hadeethenc.com/$language/browse/hadith/${hadith.id}',
  ].where((part) => part.isNotEmpty).join('\n\n');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final favorite = ref.watch(hadithFavoritesProvider).contains(hadith.id);
    final arabic = language == 'ar' ? hadith : null;
    final arabicText = language == 'ar' ? hadith.text : hadith.arabicText;
    final grade = hadithGrade(hadith.grade);
    final reading = theme.textTheme.bodyLarge?.copyWith(
      fontFamily: AppTheme.readingFontFamily,
      fontSize: 23,
      height: 1.9,
    );

    Widget section(String title, IconData icon, Widget child) => Card(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: scheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  hadith.title,
                  style: theme.textTheme.titleLarge?.copyWith(height: 1.5),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (hadith.grade.isNotEmpty)
                      Chip(
                        key: const Key('hadith-grade'),
                        avatar: Icon(
                          grade == HadithGrade.authentic
                              ? Icons.verified
                              : Icons.info_outline,
                          size: 18,
                          color: switch (grade) {
                            HadithGrade.authentic => scheme.primary,
                            HadithGrade.good => scheme.tertiary,
                            HadithGrade.other => scheme.onSurfaceVariant,
                          },
                        ),
                        label: Text(hadith.grade),
                      ),
                    if (hadith.attribution.isNotEmpty)
                      Chip(
                        avatar: const Icon(Icons.bookmark_outline, size: 18),
                        label: Text(hadith.attribution),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.55),
                    borderRadius: AppRadii.lgAll,
                    border: BorderDirectional(
                      start: BorderSide(color: scheme.primary, width: 4),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (arabic != null && arabic.intro.isNotEmpty) ...[
                          Text(
                            arabic.intro.trim(),
                            textDirection: TextDirection.rtl,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontFamily: AppTheme.readingFontFamily,
                              color: scheme.onSurfaceVariant,
                              height: 1.7,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                        ],
                        if (arabicText != null)
                          SelectableText(
                            arabic != null ? arabic.body : arabicText,
                            textDirection: TextDirection.rtl,
                            style: reading,
                          ),
                        if (language != 'ar') ...[
                          const Divider(height: AppSpacing.xl),
                          Text(
                            l10n.hadithTranslation,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          SelectableText(
                            hadith.text,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    IconButton.filledTonal(
                      key: const Key('hadith-favorite'),
                      tooltip: favorite
                          ? l10n.hadithRemoveFavorite
                          : l10n.hadithAddFavorite,
                      isSelected: favorite,
                      onPressed: () async {
                        try {
                          await ref
                              .read(hadithFavoritesProvider.notifier)
                              .toggle(hadith.id);
                        } on Object {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.localSaveFailed)),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.favorite_border),
                      selectedIcon: const Icon(Icons.favorite),
                    ),
                    IconButton(
                      tooltip: l10n.hadithCopy,
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: _shareText),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.hadithCopied)),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_outlined),
                    ),
                    IconButton(
                      tooltip: l10n.hadithShare,
                      onPressed: () async {
                        try {
                          await const MethodChannel('madar/share')
                              .invokeMethod<void>('shareText', _shareText);
                        } on Exception {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.readerShareFailed)),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.share_outlined),
                    ),
                  ],
                ),
                if (hadith.explanation.isNotEmpty)
                  section(
                    l10n.hadithExplanationTitle,
                    Icons.lightbulb_outline,
                    SelectableText(
                      hadith.explanation,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
                    ),
                  ),
                if (hadith.hints.isNotEmpty)
                  section(
                    l10n.hadithBenefits,
                    Icons.checklist,
                    Column(
                      children: [
                        for (final hint in hadith.hints)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 9),
                                  child: Icon(
                                    Icons.circle,
                                    size: 7,
                                    color: scheme.primary,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    hint,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                if (hadith.words.isNotEmpty)
                  section(
                    l10n.hadithWords,
                    Icons.translate,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final word in hadith.words)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${word.word}: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: scheme.primary,
                                    ),
                                  ),
                                  TextSpan(text: word.meaning),
                                ],
                              ),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                height: 1.6,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (hadith.reference case final reference?
                    when reference.isNotEmpty)
                  Card(
                    margin: const EdgeInsets.only(top: AppSpacing.md),
                    clipBehavior: Clip.antiAlias,
                    child: ExpansionTile(
                      leading: Icon(
                        Icons.library_books_outlined,
                        color: scheme.primary,
                      ),
                      title: Text(l10n.hadithSourceTitle),
                      shape: const Border(),
                      childrenPadding: const EdgeInsetsDirectional.fromSTEB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          reference,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HadithFavoritesScreen extends ConsumerWidget {
  const _HadithFavoritesScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(hadithFavoritesProvider).toList();
    final language = _language(context);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.hadithFavoritesTitle)),
      body: ids.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.hadithNoFavorites, textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: ids.length,
              itemBuilder: (context, index) {
                final id = ids[index];
                final entry = ref.watch(
                  hadithDetailProvider((language: language, id: id)),
                );
                final title = entry.asData?.value.title;
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    leading: Icon(
                      Icons.favorite,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(title ?? '…', maxLines: 3),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(
                      context,
                      HadithReaderScreen(
                        items: [for (final id in ids) (id: id, title: '')],
                        initial: index,
                      ),
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
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(context.l10n.hadithUnavailable, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.tonal(
            onPressed: onRetry,
            child: Text(context.l10n.readerRetry),
          ),
        ],
      ),
    ),
  );
}
