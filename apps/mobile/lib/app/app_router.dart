import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/routing/app_routes.dart';
import '../features/adhkar/presentation/adhkar_screen.dart';
import '../features/articles/presentation/articles_screen.dart';
import '../features/downloads/presentation/download_center_screen.dart';
import '../features/feedback/feedback_screen.dart';
import '../features/fiqh/presentation/fiqh_screen.dart';
import '../features/hadith/presentation/hadith_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/home/presentation/listening_duas.dart';
import '../features/learning/presentation/learning_hub_screen.dart';
import '../features/learning/presentation/lessons_screen.dart';
import '../features/learning/presentation/prophet_stories_screen.dart';
import '../features/library/presentation/library_hub_screen.dart';
import '../features/library/presentation/links_section_screen.dart';
import '../features/names/names_screen.dart';
import '../features/prayer/presentation/prayer_times_screen.dart';
import '../features/qibla/presentation/qibla_screen.dart';
import '../features/quran/data/mushaf_edition.dart';
import '../features/quran/domain/quran_storage_contracts.dart';
import '../features/quran/presentation/memorize_screen.dart';
import '../features/quran/presentation/mushaf_screen.dart';
import '../features/ramadan/presentation/ramadan_screen.dart';
import '../features/reminders/presentation/reminder_settings_screen.dart';
import '../features/search/presentation/global_search_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/stats/presentation/stats_screen.dart';
import '../features/tasbih/presentation/tasbih_screen.dart';
import '../features/worship/presentation/daily_reading_card.dart';
import '../features/worship/presentation/worship_hub_screen.dart';
import '../features/zakat/presentation/zakat_screen.dart';
import 'app_shell.dart';
import 'not_found_screen.dart';

/// Route path → screen for one sub-route, relative to its tab root.
GoRoute _child(String fullPath, String parent, Widget screen) => GoRoute(
  path: fullPath.substring(parent.length + 1),
  builder: (_, _) => screen,
);

/// Builds the app's router. Exposed for tests (custom [initialLocation]).
GoRouter buildAppRouter({String initialLocation = AppRoutes.home}) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    errorBuilder: (_, _) => const NotFoundScreen(),
    redirect: (_, state) => switch (state.uri.path) {
      '/' => AppRoutes.home,
      // The radio plays in place now; its old page address opens the
      // library, where its banner is.
      AppRoutes.cairoRadio => AppRoutes.library,
      AppRoutes.mushaf ||
      AppRoutes.recitations ||
      AppRoutes.tafsir => state.uri.replace(path: AppRoutes.quran).toString(),
      _ => null,
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.quran,
                builder: (_, state) {
                  final surah = int.tryParse(
                    state.uri.queryParameters['surah'] ?? '',
                  );
                  final ayah = int.tryParse(
                    state.uri.queryParameters['ayah'] ?? '',
                  );
                  return MushafScreen(
                    initialVerse:
                        surah != null &&
                            surah >= 1 &&
                            surah <= surahCount &&
                            ayah != null &&
                            ayah >= 1
                        ? AyahRef(
                            editionId: MushafEdition.id,
                            surah: surah,
                            ayah: ayah,
                          )
                        : null,
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adhkar,
                builder: (_, _) => const AdhkarScreen(),
                routes: [
                  GoRoute(
                    path: 'listen',
                    builder: (_, state) => ListeningDuasScreen(
                      initialId: state.uri.queryParameters['dua'],
                    ),
                  ),
                  _child(
                    AppRoutes.morningAdhkar,
                    AppRoutes.adhkar,
                    const AdhkarScreen(destination: AdhkarDestination.morning),
                  ),
                  _child(
                    AppRoutes.quranDuas,
                    AppRoutes.adhkar,
                    const AdhkarScreen(
                      destination: AdhkarDestination.quranDuas,
                    ),
                  ),
                  GoRoute(
                    path: 'group/:id',
                    builder: (_, state) => AdhkarScreen(
                      destination: AdhkarDestination.group,
                      groupId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            initialLocation: AppRoutes.worship,
            routes: [
              GoRoute(
                path: AppRoutes.worship,
                builder: (_, _) => const WorshipHubScreen(),
                routes: [
                  GoRoute(
                    path: 'prayer-times',
                    builder: (_, state) => PrayerTimesScreen(
                      showLocationOnOpen:
                          state.uri.queryParameters['location'] == '1',
                    ),
                  ),
                  _child(
                    AppRoutes.qibla,
                    AppRoutes.worship,
                    const QiblaScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.library,
                builder: (_, _) => const LibraryHubScreen(),
                routes: [
                  _child(
                    AppRoutes.hadith,
                    AppRoutes.library,
                    const HadithScreen(),
                  ),
                  _child(AppRoutes.fiqh, AppRoutes.library, const FiqhScreen()),
                  _child(
                    AppRoutes.articles,
                    AppRoutes.library,
                    const ArticlesScreen(),
                  ),
                  _child(
                    AppRoutes.names,
                    AppRoutes.library,
                    const NamesScreen(),
                  ),
                  GoRoute(
                    path: 's/:id',
                    builder: (_, state) => LinksSectionScreen(
                      id: state.pathParameters['id']!,
                      seasonId: state.uri.queryParameters['season'],
                      episodeNumber: int.tryParse(
                        state.uri.queryParameters['episode'] ?? '',
                      ),
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: AppRoutes.learning,
                builder: (_, _) => const LearningHubScreen(),
                routes: [
                  _child(
                    AppRoutes.lessons,
                    AppRoutes.learning,
                    const LessonsScreen(),
                  ),
                  _child(
                    AppRoutes.stories,
                    AppRoutes.learning,
                    const ProphetStoriesScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.dailyReading,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) => const DailyReadingScreen(),
      ),
      GoRoute(
        path: AppRoutes.tasbih,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) =>
            const AppNavigationFrame(index: 2, child: TasbihScreen()),
      ),
      GoRoute(
        path: AppRoutes.ramadan,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) => const RamadanScreen(),
      ),
      GoRoute(
        path: AppRoutes.zakat,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) => const ZakatScreen(),
      ),
      GoRoute(
        path: AppRoutes.stats,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) =>
            const AppNavigationFrame(index: 4, child: StatsScreen()),
      ),
      GoRoute(
        path: AppRoutes.memorize,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) => const MemorizeScreen(),
      ),
      GoRoute(
        path: AppRoutes.search,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) => const GlobalSearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) =>
            const AppNavigationFrame(index: 4, child: SettingsScreen()),
        routes: [
          GoRoute(
            path: 'reminders',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, _) => const ReminderSettingsScreen(),
          ),
          GoRoute(
            path: 'downloads',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, _) => const AppNavigationFrame(
              index: 4,
              child: DownloadCenterScreen(),
            ),
          ),
          GoRoute(
            path: 'feedback',
            parentNavigatorKey: rootNavigatorKey,
            builder: (_, _) => const FeedbackScreen(),
          ),
        ],
      ),
    ],
  );
}

/// The app router; created once per ProviderScope.
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = buildAppRouter();
  ref.onDispose(router.dispose);
  return router;
});
