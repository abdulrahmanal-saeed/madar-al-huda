import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/content/feature_preview.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/widgets/section_detail_scaffold.dart';
import '../data/adhkar_catalog.dart';
import 'adhkar_hub.dart';
import 'quran_duas.dart';

enum AdhkarDestination { hub, morning, group, quranDuas }

/// Adhkar & dua. Gated until sources and review are complete (P02-03).
class AdhkarScreen extends ConsumerWidget {
  const AdhkarScreen({
    this.destination = AdhkarDestination.hub,
    this.groupId,
    super.key,
  });

  final AdhkarDestination destination;

  /// Catalog group opened by [AdhkarDestination.group], such as `evening`.
  final String? groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (AppSection.adhkar.status.isGated && !managedReleaseEnabled) {
      return const SectionDetailScaffold(section: AppSection.adhkar);
    }
    if (destination == AdhkarDestination.quranDuas) return const QuranDuas();
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
          data: (catalog) {
            final id = switch (destination) {
              AdhkarDestination.morning => 'morning',
              AdhkarDestination.group => groupId,
              _ => null,
            };
            final group = catalog.groups
                .where((group) => group.id == id)
                .firstOrNull;
            return group == null
                ? AdhkarHub(catalog: catalog)
                : adhkarGroupPage(group);
          },
        );
  }
}
