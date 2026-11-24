import 'package:material_ui/material_ui.dart';

import '../routing/app_sections.dart';
import '../theme/app_tokens.dart';
import 'responsive_content.dart';
import 'section_card.dart';
import 'settings_button.dart';

/// Root screen of a tab: large title, short intro, and its sections.
class HubScaffold extends StatelessWidget {
  const HubScaffold({
    required this.title,
    required this.intro,
    required this.sections,
    this.footer,
    super.key,
  });

  final String title;
  final String intro;
  final List<AppSection> sections;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: const [SettingsButton()]),
      body: CustomScrollView(
        slivers: [
          SliverResponsiveContent(
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Text(
                  intro,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          SliverResponsiveContent(
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                mainAxisExtent: MediaQuery.textScalerOf(context).scale(164),
              ),
              itemCount: sections.length,
              itemBuilder: (context, i) =>
                  SectionCard(section: sections[i], tone: i),
            ),
          ),
          if (footer != null) ...[
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            if (footer != null)
              SliverResponsiveContent(
                sliver: SliverToBoxAdapter(child: footer),
              ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }
}
