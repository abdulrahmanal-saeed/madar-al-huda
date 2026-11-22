import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/content/feature_preview.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/widgets/section_detail_scaffold.dart';
import '../data/hadeeth_enc.dart';

/// Hadith library. Gated until a licensed corpus is selected (P03-01).
class HadithScreen extends ConsumerStatefulWidget {
  const HadithScreen({super.key});

  @override
  ConsumerState<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends ConsumerState<HadithScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    if (AppSection.hadith.status.isGated && !featurePreviewEnabled) {
      return const SectionDetailScaffold(section: AppSection.hadith);
    }
    final language = Localizations.localeOf(context).languageCode;
    final categories = hadithCategoriesProvider(language);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sectionHadithTitle)),
      body: ref
          .watch(categories)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                _HadithUnavailable(onRetry: () => ref.invalidate(categories)),
            data: (items) {
              final matches = items
                  .where((item) => item.title.toLowerCase().contains(_query))
                  .toList();
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextFormField(
                      initialValue: _query,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        labelText: l10n.hadithSearchTopics,
                      ),
                      onChanged: (value) =>
                          setState(() => _query = value.trim().toLowerCase()),
                    ),
                  ),
                  Expanded(
                    child: matches.isEmpty
                        ? Center(child: Text(l10n.hadithNoTopics))
                        : ListView.builder(
                            itemCount: matches.length,
                            itemBuilder: (context, index) {
                              final category = matches[index];
                              return ListTile(
                                title: Text(category.title),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        _HadithCategory(category: category),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
    );
  }
}

class _HadithCategory extends ConsumerStatefulWidget {
  const _HadithCategory({required this.category});
  final HadithItem category;

  @override
  ConsumerState<_HadithCategory> createState() => _HadithCategoryState();
}

class _HadithCategoryState extends ConsumerState<_HadithCategory> {
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final numbers = NumberFormat.decimalPattern(language);
    final l10n = context.l10n;
    final source = hadithPageProvider((
      language: language,
      category: widget.category.id,
      page: _page,
    ));
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.title)),
      body: ref
          .watch(source)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                _HadithUnavailable(onRetry: () => ref.invalidate(source)),
            data: (data) => Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    key: ValueKey(_page),
                    itemCount: data.items.length,
                    itemBuilder: (context, index) {
                      final item = data.items[index];
                      return ListTile(
                        title: Text(item.title),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _HadithEntry(id: item.id),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: l10n.hadithPrevious,
                      onPressed: _page > 1
                          ? () => setState(() => _page--)
                          : null,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Text(l10n.readerPageLabel(numbers.format(_page))),
                    IconButton(
                      tooltip: l10n.hadithNext,
                      onPressed: _page < data.lastPage
                          ? () => setState(() => _page++)
                          : null,
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }
}

class _HadithEntry extends ConsumerWidget {
  const _HadithEntry({required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = Localizations.localeOf(context).languageCode;
    final l10n = context.l10n;
    final source = hadithDetailProvider((language: language, id: id));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sectionHadithTitle)),
      body: ref
          .watch(source)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                _HadithUnavailable(onRetry: () => ref.invalidate(source)),
            data: (hadith) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  hadith.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(hadith.text),
                const SizedBox(height: 12),
                if (hadith.attribution.isNotEmpty) Text(hadith.attribution),
                if (hadith.grade.isNotEmpty)
                  Text(l10n.hadithProviderGrade(hadith.grade)),
                const SizedBox(height: 12),
                Text(hadith.explanation),
                if (hadith.reference case final reference?
                    when reference.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(reference),
                  ),
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.https('hadeethenc.com', '/$language/browse/hadith/$id'),
                  ),
                  child: const Text('HadeethEnc'),
                ),
              ],
            ),
          ),
    );
  }
}

class _HadithUnavailable extends StatelessWidget {
  const _HadithUnavailable({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.hadithUnavailable),
        TextButton(onPressed: onRetry, child: Text(context.l10n.readerRetry)),
      ],
    ),
  );
}
