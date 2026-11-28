import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/content/feature_preview.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../core/widgets/section_detail_scaffold.dart';
import '../../library/presentation/managed_content_screen.dart';
import '../data/fiqh_catalog.dart';

class FiqhScreen extends ConsumerWidget {
  const FiqhScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (AppSection.fiqh.status.isGated && !managedReleaseEnabled) {
      return const SectionDetailScaffold(section: AppSection.fiqh);
    }
    final result = ref.watch(fiqhCatalogProvider);
    final catalog = result.asData?.value;
    if (catalog == null && result.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(AppSection.fiqh.title(context.l10n))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (catalog == null) {
      return const ManagedContentScreen(section: AppSection.fiqh);
    }
    return FiqhCatalogScreen(
      catalog: catalog,
      onRefresh: () async {
        await ref.refresh(fiqhCatalogProvider.future);
      },
    );
  }
}

bool _arabic(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'ar';

const _schoolNames = {
  'hanafi': ('الحنفي', 'Hanafi'),
  'maliki': ('المالكي', 'Maliki'),
  'shafii': ('الشافعي', 'Shafi‘i'),
  'hanbali': ('الحنبلي', 'Hanbali'),
};

class FiqhCatalogScreen extends StatefulWidget {
  const FiqhCatalogScreen({
    required this.catalog,
    required this.onRefresh,
    super.key,
  });

  final FiqhCatalog catalog;
  final Future<void> Function() onRefresh;

  @override
  State<FiqhCatalogScreen> createState() => _FiqhCatalogScreenState();
}

class _FiqhCatalogScreenState extends State<FiqhCatalogScreen> {
  String _query = '';
  String? _category;

  @override
  Widget build(BuildContext context) {
    final ar = _arabic(context);
    final catalog = widget.catalog;
    final category = catalog.categories.any((row) => row['id'] == _category)
        ? _category
        : null;
    final rows = catalog.search(_query, category: category);
    return Scaffold(
      appBar: AppBar(title: Text(AppSection.fiqh.title(context.l10n))),
      body: RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ResponsiveContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Text(fiqhText(catalog.disclaimer, ar)),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      labelText: ar ? 'ابحث عن مسألة' : 'Search issues',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      ChoiceChip(
                        label: Text(ar ? 'الكل' : 'All'),
                        selected: category == null,
                        onSelected: (_) => setState(() => _category = null),
                      ),
                      for (final row in catalog.categories)
                        ChoiceChip(
                          label: Text(
                            '${fiqhText(row['title'], ar)} '
                            '(${catalog.search('', category: row['id'] as String).length})',
                          ),
                          selected: category == row['id'],
                          onSelected: (_) => setState(
                            () => _category = row['id'] as String,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (rows.isEmpty)
                    Text(
                      ar ? 'لا توجد مسائل منشورة مطابقة.' : 'No matching published issues.',
                    ),
                  for (final row in rows)
                    Card(
                      child: ListTile(
                        title: Text(fiqhText(row['title'], ar)),
                        subtitle: Text(fiqhText(row['summary'], ar)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => FiqhIssueScreen(issue: row),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FiqhIssueScreen extends StatelessWidget {
  const FiqhIssueScreen({required this.issue, super.key});

  final FiqhRecord issue;

  @override
  Widget build(BuildContext context) {
    final ar = _arabic(context);
    final title = fiqhText(issue['title'], ar);
    final positions = fiqhRecord(issue['positions']);
    final sources = fiqhRecord(issue['sources']);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: ar ? 'نسخ عنوان المسألة' : 'Copy issue reference',
            icon: const Icon(Icons.copy),
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: '$title · ${issue['number'] ?? ''}'),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ar ? 'تم النسخ' : 'Copied')),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.md),
                _TextSection(
                  heading: ar ? 'الملخص' : 'Summary',
                  text: fiqhText(issue['summary'], ar),
                ),
                _TextSection(
                  heading: ar ? 'المقدمة' : 'Introduction',
                  text: fiqhText(issue['introduction'], ar),
                ),
                _TextSection(
                  heading: ar ? 'نطاق المسألة' : 'Scope',
                  text: fiqhText(issue['scope'], ar),
                ),
                Text(
                  ar ? 'المذاهب الأربعة' : 'The four schools',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                for (final school in fiqhSchools)
                  _SchoolCard(
                    name: ar
                        ? _schoolNames[school]!.$1
                        : _schoolNames[school]!.$2,
                    position: fiqhRecord(positions[school]),
                    sources: sources,
                    ar: ar,
                  ),
                Text(
                  ar ? 'الأدلة' : 'Evidence',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                for (final evidence in fiqhRecords(issue['evidence']))
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(fiqhText(evidence['text'], ar)),
                          SelectableText(fiqhText(evidence['reference'], ar)),
                          Text(fiqhText(evidence['explanation'], ar)),
                          if (fiqhText(evidence['grading'], ar).isNotEmpty)
                            Text(
                              '${fiqhText(evidence['grading'], ar)} — '
                              '${fiqhText(evidence['gradingAttribution'], ar)}',
                            ),
                        ],
                      ),
                    ),
                  ),
                for (final (key, heading) in [
                  ('agreements', ar ? 'مواضع الاتفاق' : 'Agreement'),
                  ('disagreements', ar ? 'مواضع الاختلاف' : 'Disagreement'),
                  ('reasonsForDifferences', ar ? 'أسباب الاختلاف' : 'Reasons'),
                ])
                  _TextSection(
                    heading: heading,
                    text: _analysisText(issue[key], ar),
                  ),
                _TextSection(
                  heading: ar ? 'الخلاصة العلمية' : 'Scholarly summary',
                  text: fiqhText(issue['scholarlySummary'], ar),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _analysisText(Object? value, bool ar) {
  final block = fiqhRecord(value);
  if (block['applicable'] == false) {
    return fiqhText(block['justification'], ar);
  }
  return fiqhRecords(block['entries'])
      .map((entry) => fiqhText(entry, ar))
      .where((text) => text.isNotEmpty)
      .join('\n\n');
}

class _TextSection extends StatelessWidget {
  const _TextSection({required this.heading, required this.text});

  final String heading;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          SelectableText(text),
        ],
      ),
    );
  }
}

class _SchoolCard extends StatelessWidget {
  const _SchoolCard({
    required this.name,
    required this.position,
    required this.sources,
    required this.ar,
  });

  final String name;
  final FiqhRecord position;
  final FiqhRecord sources;
  final bool ar;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(name, style: Theme.of(context).textTheme.titleLarge),
          _TextSection(
            heading: ar ? 'القول' : 'Position',
            text: fiqhText(position['ruling'], ar),
          ),
          _TextSection(
            heading: ar ? 'الشرح' : 'Explanation',
            text: fiqhText(position['explanation'], ar),
          ),
          _TextSection(
            heading: ar ? 'التعليل' : 'Reasoning',
            text: fiqhText(position['reasoning'], ar),
          ),
          for (final ref in fiqhRecords(position['sourceReferences']))
            SelectableText(
              '${fiqhText(fiqhRecord(sources[ref['sourceId']])['title'], ar)}'
              ' — ${fiqhText(ref['locator'], ar)}',
            ),
        ],
      ),
    ),
  );
}
