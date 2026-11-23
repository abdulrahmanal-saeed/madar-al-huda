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
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(title),
            actions: const [SettingsButton()],
          ),
          SliverResponsiveContent(
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
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
            sliver: SliverList.separated(
              itemCount: sections.length,
              itemBuilder: (context, i) => SectionCard(section: sections[i]),
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            ),
          ),
          if (footer != null)
            SliverResponsiveContent(sliver: SliverToBoxAdapter(child: footer)),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }
}
