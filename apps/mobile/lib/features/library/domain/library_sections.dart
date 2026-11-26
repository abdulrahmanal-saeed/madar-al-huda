import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/content/managed_library.dart';
import '../../learning/data/learning_catalog.dart' as learning;

typedef LocalizedText = ({String ar, String en});

extension LocalizedTextValue on LocalizedText {
  String inLanguage(String language) => language == 'ar' ? ar : en;
}

typedef SectionLink = ({LocalizedText title, Uri url});

/// One entry of the library, in the order chosen on the dashboard.
sealed class LibraryEntry {
  const LibraryEntry(this.id);
  final String id;
}

/// A section built into the app: `radio`, `duas`, `hadith`, `fiqh`,
/// `articles`, `stories` or `lessons`.
final class BuiltinEntry extends LibraryEntry {
  const BuiltinEntry(super.id);
}

/// A section added on the dashboard: a titled list of HTTPS links.
final class LinksEntry extends LibraryEntry {
  const LinksEntry(
    super.id, {
    required this.title,
    required this.subtitle,
    required this.links,
    this.seasons = const [],
  });

  final LocalizedText title;
  final LocalizedText? subtitle;
  final List<SectionLink> links;
  final List<learning.LearningSeries> seasons;
}

/// The app's own order, used until the dashboard publishes one.
const defaultLibraryOrder = [
  'radio',
  'duas',
  'names',
  'hadith',
  'fiqh',
  'articles',
  'stories',
  'lessons',
];

/// Visible library entries in dashboard order. Hidden entries are left out;
/// built-in sections the feed does not mention keep their default place at
/// the end, so a newer app never loses a section an older dashboard omits.
List<LibraryEntry> librarySectionsFrom(Map<String, Object?>? feed) {
  final appearance = feed?['appearance'];
  final raw = appearance is Map ? appearance['sections'] : null;
  if (raw is! List) {
    return [for (final id in defaultLibraryOrder) BuiltinEntry(id)];
  }
  final entries = <LibraryEntry>[];
  final mentioned = <String>{};
  for (final item in raw.whereType<Map<Object?, Object?>>()) {
    final id = item['id'];
    if (id is! String || !mentioned.add(id)) continue;
    if (item['visible'] == false) continue;
    if (item['kind'] == 'builtin') {
      if (defaultLibraryOrder.contains(id)) entries.add(BuiltinEntry(id));
    } else if (item['kind'] == 'links') {
      final title = _text(item['title']);
      if (title == null) continue;
      final links = <SectionLink>[];
      final items = item['items'];
      if (items is List) {
        for (final link in items.whereType<Map<Object?, Object?>>()) {
          final name = _text(link['title']);
          final address = link['url'];
          final url = address is String ? Uri.tryParse(address) : null;
          if (name == null ||
              url == null ||
              url.scheme != 'https' ||
              url.host.isEmpty ||
              url.userInfo.isNotEmpty) {
            continue;
          }
          links.add((title: name, url: url));
        }
      }
      entries.add(
        LinksEntry(
          id,
          title: title,
          subtitle: _text(item['subtitle']),
          links: List.unmodifiable(links),
          seasons: _seasons(id, item['seasons']),
        ),
      );
    }
  }
  for (final id in defaultLibraryOrder) {
    if (!mentioned.contains(id)) entries.add(BuiltinEntry(id));
  }
  return entries;
}

List<learning.LearningSeries> _seasons(String sectionId, Object? raw) {
  if (raw is! List) return const [];
  final seasons = <learning.LearningSeries>[];
  final ids = <String>{};
  final names = <String>{};
  for (final season in raw.whereType<Map<Object?, Object?>>()) {
    final id = season['id'];
    final title = _text(season['title']);
    final rows = season['episodes'];
    if (id is! String ||
        !RegExp(r'^season-[a-f0-9]{16}
  if (value is! Map) return null;
  final ar = value['ar'];
  final en = value['en'];
  if (ar is! String || en is! String || ar.trim().isEmpty) return null;
  return (ar: ar, en: en.trim().isEmpty ? ar : en);
}

final librarySectionsProvider = Provider<List<LibraryEntry>>(
  (ref) => librarySectionsFrom(ref.watch(managedLibraryProvider).asData?.value),
);
).hasMatch(id) ||
        !ids.add(id) ||
        title == null ||
        rows is! List) {
      continue;
    }
    final episodes = <learning.LessonEpisode>[];
    final numbers = <int>{};
    for (final row in rows.whereType<Map<Object?, Object?>>()) {
      final number = row['number'];
      final label = _text(row['title']);
      final media = row['media'];
      if (number is! int ||
          number < 1 ||
          number > 999999 ||
          label == null ||
          media is! Map ||
          numbers.contains(number)) {
        continue;
      }
      final files = <learning.LessonFormat, learning.LessonMedia>{};
      for (final format in learning.LessonFormat.values) {
        final file = media[format.name];
        if (file is! Map) continue;
        final name = file['file'];
        final bytes = file['bytes'];
        if (name is! String ||
            !RegExp(r'^Library-[a-f0-9]{32}\.(mp3|mp4)
  if (value is! Map) return null;
  final ar = value['ar'];
  final en = value['en'];
  if (ar is! String || en is! String || ar.trim().isEmpty) return null;
  return (ar: ar, en: en.trim().isEmpty ? ar : en);
}

final librarySectionsProvider = Provider<List<LibraryEntry>>(
  (ref) => librarySectionsFrom(ref.watch(managedLibraryProvider).asData?.value),
);
).hasMatch(name) ||
            !name.endsWith('.${format.extension}') ||
            bytes is! int ||
            bytes < 1024 ||
            bytes > 1536 * 1024 * 1024 ||
            !names.add(name)) {
          continue;
        }
        files[format] = learning.LessonMedia(name, bytes, format);
      }
      if (files.isEmpty) continue;
      numbers.add(number);
      episodes.add(
        learning.LessonEpisode(number, Map.unmodifiable(files), title: label),
      );
    }
    episodes.sort((a, b) => a.number.compareTo(b.number));
    if (episodes.isEmpty) continue;
    seasons.add(
      learning.LearningSeries(
        '$sectionId-$id',
        title.ar,
        title.en,
        List.unmodifiable(episodes),
      ),
    );
  }
  return List.unmodifiable(seasons);
}

LocalizedText? _text(Object? value) {
  if (value is! Map) return null;
  final ar = value['ar'];
  final en = value['en'];
  if (ar is! String || en is! String || ar.trim().isEmpty) return null;
  return (ar: ar, en: en.trim().isEmpty ? ar : en);
}

final librarySectionsProvider = Provider<List<LibraryEntry>>(
  (ref) => librarySectionsFrom(ref.watch(managedLibraryProvider).asData?.value),
);
