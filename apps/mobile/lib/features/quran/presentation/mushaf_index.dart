import 'dart:async';

import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/l10n_extension.dart';
import '../data/mushaf_edition.dart';
import '../domain/quran_search_text.dart';
import '../domain/quran_storage_contracts.dart';

enum _Index { surahs, juzs, hizbs, pages, bookmarks, search }

class MushafIndex extends StatefulWidget {
  const MushafIndex({
    super.key,
    required this.edition,
    required this.bookmarks,
    required this.current,
  });

  final MushafEdition edition;
  final List<QuranBookmark> bookmarks;
  final AyahRef current;

  @override
  State<MushafIndex> createState() => _MushafIndexState();
}

class _MushafIndexState extends State<MushafIndex> {
  _Index _index = _Index.surahs;
  String _query = '';
  String _page = '';
  bool _invalidPage = false;
  final _searchInput = TextEditingController();
  Timer? _searchDelay;

  /// Search text for every verse, normalized once instead of on every
  /// keystroke (6,236 verses).
  late final List<String> _verseSearchText = [
    for (final verse in widget.edition.verses) quranSearchText(verse.text),
  ];
  late final List<(int, String, String)> _surahSearchText = [
    for (final surah in widget.edition.surahs)
      (
        surah.id,
        quranSearchText(surah.arabicName),
        quranSearchText(surah.englishName),
      ),
  ];

  @override
  void dispose() {
    _searchDelay?.cancel();
    _searchInput.dispose();
    super.dispose();
  }

  void _openPage() {
    final edition = widget.edition;
    final number = int.tryParse(quranSearchText(_page));
    if (number == null || number < 1 || number > edition.pageStarts.length) {
      setState(() => _invalidPage = true);
      return;
    }
    Navigator.pop(context, edition.verses[edition.pageStarts[number - 1]].ref);
  }

  List<MushafVerse> _results = [];

  /// Waits for a short pause in typing before searching.
  void _scheduleSearch(String text) {
    _searchDelay?.cancel();
    _searchDelay = Timer(const Duration(milliseconds: 200), () {
      if (mounted) _search(text);
    });
  }

  void _search(String text) {
    final query = quranSearchText(text);
    final edition = widget.edition;
    final key = RegExp(r'^(\d+):(\d+)$').firstMatch(query);
    Iterable<MushafVerse> results = const [];
    if (key != null) {
      final surah = int.tryParse(key[1]!);
      final ayah = int.tryParse(key[2]!);
      if (surah != null &&
          ayah != null &&
          surah >= 1 &&
          surah <= surahCount &&
          ayah >= 1 &&
          ayah <= edition.surahs[surah - 1].verses.length) {
        results = [edition.verses[edition.surahStarts[surah - 1] + ayah - 1]];
      }
    } else if (query.isNotEmpty) {
      final matchingSurahs = {
        for (final (id, arabic, english) in _surahSearchText)
          if (arabic.contains(query) || english.contains(query)) id,
      };
      final texts = _verseSearchText;
      results = [
        for (var i = 0; i < edition.verses.length; i++)
          if ((edition.verses[i].ref.ayah == 1 &&
                  matchingSurahs.contains(edition.verses[i].ref.surah)) ||
              texts[i].contains(query))
            edition.verses[i],
      ];
    }
    setState(() {
      _query = query;
      _index = query.isEmpty ? _Index.surahs : _Index.search;
      _results = results.take(150).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final numbers = NumberFormat.decimalPattern(language);
    final edition = widget.edition;
    final options = {
      _Index.surahs: l10n.readerSurahs,
      _Index.juzs: l10n.readerJuzs,
      _Index.hizbs: l10n.readerHizbs,
      _Index.pages: l10n.readerPages,
      _Index.bookmarks: l10n.readerBookmarks,
    };
    final starts = switch (_index) {
      _Index.surahs => edition.surahStarts,
      _Index.juzs => edition.juzStarts,
      _Index.hizbs => edition.hizbStarts,
      _Index.pages => edition.pageStarts,
      _Index.bookmarks || _Index.search => const <int>[],
    };
    final rows = switch (_index) {
      _Index.search => _results,
      _Index.bookmarks => [
        for (final bookmark in widget.bookmarks)
          if (edition.contains(bookmark.ref))
            edition.verses[edition.indexOf(bookmark.ref)],
      ],
      _ => [for (final start in starts) edition.verses[start]],
    };
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchInput,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: l10n.readerSearch,
              helperText: l10n.readerSearchHint,
              helperMaxLines: 2,
            ),
            onChanged: _scheduleSearch,
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.history),
            title: Text(l10n.readerLastPosition),
            subtitle: Text(
              l10n.readerPosition(
                edition.surahs[widget.current.surah - 1].name(language),
                numbers.format(widget.current.ayah),
                numbers.format(edition.pageOf(widget.current) + 1),
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pop(context, widget.current),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (final option in options.entries)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(option.value),
                    selected: _index == option.key,
                    onSelected: (_) {
                      _searchInput.clear();
                      setState(() => _index = option.key);
                    },
                  ),
                ),
            ],
          ),
        ),
        if (_index == _Index.pages)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.readerPageInput,
                      errorText: _invalidPage ? l10n.readerPageInvalid : null,
                    ),
                    onChanged: (value) => setState(() {
                      _page = value;
                      _invalidPage = false;
                    }),
                    onSubmitted: (_) => _openPage(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _openPage, child: Text(l10n.readerGo)),
              ],
            ),
          ),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(
                    _index == _Index.bookmarks
                        ? l10n.readerNoBookmarks
                        : _query.isEmpty
                        ? l10n.readerSearchHint
                        : l10n.readerNoResults,
                  ),
                )
              : ListView.builder(
                  key: ValueKey(_index),
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final verse = rows[index];
                    final ref = verse.ref;
                    final number = numbers.format(index + 1);
                    final surah = edition.surahs[ref.surah - 1].name(language);
                    final title = switch (_index) {
                      _Index.surahs => '$number. $surah',
                      _Index.juzs => l10n.readerJuzLabel(number),
                      _Index.hizbs => l10n.readerHizbLabel(number),
                      _Index.pages => l10n.readerPageLabel(number),
                      _ => '$surah · ${numbers.format(ref.ayah)}',
                    };
                    final subtitle = switch (_index) {
                      _Index.search || _Index.bookmarks => Text(
                        verse.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl,
                      ),
                      _Index.surahs => Text(
                        l10n.readerIndexVerseCount(
                          numbers.format(
                            edition.surahs[ref.surah - 1].verses.length,
                          ),
                        ),
                      ),
                      _ => Text('$surah · ${numbers.format(ref.ayah)}'),
                    };
                    return ListTile(
                      title: Text(title),
                      subtitle: subtitle,
                      trailing: _index == _Index.pages
                          ? null
                          : Text(
                              l10n.readerPageLabel(
                                numbers.format(edition.pageOf(ref) + 1),
                              ),
                            ),
                      onTap: () => Navigator.pop(context, ref),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
