import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/audio/audio_mini_player.dart';
import '../core/connectivity/offline_banner.dart';
import '../core/localization/l10n_extension.dart';
import '../core/routing/app_routes.dart';
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
  _Destination(
    Icons.nights_stay_outlined,
    Icons.nights_stay_rounded,
    (c) => c.l10n.navPrayer,
  ),
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
    if (ref.watch(readingFocusProvider)) {
      return Scaffold(body: navigationShell);
    }
    return AppNavigationFrame(
      index: navigationShell.currentIndex,
      onSelect: _onSelect,
      child: navigationShell,
    );
  }
}

/// Keeps the main destinations available on screens pushed above the tabs.
class AppNavigationFrame extends StatelessWidget {
  const AppNavigationFrame({
    required this.index,
    required this.child,
    this.onSelect,
    super.key,
  });

  final int index;
  final Widget child;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoints.medium;
    final select =
        onSelect ?? (int position) => context.go(AppRoutes.tabs[position]);

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              right: false,
              left: false,
              child: NavigationRail(
                key: AppShell.navigationRailKey,
                selectedIndex: index,
                onDestinationSelected: select,
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
                  Expanded(child: child),
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
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const OfflineBanner(),
          const AudioMiniPlayer(),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: DecoratedBox(
              key: AppShell.navigationBarKey,
              decoration: BoxDecoration(
                color: scheme.inverseSurface,
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .27),
                    blurRadius: 23,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Row(
                  children: [
                    for (final (position, destination) in _destinations.indexed)
                      Expanded(
                        flex: position == index ? 2 : 1,
                        child: _DockTab(
                          label: destination.label(context),
                          icon: position == index
                              ? destination.selectedIcon
                              : destination.icon,
                          current: position == index,
                          select: () => select(position),
                        ),
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

class _DockTab extends StatelessWidget {
  const _DockTab({
    required this.label,
    required this.icon,
    required this.current,
    required this.select,
  });

  final String label;
  final IconData icon;
  final bool current;
  final VoidCallback select;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = current ? scheme.onPrimary : scheme.onInverseSurface;
    return Semantics(
      label: label,
      selected: current,
      button: true,
      onTap: select,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: Material(
          color: current ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(32),
          child: InkWell(
            onTap: select,
            borderRadius: BorderRadius.circular(32),
            child: SizedBox(
              height: 44,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      Icon(icon, size: 21, color: color),
                      if (current) ...[
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
