import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/devotional_recording.dart';
import '../../../core/content/managed_library.dart';
import '../../quran/data/mushaf_edition.dart';
import 'quran_dua_index.dart';

final adhkarCatalogProvider = FutureProvider.autoDispose<AdhkarCatalog>(
  (ref) async => (await ref.watch(_libraryProvider.future)).adhkar,
);

final quranDuaIndexProvider =
    FutureProvider.autoDispose<Map<DuaTopic, List<DuaRange>>>(
      (ref) async => (await ref.watch(_libraryProvider.future)).duas,
    );

typedef _LibraryContent = ({
  AdhkarCatalog adhkar,
  Map<DuaTopic, List<DuaRange>> duas,
});

final _libraryProvider = FutureProvider.autoDispose<_LibraryContent>((
  ref,
) async {
  // Shares the single library download with the other library screens.
  final feedFuture = ref.watch(managedLibraryProvider.future);
  final editionFuture = ref.watch(mushafEditionProvider.future);
  final edition = await editionFuture;
  final feed = await feedFuture;
  if (feed != null) {
    try {
      return _decodeLibrary(feed, edition);
    } on Object {
      // A feed this version cannot read falls back to the bundled catalog.
    }
  }
  final text = await rootBundle.loadString('assets/adhkar/catalog.json');
  return (
    adhkar: AdhkarCatalog.fromJson(jsonDecode(text) as Map<String, Object?>),
    duas: quranDuaIndex,
  );
});

_LibraryContent _decodeLibrary(Object? source, MushafEdition edition) {
  final data = source as Map<String, Object?>;
  if (data['version'] != 1) {
    throw const FormatException('Unknown library version');
  }
  final adhkar = AdhkarCatalog.fromJson(data['adhkar'] as Map<String, Object?>);
  final rawDuas = data['duas'] as Map<String, Object?>;
  final duas = {
    for (final topic in DuaTopic.values)
      topic: [
        for (final item in _list<List<Object?>>(rawDuas[topic.name]))
          (surah: item[0] as int, first: item[1] as int, last: item[2] as int),
      ],
  };
  void validateRange(DuaRange range) {
    if (range.surah < 1 ||
        range.surah > edition.surahs.length ||
        range.first < 1 ||
        range.last < range.first ||
        range.last > edition.surahs[range.surah - 1].verses.length) {
      throw const FormatException('Invalid library verse range');
    }
  }

  for (final key in ['daily', 'routine', 'hisn', 'merits', 'quranDuas']) {
    if (!adhkar.sections.containsKey(key)) {
      throw const FormatException('Missing library section');
    }
  }
  if (!adhkar.groups.any((group) => group.id == 'morning')) {
    throw const FormatException('Missing morning remembrance');
  }
  for (final range in duas.values.expand((items) => items)) {
    validateRange(range);
  }
  for (final entry in [
    ...adhkar.groups.expand((group) => group.entries),
    ...adhkar.merits,
  ]) {
    for (final range in entry.verses) {
      validateRange(range);
    }
  }
  for (final chapter in adhkar.hisnTopics.expand((topic) => topic.chapters)) {
    if (chapter < 0 || chapter >= adhkar.chapterTitles.length) {
      throw const FormatException('Invalid Fortress of the Muslim chapter');
    }
  }
  return (adhkar: adhkar, duas: duas);
}

typedef LocalizedLabel = ({String ar, String en});
typedef DhikrStep = ({String unit, int count});
typedef VerseRange = ({int surah, int first, int last});

extension LocalizedLabelValue on LocalizedLabel {
  String inLanguage(String language) => language == 'ar' ? ar : en;
}

LocalizedLabel _label(Object? value) {
  final data = value as Map<String, Object?>;
  return (ar: data['ar'] as String, en: data['en'] as String);
}

List<T> _list<T>(Object? value) => (value as List<Object?>).cast<T>();

class DhikrVariant {
  DhikrVariant.fromJson(Map<String, Object?> data)
    : hadith = data['hadith'] as int?,
      recording = devotionalRecording(data['recording']),
      steps = [
        for (final step in _list<Map<String, Object?>>(data['repeat'] ?? []))
          (unit: step['unit'] as String, count: step['count'] as int),
      ];

  /// The HadeethEnc narration, or null for a dhikr written on the
  /// dashboard with its own text.
  final int? hadith;
  final List<DhikrStep> steps;
  final DevotionalRecording? recording;

  /// Stable part of progress keys: the hadith number, or `own`.
  String get key => hadith == null ? 'own' : '$hadith';

