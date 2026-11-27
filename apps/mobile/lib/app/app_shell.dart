import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/audio/audio_mini_player.dart';
import '../core/connectivity/offline_banner.dart';
import '../core/localization/l10n_extension.dart';
import '../core/theme/app_tokens.dart';
import '../features/quran/application/reading_preferences.dart';

/// Tab destination metadata, in [AppRoutes.tabs] order.
class _Destination {
  const _Destination(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String Function(BuildContext) label;
}

final List<_Destination> _destinations = [
  _Destination(Icons.home_outlined, Icons.home, (c) => c.l10n.navHome),
  _Destination(
    Icons.menu_book_outlined,
    Icons.menu_book,
    (c) => c.l10n.navQuran,
  ),
  _Destination(
    Icons.wb_twilight_outlined,
    Icons.wb_twilight,
    (c) => c.l10n.navAdhkar,
  ),
  _Destination(Icons.mosque_outlined, Icons.mosque, (c) => c.l10n.navPrayer),
  _Destination(
    Icons.local_library_outlined,
    Icons.local_library,
    (c) => c.l10n.navLibrary,
  ),
];

/// Five-tab shell. Each tab keeps its own navigation stack and scroll state
/// (StatefulShellRoute.indexedStack). Uses a bottom bar on phones and a
/// navigation rail on wider screens.
class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const Key navigationBarKey = ValueKey('app-navigation-bar');
  static const Key navigationRailKey = ValueKey('app-navigation-rail');

  void _onSelect(int index) => navigationShell.goBranch(
    index,
    // Re-selecting the current tab returns to its root.
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoints.medium;
    final index = navigationShell.currentIndex;
    if (ref.watch(readingFocusProvider)) {
      return Scaffold(body: navigationShell);
    }

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              right: false,
              left: false,
              child: NavigationRail(
                key: navigationRailKey,
                selectedIndex: index,
                onDestinationSelected: _onSelect,
                labelType: NavigationRailLabelType.all,
                groupAlignment: -0.85,
                destinations: [
                  for (final d in _destinations)
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label(context)),
                    ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: navigationShell),
                  const OfflineBanner(),
                  const AudioMiniPlayer(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const OfflineBanner(),
          const AudioMiniPlayer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: NavigationBarTheme(
                data: NavigationBarTheme.of(context).copyWith(
                  labelTextStyle: WidgetStatePropertyAll(
                    TextStyle(
                      color: scheme.onInverseSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                child: NavigationBar(
                  key: navigationBarKey,
                  backgroundColor: scheme.inverseSurface,
                  indicatorColor: scheme.primary,
                  labelBehavior:
                      NavigationDestinationLabelBehavior.onlyShowSelected,
                  selectedIndex: index,
                  onDestinationSelected: _onSelect,
                  destinations: [
                    for (final d in _destinations)
                      NavigationDestination(
                        icon: Icon(d.icon, color: scheme.onInverseSurface),
                        selectedIcon: Icon(
                          d.selectedIcon,
                          color: scheme.onPrimary,
                        ),
                        label: d.label(context),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
