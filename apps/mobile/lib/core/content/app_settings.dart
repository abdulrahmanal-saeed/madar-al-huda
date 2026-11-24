import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'feature_preview.dart';
import 'managed_library.dart';

/// A feature the dashboard can hide («إعدادات التطبيق»).
enum AppFeature {
  search,
  khatma,
  memorize,
  stats,
  zakat,
  tasbih,
  radio,
  ramadan,
  hadith,
  stories,
  qibla,
}

typedef Announcement = ({String ar, String en, Uri? link});

/// What the published library says about the app's features and the home
/// announcement. Everything stays on until the dashboard says otherwise, so
/// an old or missing feed never hides anything.
class AppSettings {
  const AppSettings({this.hidden = const {}, this.announcement});

  factory AppSettings.fromFeed(Map<String, Object?>? feed, DateTime today) {
    final app = feed?['app'];
    if (app is! Map) return const AppSettings();
    final features = app['features'];
    final hidden = <AppFeature>{
      if (features is Map)
        for (final feature in AppFeature.values)
          if (features[feature.name] == false) feature,
    };
    Announcement? announcement;
    final raw = app['announcement'];
    if (raw is Map) {
      final ar = '${raw['ar'] ?? ''}'.trim();
      final en = '${raw['en'] ?? ''}'.trim();
      final until = DateTime.tryParse('${raw['until'] ?? ''}');
      final link = Uri.tryParse('${raw['link'] ?? ''}');
      final current =
          until == null ||
          !DateTime(today.year, today.month, today.day).isAfter(until);
      if ((ar.isNotEmpty || en.isNotEmpty) && current) {
        announcement = (
          ar: ar.isNotEmpty ? ar : en,
          en: en.isNotEmpty ? en : ar,
          link: link != null && link.scheme == 'https' && link.host.isNotEmpty
              ? link
              : null,
        );
      }
    }
    return AppSettings(hidden: hidden, announcement: announcement);
  }

  final Set<AppFeature> hidden;
  final Announcement? announcement;

  bool shows(AppFeature feature) => !hidden.contains(feature);
}

final appSettingsProvider = Provider<AppSettings>((ref) {
  if (!managedReleaseEnabled) return const AppSettings();
  return AppSettings.fromFeed(
    ref.watch(managedLibraryProvider).asData?.value,
    DateTime.now(),
  );
});
