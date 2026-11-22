import 'package:material_ui/material_ui.dart';

import '../../../core/content/feature_preview.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/widgets/section_detail_scaffold.dart';
import 'quran_duas.dart';

/// Adhkar & dua. Gated until sources and review are complete (P02-03).
class AdhkarScreen extends StatelessWidget {
  const AdhkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (AppSection.adhkar.status.isGated && !featurePreviewEnabled) {
      return const SectionDetailScaffold(section: AppSection.adhkar);
    }
    return const QuranDuas();
  }
}
