import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../content/feature_preview.dart';
import '../localization/l10n_extension.dart';
import '../routing/app_sections.dart';
import '../theme/app_tokens.dart';
import 'status_pill.dart';

/// A tappable row card that opens an [AppSection].
class SectionCard extends StatelessWidget {
  const SectionCard({required this.section, this.tone = 0, super.key});

  final AppSection section;

  /// Picks the icon colour so neighbouring cards differ.
  final int tone;

  static Key keyFor(AppSection section) => ValueKey('section-card-$section');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = section.title(l10n);
    final subtitle = section.subtitle(l10n);

    final (background, foreground) = switch (tone % 3) {
      0 => (scheme.primaryContainer, scheme.onPrimaryContainer),
      1 => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      _ => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
    };
    return Card(
      key: keyFor(section),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        label: '$title. $subtitle. ${section.status.title(l10n)}',
        excludeSemantics: true,
        child: InkWell(
          onTap: () => context.go(section.path),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: AppRadii.lgAll,
                  ),
                  child: Icon(section.icon, color: foreground),
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                // Builds that already show the content don't label it as
                // awaiting review.
                if (!managedReleaseEnabled) ...[
                  const SizedBox(height: AppSpacing.xs),
                  StatusPill(status: section.status),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
