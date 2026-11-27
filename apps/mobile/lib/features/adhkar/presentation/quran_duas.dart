import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/app_locales.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../quran/data/local_quran_bookmarks.dart';
import '../../quran/data/mushaf_edition.dart';
import '../../quran/domain/quran_search_text.dart';
import '../../quran/domain/quran_storage_contracts.dart';
import '../../quran/presentation/basmala_line.dart';
import '../../quran/presentation/quran_meaning_view.dart';
import '../data/adhkar_catalog.dart';
import '../data/quran_dua_index.dart';
import 'adhkar_widgets.dart';

extension on DuaTopic {
  String title(AppLocalizations l10n) => switch (this) {
    DuaTopic.forgiveness => l10n.duaTopicForgiveness,
    DuaTopic.guidance => l10n.duaTopicGuidance,
    DuaTopic.family => l10n.duaTopicFamily,
    DuaTopic.hardship => l10n.duaTopicHardship,
    DuaTopic.gratitude => l10n.duaTopicGratitude,
    DuaTopic.worship => l10n.duaTopicWorship,
    DuaTopic.hereafter => l10n.duaTopicHereafter,
    DuaTopic.protection => l10n.duaTopicProtection,
  };
}

class QuranDuas extends ConsumerStatefulWidget {
  const QuranDuas({super.key});

  @override
  ConsumerState<QuranDuas> createState() => _QuranDuasState();
}

class _QuranDuasState extends ConsumerState<QuranDuas> {
  DuaTopic? _topic;
  var _query = '';
  var _savedOnly = false;

  AyahRef _reference(DuaRange range) => AyahRef(
    editionId: MushafEdition.id,
    surah: range.surah,
    ayah: range.first,
  );

  Future<void> _save(DuaRange range, QuranBookmark? bookmark) async {
    try {
      final store = ref.read(quranBookmarksProvider);
      if (bookmark == null) {
        await store.add(_reference(range));
      } else {
        await store.remove(bookmark.id);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.localSaveFailed)));
      }
    }
  }

  bool _matches(
    MushafSurah surah,
    DuaTopic topic,
    DuaRange range,
    AppLocalizations l10n,
  ) {
    if (_query.isEmpty) return true;
    final reference = RegExp(r'^(\d+)\s*:\s*(\d+)$').firstMatch(_query);
    if (reference != null) {
      final ayah = int.tryParse(reference[2]!);
      return int.tryParse(reference[1]!) == range.surah &&
          ayah != null &&
          ayah >= range.first &&
          ayah <= range.last;
    }
    return quranSearchText(surah.arabicName).contains(_query) ||
        quranSearchText(surah.englishName).contains(_query) ||
        quranSearchText(topic.title(l10n)).contains(_query) ||
        quranSearchText(
          surah.verses.sublist(range.first - 1, range.last).join(' '),
        ).contains(_query);
  }

  Widget _list(MushafEdition edition, Map<DuaTopic, List<DuaRange>> index) {
    final l10n = context.l10n;
    final bookmarks = {
      for (final item
          in ref.watch(quranBookmarkListProvider).asData?.value ??
              const <QuranBookmark>[])
        item.ref: item,
    };
    final rows = [
      for (final entry in index.entries)
        if (_topic == null || _topic == entry.key)
          for (final range in entry.value)
            if ((!_savedOnly || bookmarks.containsKey(_reference(range))) &&
                _matches(
                  edition.surahs[range.surah - 1],
                  entry.key,
                  range,
                  l10n,
                ))
              (topic: entry.key, range: range),
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: TextField(
            decoration: InputDecoration(
              labelText: l10n.duaSearch,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (value) =>
                setState(() => _query = quranSearchText(value)),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              for (final topic in [null, ...DuaTopic.values])
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: ChoiceChip(
                    label: Text(topic?.title(l10n) ?? l10n.duaTopics),
                    selected: _topic == topic,
                    onSelected: (_) => setState(() => _topic = topic),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
            itemCount: rows.length + 1,
            itemBuilder: (context, index) {
              if (index == rows.length) {
                return Column(
                  children: [
                    if (rows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(l10n.duaNoResults),
                      ),
                  ],
                );
              }
              final row = rows[index];
              final bookmark = bookmarks[_reference(row.range)];
              return _DuaCard(
                key: ValueKey(row.range),
                edition: edition,
                topic: row.topic,
                range: row.range,
                isSaved: bookmark != null,
                onSave: () => _save(row.range, bookmark),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final source = ref.watch(mushafEditionProvider);
    final duas = ref.watch(quranDuaIndexProvider);
    return AdhkarPage(
      title: l10n.duaTitle,
      actions: [
        IconButton(
          tooltip: _savedOnly ? l10n.duaShowAll : l10n.duaShowSaved,
          isSelected: _savedOnly,
          icon: const Icon(Icons.bookmarks_outlined),
          selectedIcon: const Icon(Icons.bookmarks),
          onPressed: () => setState(() => _savedOnly = !_savedOnly),
        ),
      ],
      body: source.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(mushafEditionProvider),
            child: Text(l10n.readerRetry),
          ),
        ),
        data: (edition) => duas.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(quranDuaIndexProvider),
              child: Text(l10n.readerRetry),
            ),
          ),
          data: (index) => _list(edition, index),
        ),
      ),
    );
  }
}

class _DuaCard extends StatefulWidget {
  const _DuaCard({
    required super.key,
    required this.edition,
    required this.topic,
    required this.range,
    required this.isSaved,
    required this.onSave,
  });

  final MushafEdition edition;
  final DuaTopic topic;
  final DuaRange range;
  final bool isSaved;
  final VoidCallback onSave;

  @override
  State<_DuaCard> createState() => _DuaCardState();
}

class _DuaCardState extends State<_DuaCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final numbers = decimalFormat(language);
    final range = widget.range;
    final surah = widget.edition.surahs[range.surah - 1];
    final basmala = widget.edition.openingBasmala(range.surah, range.first);
    final first = numbers.format(range.first);
    final last = numbers.format(range.last);
    return Card(
      child: ExpansionTile(
        title: Text(surah.name(language)),
        subtitle: Text(
          '${widget.topic.title(l10n)} · ${first == last ? first : '$first–$last'}',
        ),
        onExpansionChanged: (expanded) => setState(() => _expanded = expanded),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          if (basmala != null) BasmalaLine(basmala),
          for (var index = range.first - 1; index < range.last; index++)
            Text(
              MushafEdition.withoutOpeningBasmala(
                surah.verses[index],
                index == range.first - 1 ? basmala : null,
              ),
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: AppTheme.quranFontFamily,
                fontSize: 24,
                height: 1.85,
              ),
            ),
          if (_expanded && language == 'en')
            QuranMeaningView(
              surah: range.surah,
              first: range.first,
              last: range.last,
              count: surah.verses.length,
            ),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => context.go(
                  Uri(
                    path: AppRoutes.quran,
                    queryParameters: {
                      'surah': '${range.surah}',
                      'ayah': '${range.first}',
                    },
                  ).toString(),
                ),
                icon: const Icon(Icons.menu_book_outlined),
                label: Text(l10n.duaOpenVerse),
              ),
              IconButton(
                tooltip: widget.isSaved
                    ? l10n.readerRemoveBookmark
                    : l10n.readerAddBookmark,
                onPressed: widget.onSave,
                icon: Icon(
                  widget.isSaved ? Icons.bookmark : Icons.bookmark_border,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
