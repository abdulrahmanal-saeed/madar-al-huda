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
  });

  final MushafEdition edition;
  final List<QuranBookmark> bookmarks;

  @override
  State<MushafIndex> createState() => _MushafIndexState();
}

class _MushafIndexState extends State<MushafIndex> {
  _Index _index = _Index.surahs;
  String _query = '';
  List<MushafVerse> _results = [];
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
        for (final surah in edition.surahs)
          if (quranSearchText(surah.arabicName).contains(query) ||
              quranSearchText(surah.englishName).contains(query))
            surah.id,
      };
      results = edition.verses.where(
        (verse) =>
            (verse.ref.ayah == 1 && matchingSurahs.contains(verse.ref.surah)) ||
            quranSearchText(verse.text).contains(query),
      );
    }
    setState(() {
      _query = query;
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
      _Index.search: l10n.readerSearch,
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
          child: DropdownButton<_Index>(
            isExpanded: true,
            value: _index,
            items: [
              for (final option in options.entries)
                DropdownMenuItem(value: option.key, child: Text(option.value)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _index = value);
            },
          ),
        ),
        if (_index == _Index.search)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextFormField(
              initialValue: _query,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: l10n.readerSearchHint,
              ),
              onChanged: _search,
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
                      _Index.surahs => null,
                      _ => Text('$surah · ${numbers.format(ref.ayah)}'),
                    };
                    return ListTile(
                      title: Text(title),
                      subtitle: subtitle,
                      onTap: () => Navigator.pop(context, ref),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
