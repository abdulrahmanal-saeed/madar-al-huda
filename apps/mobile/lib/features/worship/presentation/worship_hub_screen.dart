import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/madar_panel.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../core/widgets/settings_button.dart';

class WorshipHubScreen extends StatelessWidget {
  const WorshipHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navPrayer),
        actions: const [SettingsButton()],
      ),
      body: MadarBackdrop(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          children: [
            ResponsiveContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.md,
                children: [
                  _PrayerTile(
                    title: l10n.dailyReadingTitle,
                    icon: Icons.auto_stories_outlined,
                    route: AppRoutes.dailyReading,
                    featured: true,
                  ),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: AppSpacing.md,
                      children: [
                        Expanded(
                          child: _PrayerTile(
                            title: l10n.sectionPrayerTimesTitle,
                            icon: Icons.mosque_outlined,
                            route: AppRoutes.prayerTimes,
                          ),
                        ),
                        Expanded(
                          child: _PrayerTile(
                            title: l10n.sectionQiblaTitle,
                            icon: Icons.explore_outlined,
                            route: AppRoutes.qibla,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerTile extends StatelessWidget {
  const _PrayerTile({
    required this.title,
    required this.icon,
    required this.route,
    this.featured = false,
  });

  final String title;
  final IconData icon;
  final String route;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      color: featured ? scheme.primaryContainer : null,
      child: InkWell(
        onTap: () => context.push(route),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: featured ? 140 : 112),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.sm,
              children: [
                Icon(
                  icon,
                  color: featured ? scheme.onPrimaryContainer : scheme.primary,
                  size: featured ? 32 : 27,
                ),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: featured ? scheme.onPrimaryContainer : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
