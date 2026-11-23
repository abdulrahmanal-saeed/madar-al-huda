import 'package:material_ui/material_ui.dart';

import '../../../core/routing/app_sections.dart';
import '../../library/presentation/managed_content_screen.dart';

/// Comparative fiqh of the four madhhabs. Requires qualified scholarly review (P00-08 → P03-05).
class FiqhScreen extends StatelessWidget {
  const FiqhScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const ManagedContentScreen(section: AppSection.fiqh);
}
