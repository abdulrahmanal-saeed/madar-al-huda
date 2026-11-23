import 'quran_services.dart';

class ChapterReciter {
  const ChapterReciter({
    required this.key,
    required this.arabicName,
    required this.englishName,
    this.publisher,
    this.foundationId,
    this.unavailable = const {},
  });

  final String key;
  final String arabicName;
  final String englishName;
  final String? publisher;
  final int? foundationId;
  final Set<int> unavailable;

  String name(String language) => language == 'ar' ? arabicName : englishName;

  bool covers(int chapter) =>
      chapter >= 1 && chapter <= 114 && !unavailable.contains(chapter);

  Uri? publisherAudio(int chapter) {
    final edition = publisher;
    if (edition == null || !covers(chapter)) return null;
    final number = chapter.toString().padLeft(3, '0');
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
  Iterable<QuranResource> verifiedFoundation,
) {
  final foundation = {for (final item in verifiedFoundation) item.id: item};
  final maher = foundation.remove(159);
  return [
    for (final reader in publishedChapterReciters)
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
    for (final item in foundation.values)
      ChapterReciter(
        key: '${item.id}',
        arabicName: item.name,
        englishName: item.name,
        foundationId: item.id,
      ),
  ];
}
