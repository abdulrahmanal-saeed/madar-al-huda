import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adhkarCatalogProvider = FutureProvider<AdhkarCatalog>((ref) async {
  final text = await rootBundle.loadString('assets/adhkar/catalog.json');
  return AdhkarCatalog.fromJson(jsonDecode(text) as Map<String, Object?>);
});

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
    : hadith = data['hadith'] as int,
      steps = [
        for (final step in _list<Map<String, Object?>>(data['repeat'] ?? []))
          (unit: step['unit'] as String, count: step['count'] as int),
      ];

  final int hadith;
  final List<DhikrStep> steps;

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
              as String?;

  final String id;
  final LocalizedLabel title;
  final List<DhikrVariant> variants;
  final List<VerseRange> verses;
  final String? wording;
  final String? draftMeaning;
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
      hadiths = _list<int>(data['hadiths'] ?? []);

  final LocalizedLabel title;
  final List<int> chapters;
  final List<int> hadiths;
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
