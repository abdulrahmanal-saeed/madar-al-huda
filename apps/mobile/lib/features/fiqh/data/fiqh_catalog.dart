import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/content/hosted_feed.dart';
import '../../../core/localization/search_text.dart';

const fiqhSchools = ['hanafi', 'maliki', 'shafii', 'hanbali'];
final fiqhFeedUrl = Uri.https('quran.abdulrahmanalsaeed.com', '/admin/', {
  'feed': 'fiqh',
});

typedef FiqhRecord = Map<String, Object?>;

FiqhRecord fiqhRecord(Object? value) =>
    value is Map<String, Object?> ? value : const {};

List<FiqhRecord> fiqhRecords(Object? value) =>
    value is List ? value.whereType<FiqhRecord>().toList() : const [];

String fiqhText(Object? value, bool ar) {
  final text = fiqhRecord(value)[ar ? 'ar' : 'en'];
  return text is String ? text : '';
}

bool _bilingual(Object? value) =>
    fiqhText(value, true).trim().isNotEmpty &&
    fiqhText(value, false).trim().isNotEmpty;

bool _id(Object? value) =>
    value is String && RegExp(r'^[a-z0-9][a-z0-9_-]{0,95}$').hasMatch(value);

/// A public issue link is built from the verified stable slug, never a URL
/// supplied by the issue body.
Uri? fiqhIssueUrl(FiqhRecord issue, bool ar) {
  final slug = issue['slug'];
  if (issue['status'] != 'published' || !_id(slug)) return null;
  final lang = ar ? 'ar' : 'en';
  return Uri.https(fiqhFeedUrl.host, '/admin/fiqh/$lang/$slug/');
}

String? fiqhShareText(FiqhRecord issue, bool ar) {
  final url = fiqhIssueUrl(issue, ar);
  if (url == null) return null;
  final title = fiqhText(issue['title'], ar);
  return '$title\n$url';
}

/// The dedicated feed is authoritative when available, even if empty.
/// It accepts a published projection, never a draft export.
class FiqhCatalog {
  const FiqhCatalog._(this.categories, this.issues, this.disclaimer);

  final List<FiqhRecord> categories;
  final List<FiqhRecord> issues;
  final FiqhRecord disclaimer;

  factory FiqhCatalog.decode(Object? value) {
    final feed = fiqhRecord(value);
    if (feed['schemaVersion'] != 1 ||
        feed['kind'] != 'published_fiqh' ||
        feed['categories'] is! List ||
        feed['issues'] is! List ||
        !_bilingual(feed['disclaimer'])) {
      throw const FormatException('Invalid published fiqh feed');
    }
    final categories = fiqhRecords(feed['categories']);
    final issues = fiqhRecords(feed['issues']);
    if (categories.length != (feed['categories'] as List).length ||
        issues.length != (feed['issues'] as List).length) {
      throw const FormatException('Invalid fiqh rows');
    }
    final ids = <Object?>{};
    for (final category in categories) {
      if (!_id(category['id']) ||
          !_bilingual(category['title']) ||
          !ids.add(category['id'])) {
        throw const FormatException('Invalid fiqh category');
      }
    }
    final issueIds = <Object?>{};
    final slugs = <Object?>{};
    for (final issue in issues) {
      final positions = fiqhRecord(issue['positions']);
      final revision = issue['revision'];
      if (!_id(issue['id']) ||
          !issueIds.add(issue['id']) ||
          !_id(issue['slug']) ||
          !slugs.add(issue['slug']) ||
          !ids.contains(issue['categoryId']) ||
          !_bilingual(issue['title']) ||
          issue['status'] != 'published' ||
          revision is! int ||
          revision < 1 ||
          positions.length != fiqhSchools.length ||
          fiqhSchools.any(
            (school) => !_bilingual(fiqhRecord(positions[school])['ruling']),
          )) {
        throw const FormatException('Invalid published fiqh issue');
      }
    }
    return FiqhCatalog._(
      List.unmodifiable(categories),
      List.unmodifiable(issues),
      Map.unmodifiable(fiqhRecord(feed['disclaimer'])),
    );
  }

  List<FiqhRecord> search(String query, {String? category}) {
    final needle = normalizeSearch(query);
    return issues.where((issue) {
      if (category != null &&
          issue['categoryId'] != category &&
          issue['subcategoryId'] != category &&
          !(issue['relatedCategoryIds'] is List &&
              (issue['relatedCategoryIds'] as List).contains(category))) {
        return false;
      }
      if (needle.isEmpty) return true;
      final terms = [
        issue['number'],
        for (final field in ['title', 'summary', 'introduction', 'scope'])
          for (final ar in [true, false]) fiqhText(issue[field], ar),
        ..._keywords(issue['keywords']),
      ].whereType<String>();
      return terms.any((term) => normalizeSearch(term).contains(needle));
    }).toList();
  }

  static Iterable<String> _keywords(Object? value) sync* {
    if (value is List) {
      for (final item in value) {
        if (item is String) yield item;
        if (item is Map) {
          yield fiqhText(item, true);
          yield fiqhText(item, false);
        }
      }
    } else if (value is Map) {
      for (final lang in ['ar', 'en']) {
        final words = value[lang];
        if (words is String) yield words;
        if (words is List) yield* words.whereType<String>();
      }
    }
  }
}

final fiqhCatalogProvider = FutureProvider.autoDispose<FiqhCatalog?>((ref) {
  final loadedAt = DateTime.now();
  final timer = Timer(const Duration(minutes: 15), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  final lifecycle = AppLifecycleListener(
    onResume: () {
      if (DateTime.now().difference(loadedAt) >= const Duration(minutes: 1)) {
        ref.invalidateSelf();
      }
    },
  );
  ref.onDispose(lifecycle.dispose);
  return ref
      .watch(hostedFeedProvider)
      .load<FiqhCatalog?>(
        url: fiqhFeedUrl,
        cacheName: 'madar-fiqh-published-v1',
        decode: FiqhCatalog.decode,
        fallback: () async => null,
      );
});
