import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/content/managed_library.dart';
import 'quran_services.dart';

class ChapterReciter {
  const ChapterReciter({
    required this.key,
    required this.arabicName,
    required this.englishName,
    this.publisher,
    this.downloadBase,
    this.foundationId,
    this.unavailable = const {},
  });

  final String key;
  final String arabicName;
  final String englishName;
  final String? publisher;
  final Uri? downloadBase;
  final int? foundationId;
  final Set<int> unavailable;

  String name(String language) => language == 'ar' ? arabicName : englishName;

  bool covers(int chapter) =>
      chapter >= 1 && chapter <= 114 && !unavailable.contains(chapter);

  bool get hasOfflineAudio => publisher != null || downloadBase != null;

  Uri? publisherAudio(int chapter) {
    final base = downloadBase;
    if (!covers(chapter)) return null;
    final number = chapter.toString().padLeft(3, '0');
    if (base != null) return base.resolve('$number.mp3');
    final edition = publisher;
    if (edition == null) return null;
    return Uri.https('cdn.mp3quran.net', '/audio/$edition/r1/$number.mp3');
  }
}

/// The Yousef Heiba catalogue snapshot is intersected with the publisher's
/// coverage for the verified Hafs murattal editions (see CONTENT_SOURCES).
const publishedChapterReciters = [
  ChapterReciter(
    key: '159',
    arabicName: 'ماهر المعيقلي',
    englishName: 'Maher Al Muaiqly',
    publisher: 'maher-muaiqly',
  ),
  ChapterReciter(
    key: 'mp3quran-121',
    arabicName: 'محمود علي البنا',
    englishName: 'Mahmoud Ali Al-Banna',
    publisher: 'mahmoud-banna',
  ),
  ChapterReciter(
    key: 'mp3quran-253',
    arabicName: 'إسلام صبحي',
    englishName: 'Islam Sobhi',
    publisher: 'islam-sobhi',
    unavailable: {
      3,
      4,
      6,
      7,
      8,
      9,
      10,
      16,
      22,
      28,
      33,
      37,
      39,
      40,
      43,
      45,
      65,
      69,
      105,
      112,
      113,
    },
  ),
];

List<ChapterReciter> chapterRecitersFor(
  int chapter,
  Iterable<QuranResource> verifiedFoundation, {
  Iterable<ChapterReciter> published = publishedChapterReciters,
  bool configured = false,
}) {
  final foundation = {for (final item in verifiedFoundation) item.id: item};
  final maher = foundation.remove(159);
  return [
    for (final reader in published)
      if (reader.covers(chapter))
        if (reader.key == '159' && maher != null)
          ChapterReciter(
            key: reader.key,
            arabicName: reader.arabicName,
            englishName: reader.englishName,
            publisher: reader.publisher,
            foundationId: maher.id,
          )
        else
          reader,
    if (!configured)
      for (final item in foundation.values)
        ChapterReciter(
          key: '${item.id}',
          arabicName: item.name,
          englishName: item.name,
          foundationId: item.id,
        ),
  ];
}

typedef ReciterSelection = ({
  bool configured,
  List<ChapterReciter> active,
  List<ChapterReciter> all,
});

const defaultReciterSelection = (
  configured: false,
  active: publishedChapterReciters,
  all: publishedChapterReciters,
);

final reciterSelectionProvider = Provider<ReciterSelection>((ref) {
  final data = ref.watch(managedLibraryProvider).asData?.value?['reciters'];
  if (data is! List<Object?>) return defaultReciterSelection;
  final original = {
    for (final reciter in publishedChapterReciters) reciter.key: reciter,
  };
  final all = {...original};
  final active = <String, ChapterReciter>{};
  for (final item in data.whereType<Map<String, Object?>>()) {
    final id = item['id'];
    if (id is! String) continue;
    final current = original[id] ?? _licensedReader(id, item);
    if (current == null) continue;
    all[id] = current;
    if (item['enabled'] == true) active[id] = current;
  }
  return (
    configured: true,
    active: active.values.toList(),
    all: all.values.toList(),
  );
});

ChapterReciter? _licensedReader(String id, Map<String, Object?> item) {
  final value = item['base'];
  final arabic = item['ar'];
  final english = item['en'];
  final chapters = item['chapters'];
  if (!RegExp(r'^mp3quran-\d+-\d+$').hasMatch(id) ||
      value is! String ||
      arabic is! String ||
      english is! String ||
      chapters is! List<Object?> ||
      chapters.isEmpty) {
    return null;
  }
  final base = Uri.tryParse(value);
  if (base == null ||
      base.scheme != 'https' ||
      !base.host.endsWith('.mp3quran.net') ||
      base.userInfo.isNotEmpty ||
      base.hasQuery ||
      base.hasFragment ||
      !base.path.endsWith('/')) {
    return null;
  }
  return ChapterReciter(
    key: id,
    arabicName: arabic,
    englishName: english,
    downloadBase: base,
    unavailable: {
      for (var chapter = 1; chapter <= 114; chapter++)
        if (!chapters.contains(chapter)) chapter,
    },
  );
}
