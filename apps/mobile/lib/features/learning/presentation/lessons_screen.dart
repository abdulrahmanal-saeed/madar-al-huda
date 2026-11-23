import 'package:material_ui/material_ui.dart';

import '../../../core/routing/app_sections.dart';
import '../../library/presentation/managed_content_screen.dart';

/// Lessons & quizzes (P04-02, P04-03).
class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const ManagedContentScreen(section: AppSection.lessons);
}
