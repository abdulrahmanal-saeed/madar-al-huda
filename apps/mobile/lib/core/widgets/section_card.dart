import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../content/feature_preview.dart';
import '../localization/l10n_extension.dart';
import '../routing/app_sections.dart';
import '../theme/app_tokens.dart';
import 'icon_badge.dart';
import 'status_pill.dart';

/// A tappable row card that opens an [AppSection].
class SectionCard extends StatelessWidget {
  const SectionCard({required this.section, super.key});

  final AppSection section;

  static Key keyFor(AppSection section) => ValueKey('section-card-$section');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = section.title(l10n);
    final subtitle = section.subtitle(l10n);

    return Card(
      key: keyFor(section),
      child: Semantics(
        button: true,
        label: '$title. $subtitle. ${section.status.title(l10n)}',
        excludeSemantics: true,
        child: InkWell(
          onTap: () => context.go(section.path),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                IconBadge(icon: section.icon),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      // Builds that already show the content don't label it
                      // as awaiting review.
                      if (!managedReleaseEnabled) ...[
                        const SizedBox(height: AppSpacing.sm),
                        StatusPill(status: section.status),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.chevron_right, color: scheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
