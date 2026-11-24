/// Route paths. Keep them stable: they double as deep-link paths.
abstract final class AppRoutes {
  // Tab roots (one StatefulShellBranch each, in navigation order).
  static const String home = '/home';
  static const String quran = '/quran';
  static const String worship = '/worship';
  static const String library = '/library';
  static const String learning = '/learning';

  // Quran
  static const String mushaf = '$quran/read';
  static const String recitations = '$quran/recitations';
  static const String tafsir = '$quran/tafsir';

  // Worship
  static const String prayerTimes = '$worship/prayer-times';
  static const String qibla = '$worship/qibla';
  static const String adhkar = '$worship/adhkar';
  static const String morningAdhkar = '$adhkar/morning';
  static const String quranDuas = '$adhkar/quran-duas';

  /// One remembrance group by its catalog id, e.g. `evening`.
  static String adhkarGroup(String id) => '$adhkar/group/$id';
  static const String dailyReading = '$worship/daily-reading';
  static const String ramadan = '$worship/ramadan';
  static const String tasbih = '$worship/tasbih';
  static const String cairoRadio = '$worship/cairo-radio';

  // Library
  static const String hadith = '$library/hadith';
  static const String fiqh = '$library/fiqh';
  static const String articles = '$library/articles';

  /// A section added on the dashboard, by its id.
  static String librarySection(String id) => '$library/s/$id';

  // Learning
  static const String lessons = '$learning/lessons';
  static const String stories = '$learning/prophet-stories';

  // Full-screen (outside the tab shell)
  static const String settings = '/settings';
  static const String search = '/search';
  static const String memorize = '/memorize';
  static const String reminders = '$settings/reminders';
  static const String downloads = '$settings/downloads';

  /// Tab roots in navigation order.
  static const List<String> tabs = [home, quran, adhkar, prayerTimes, library];

  static String verse(int surah, int ayah) => Uri(
    path: quran,
    queryParameters: {'surah': '$surah', 'ayah': '$ayah'},
  ).toString();
}
