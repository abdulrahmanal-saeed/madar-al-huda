import '../../../core/localization/search_text.dart';
import '../../adhkar/data/adhkar_catalog.dart';
import '../../hadith/data/hadeeth_enc.dart';
import '../../quran/data/mushaf_edition.dart';
import '../../quran/domain/quran_search_text.dart';

/// A place in the app a search can open directly.
typedef SearchShortcut = ({String id, List<String> names});

typedef DhikrHit = ({DhikrGroup group, DhikrEntry entry});

class SearchResults {
  const SearchResults({
    this.shortcuts = const [],
    this.surahs = const [],
    this.verses = const [],
    this.versesTotal = 0,
    this.adhkar = const [],
    this.hadithTopics = const [],
  });

  final List<SearchShortcut> shortcuts;
  final List<MushafSurah> surahs;
  final List<MushafVerse> verses;

  /// Every matching verse, of which [verses] holds the first ones.
  final int versesTotal;
  final List<DhikrHit> adhkar;
  final List<HadithCategory> hadithTopics;

  bool get isEmpty =>
      shortcuts.isEmpty &&
      surahs.isEmpty &&
      versesTotal == 0 &&
      adhkar.isEmpty &&
      hadithTopics.isEmpty;
}

/// Searches the Quran, adhkar, hadith topics and the app's own sections,
/// all on the device. Texts are normalized once.
class GlobalSearchIndex {
  GlobalSearchIndex({
    required this.edition,
    required this.shortcuts,
    this.adhkar,
    this.hadith,
  }) : _verses = [
         for (final verse in edition.verses) quranSearchText(verse.text),
       ],
       _surahs = [
         for (final surah in edition.surahs)
           (
             quranSearchText(surah.arabicName),
             normalizeSearch(surah.englishName),
           ),
       ],
       _shortcuts = [
         for (final shortcut in shortcuts)
           [for (final name in shortcut.names) normalizeSearch(name)],
       ],
       _dhikr = [
         for (final group in adhkar?.groups ?? const <DhikrGroup>[])
           for (final entry in group.entries)
             (
               group: group,
               entry: entry,
               text: [
                 normalizeSearch(entry.title.ar),
                 normalizeSearch(entry.title.en),
                 normalizeSearch(group.title.ar),
                 normalizeSearch(group.title.en),
                 if (entry.wording case final wording?)
                   quranSearchText(wording),
               ],
             ),
       ];

  final MushafEdition edition;
  final List<SearchShortcut> shortcuts;
  final AdhkarCatalog? adhkar;
  final HadithCatalog? hadith;
  final List<String> _verses;
  final List<(String, String)> _surahs;
  final List<List<String>> _shortcuts;
  final List<({DhikrGroup group, DhikrEntry entry, List<String> text})> _dhikr;

  SearchResults search(String query, {int verseLimit = 30}) {
    final quran = quranSearchText(query);
    final words = normalizeSearch(query);
    if (quran.isEmpty || words.isEmpty) return const SearchResults();

    // «2:255» opens that verse.
    final key = RegExp(r'^(\d+)\s*[:：]\s*(\d+)$').firstMatch(quran);
    if (key != null) {
      final surah = int.parse(key[1]!);
      final ayah = int.parse(key[2]!);
      if (surah >= 1 &&
          surah <= edition.surahs.length &&
          ayah >= 1 &&
          ayah <= edition.surahs[surah - 1].verses.length) {
        return SearchResults(
          verses: [edition.verses[edition.surahStarts[surah - 1] + ayah - 1]],
          versesTotal: 1,
        );
      }
    }

    final verses = <MushafVerse>[];
    var total = 0;
    if (quran.length >= 2) {
      for (var i = 0; i < _verses.length; i++) {
        if (_verses[i].contains(quran)) {
          total++;
          if (verses.length < verseLimit) verses.add(edition.verses[i]);
        }
      }
    }
    final seen = <String>{};
    return SearchResults(
      shortcuts: [
        for (var i = 0; i < shortcuts.length; i++)
          if (_shortcuts[i].any((name) => name.contains(words))) shortcuts[i],
      ],
      surahs: [
        for (var i = 0; i < _surahs.length; i++)
          if (_surahs[i].$1.contains(quran) || _surahs[i].$2.contains(words))
            edition.surahs[i],
      ],
      verses: verses,
      versesTotal: total,
      adhkar: [
        for (final item in _dhikr)
          if (item.text.any(
                (text) => text.contains(words) || text.contains(quran),
              ) &&
              seen.add(item.entry.id))
            (group: item.group, entry: item.entry),
      ].take(20).toList(),
      hadithTopics: [
        for (final topic in hadith?.categories ?? const <HadithCategory>[])
          if (normalizeSearch(topic.title).contains(words)) topic,
      ].take(20).toList(),
    );
  }
}
