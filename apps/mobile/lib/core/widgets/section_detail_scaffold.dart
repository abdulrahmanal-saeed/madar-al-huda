import 'package:material_ui/material_ui.dart';

import '../localization/l10n_extension.dart';
import '../routing/app_sections.dart';
import '../theme/app_tokens.dart';
import 'content_status_panel.dart';
import 'icon_badge.dart';
import 'responsive_content.dart';

/// Shared layout for a section screen (Prayer Times, Hadith, Tafsir, ...).
///
/// While [AppSection.status] is gated it shows only the section header and
/// a [ContentStatusPanel]. Once a feature ships, its screen supplies [body];
/// [body] is ignored while the section is gated, so unverified content can't
/// leak through by accident.
class SectionDetailScaffold extends StatelessWidget {
  const SectionDetailScaffold({
    required this.section,
    super.key,
    this.body,
    this.footer,
  });

  final AppSection section;
  final Widget? body;

  /// Shown under the status panel or [body], e.g. a retry prompt.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final title = section.title(l10n);
    final gated = section.status.isGated;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconBadge(icon: section.icon, size: 56),
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  header: true,
                  child: Text(title, style: theme.textTheme.headlineSmall),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  section.subtitle(l10n),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (gated || body == null)
                  ContentStatusPanel(status: section.status)
                else
                  body!,
                if (footer case final footer?) ...[
                  const SizedBox(height: AppSpacing.lg),
                  footer,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