  int get goal =>
      steps.isEmpty ? 1 : steps.fold(0, (total, step) => total + step.count);

  DhikrStep stepAt(int count) {
    var offset = count;
    for (final step in steps) {
      if (offset < step.count) return step;
      offset -= step.count;
    }
    return steps.last;
  }
}

class DhikrEntry {
  DhikrEntry.fromJson(Map<String, Object?> data)
    : id = data['id'] as String,
      title = _label(data['title']),
      variants = [
        for (final variant in _list<Map<String, Object?>>(
          data['variants'] ?? [data],
        ))
          DhikrVariant.fromJson(variant),
      ],
      verses = [
        for (final range in _list<List<Object?>>(data['quran'] ?? []))
          (
            surah: range[0] as int,
            first: range[1] as int,
            last: range[2] as int,
          ),
      ],
      wording = (data['wording'] as Map<String, Object?>?)?['ar'] as String?,
      draftMeaning =
          (data['wording'] as Map<String, Object?>?)?['draftMeaningEn']
              as String?,
      meaning = (data['wording'] as Map<String, Object?>?)?['en'] as String?,
      source = _source(data['source']);

  static LocalizedLabel? _source(Object? value) {
    if (value is! Map<String, Object?>) return null;
    final ar = '${value['ar'] ?? ''}'.trim();
    final en = '${value['en'] ?? ''}'.trim();
    if (ar.isEmpty && en.isEmpty) return null;
    return (ar: ar.isEmpty ? en : ar, en: en.isEmpty ? ar : en);
  }

  final String id;
  final LocalizedLabel title;
  final List<DhikrVariant> variants;
  final List<VerseRange> verses;
  final String? wording;
  final String? draftMeaning;

  /// The English meaning written on the dashboard for an own-text dhikr.
  final String? meaning;

  /// Where an own-text dhikr comes from, e.g. «رواه مسلم».
  final LocalizedLabel? source;

  /// Favourites key: the narration, or this entry for an own-text dhikr.
  String savedKey(DhikrVariant variant) =>
      variant.hadith == null ? 'own:$id' : 'hadith:${variant.hadith}';
}

class DhikrGroup {
  const DhikrGroup(this.id, this.title, this.entries);

  final String id;
  final LocalizedLabel title;
  final List<DhikrEntry> entries;

  bool get isAfterPrayer => id == 'after-prayer';

  DhikrGroup prayerSession(String prayer) =>
      DhikrGroup('$id-$prayer', title, entries);

  static const prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
}

class HisnTopic {
  HisnTopic.fromJson(Map<String, Object?> data)
    : title = _label(data['title']),
      chapters = _list<int>(data['chapterIds']),
      hadiths = _list<int>(data['hadiths'] ?? []),
      entries = [
        for (final entry in _list<Map<String, Object?>>(data['entries'] ?? []))
          DhikrEntry.fromJson(entry),
      ];

  final LocalizedLabel title;
  final List<int> chapters;
  final List<int> hadiths;

  /// Adhkar and supplications written on the dashboard for this topic.
  final List<DhikrEntry> entries;
}

class AdhkarCatalog {
  AdhkarCatalog.fromJson(Map<String, Object?> data)
    : sections = (data['sections']! as Map<String, Object?>).map(
        (key, label) => MapEntry(key, _label(label)),
      ),
      merits = [
        for (final entry in _list<Map<String, Object?>>(data['merits']))
          DhikrEntry.fromJson(entry),
      ],
      hisnTopics = [
        for (final entry in _list<Map<String, Object?>>(
          (data['hisn']! as Map<String, Object?>)['topics'],
        ))
          HisnTopic.fromJson(entry),
      ] {
    final daily = data['daily']! as Map<String, Object?>;
    final entries = {
      for (final data in _list<Map<String, Object?>>(daily['entries']))
        data['id'] as String: DhikrEntry.fromJson(data),
    };
    final hisn = data['hisn']! as Map<String, Object?>;
    chapterTitles = _list<Map<String, Object?>>(hisn['chapterTitles'])
        .map(_label)
        .toList(growable: false);
    groups = [
      for (final group in _list<Map<String, Object?>>(daily['groups']))
        DhikrGroup(group['id'] as String, _label(group['title']), [
          for (final id in _list<String>(group['entries'])) entries[id]!,
        ]),
    ];
  }

  final Map<String, LocalizedLabel> sections;
  final List<HisnTopic> hisnTopics;
  final List<DhikrEntry> merits;
  late final List<DhikrGroup> groups;
  late final List<LocalizedLabel> chapterTitles;
}
