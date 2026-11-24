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
  const AppSettings({
    this.hidden = const {},
    this.announcement,
    this.radioStream,
    this.prayerVerses = const [],
  });

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
    final radio = Uri.tryParse('${app['radio_url'] ?? ''}'.trim());
    final verses = app['prayer_verses'];
    return AppSettings(
      hidden: hidden,
      announcement: announcement,
      radioStream:
          radio != null &&
              radio.scheme == 'https' &&
              radio.host.isNotEmpty &&
              radio.userInfo.isEmpty
          ? radio
          : null,
      prayerVerses: [
        if (verses is List)
          for (final range in verses)
            if (range is List &&
                range.length == 3 &&
                range.every((n) => n is int && n > 0))
              (range[0] as int, range[1] as int, range[2] as int),
      ],
    );
  }

  final Set<AppFeature> hidden;
  final Announcement? announcement;

  /// The radio stream set in the dashboard, when there is one.
  final Uri? radioStream;

  /// Verses for prayer notifications as (surah, first, last); empty keeps
  /// the app's own list.
  final List<(int, int, int)> prayerVerses;

  bool shows(AppFeature feature) => !hidden.contains(feature);
}

final appSettingsProvider = Provider<AppSettings>((ref) {
  if (!managedReleaseEnabled) return const AppSettings();
  return AppSettings.fromFeed(
    ref.watch(managedLibraryProvider).asData?.value,
    DateTime.now(),
  );
});
