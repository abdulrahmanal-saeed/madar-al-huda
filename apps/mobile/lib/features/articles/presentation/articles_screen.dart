import 'package:material_ui/material_ui.dart';

import '../../../core/routing/app_sections.dart';
import '../../library/presentation/managed_content_screen.dart';

/// Articles. Requires the editorial workflow and CMS (P04-05).
class ArticlesScreen extends StatelessWidget {
  const ArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const ManagedContentScreen(section: AppSection.articles);
}
