import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/content/managed_library.dart';

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
  });

  final LocalizedText title;
  final LocalizedText? subtitle;
  final List<SectionLink> links;
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
        ),
      );
    }
  }
  for (final id in defaultLibraryOrder) {
    if (!mentioned.contains(id)) entries.add(BuiltinEntry(id));
  }
  return entries;
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
