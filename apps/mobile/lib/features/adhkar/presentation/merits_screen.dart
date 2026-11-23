import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/l10n_extension.dart';
import '../data/adhkar_catalog.dart';
import '../data/adhkar_progress.dart';
import 'adhkar_widgets.dart';
import 'dhikr_content.dart';

class MeritsScreen extends StatelessWidget {
  const MeritsScreen({required this.catalog, super.key});

  final AdhkarCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final language = context.adhkarLanguage;
    return AdhkarPage(
      title: catalog.sections['merits']!.inLanguage(language),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: catalog.merits.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final entry = catalog.merits[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: Text(entry.title.inLanguage(language)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openAdhkarPage(context, _MeritDetail(entry: entry)),
            ),
          );
        },
      ),
    );
  }
}

class _MeritDetail extends ConsumerWidget {
  const _MeritDetail({required this.entry});

  final DhikrEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final title = entry.title.inLanguage(context.adhkarLanguage);
    final selected = ref
        .watch(adhkarProgressProvider)
        .merits
        .contains(entry.id);
    return AdhkarPage(
      title: l10n.adhkarMerit,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdhkarHero(
            child: SizedBox(width: double.infinity, child: Text(title)),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.adhkarMerit,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          DhikrContent(hadith: entry.variants.first.hadith, entry: entry),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => adhkarSave(
              context,
              ref
                  .read(adhkarProgressProvider.notifier)
                  .setMerit(entry.id, selected: !selected),
            ),
            icon: Icon(selected ? Icons.check : Icons.add),
            label: Text(
              selected ? l10n.adhkarRemoveFromWird : l10n.adhkarAddToWird,
            ),
          ),
        ],
      ),
    );
  }
}
