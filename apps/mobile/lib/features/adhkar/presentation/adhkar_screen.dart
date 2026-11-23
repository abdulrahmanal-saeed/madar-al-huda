import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/content/feature_preview.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/widgets/section_detail_scaffold.dart';
import '../data/adhkar_catalog.dart';
import 'adhkar_hub.dart';

/// Adhkar & dua. Gated until sources and review are complete (P02-03).
class AdhkarScreen extends ConsumerWidget {
  const AdhkarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (AppSection.adhkar.status.isGated && !featurePreviewEnabled) {
      return const SectionDetailScaffold(section: AppSection.adhkar);
    }
    return ref
        .watch(adhkarCatalogProvider)
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => ref.invalidate(adhkarCatalogProvider),
                child: Text(context.l10n.readerRetry),
              ),
            ),
          ),
          data: (catalog) => AdhkarHub(catalog: catalog),
        );
  }
}
