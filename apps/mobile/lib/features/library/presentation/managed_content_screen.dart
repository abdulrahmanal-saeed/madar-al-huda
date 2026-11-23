import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/content/feature_preview.dart';
import '../../../core/content/managed_library.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../core/widgets/section_detail_scaffold.dart';

List<Map<String, Object?>> _rows(Object? value) =>
    value is List ? value.whereType<Map<String, Object?>>().toList() : const [];

String _text(Object? value, bool ar) {
  if (value is! Map<String, Object?>) return '';
  final text = value[ar ? 'ar' : 'en'];
  return text is String ? text : '';
}

final _schools = {
  'hanafi': ('الحنفي', 'Hanafi'),
  'maliki': ('المالكي', 'Maliki'),
  'shafii': ('الشافعي', 'Shafi‘i'),
  'hanbali': ('الحنبلي', 'Hanbali'),
};

class ManagedContentScreen extends ConsumerWidget {
  const ManagedContentScreen({required this.section, super.key});
  final AppSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (section.status.isGated && !managedReleaseEnabled) {
      return SectionDetailScaffold(section: section);
    }
    final value = ref.watch(managedLibraryProvider);
    final library = value.asData?.value?['library'];
    final rows = _rows(library is Map ? library[section.name] : null);
    if (rows.isEmpty) return SectionDetailScaffold(section: section);
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(section.title(l10n))),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(managedLibraryProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ResponsiveContent(
              child: Column(
                children: [
                  for (final row in rows)
                    Card(
                      child: ListTile(
                        leading: Icon(section.icon),
                        title: Text(_text(row['title'], ar)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) =>
                                _ContentDetail(row: row, section: section),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentDetail extends StatelessWidget {
  const _ContentDetail({required this.row, required this.section});
  final Map<String, Object?> row;
  final AppSection section;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final title = _text(row['title'], ar);
    final questions = _rows(row['questions']);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        children: [
          ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),
                if (section == AppSection.fiqh)
                  for (final entry in _rows(row['positions']))
                    if (_schools[entry['school']] case final school?)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ar ? school.$1 : school.$2,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(_text(entry['body'], ar)),
                              _SourceLink(entry['source']),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      SelectableText(_text(row['body'], ar)),
                      _SourceLink(row['source']),
                    ],
                if (questions.isNotEmpty)
                  FilledButton.icon(
                    icon: const Icon(Icons.quiz_outlined),
                    label: Text(ar ? 'ابدأ الاختبار' : 'Start quiz'),
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(builder: (_) => _QuizScreen(questions)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceLink extends StatelessWidget {
  const _SourceLink(this.source);
  final Object? source;

  @override
  Widget build(BuildContext context) {
    final link = source is String ? Uri.tryParse(source as String) : null;
    if (link == null || link.scheme != 'https' || link.host.isEmpty) {
      return const SizedBox.shrink();
    }
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        onPressed: () => launchUrl(link, mode: LaunchMode.externalApplication),
        icon: const Icon(Icons.open_in_new),
        label: Text(ar ? 'المصدر' : 'Source'),
      ),
    );
  }
}

class _QuizScreen extends StatefulWidget {
  const _QuizScreen(this.questions);
  final List<Map<String, Object?>> questions;

  @override
  State<_QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<_QuizScreen> {
  final _answers = <int, int>{};
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final questions = widget.questions;
    final score = _answers.entries
        .where((answer) => questions[answer.key]['answer'] == answer.value)
        .length;
    return Scaffold(
      appBar: AppBar(title: Text(ar ? 'الاختبار' : 'Quiz')),
      body: ListView(
        children: [
          ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_submitted)
                  Text(
                    ar
                        ? 'النتيجة $score / ${questions.length}'
                        : 'Score $score / ${questions.length}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                for (final (i, question) in questions.indexed)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _text(question['prompt'], ar),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          for (final (index, choice) in _rows(
                            question['choices'],
                          ).indexed)
                            ChoiceChip(
                              label: Text(_text(choice, ar)),
                              selected: _submitted
                                  ? question['answer'] == index
                                  : _answers[i] == index,
                              onSelected: _submitted
                                  ? null
                                  : (_) => setState(() => _answers[i] = index),
                            ),
                        ],
                      ),
                    ),
                  ),
                FilledButton(
                  onPressed: _submitted || _answers.length == questions.length
                      ? () => setState(() {
                          if (_submitted) _answers.clear();
                          _submitted = !_submitted;
                        })
                      : null,
                  child: Text(
                    _submitted
                        ? (ar ? 'إعادة الاختبار' : 'Try again')
                        : (ar ? 'إظهار النتيجة' : 'Show result'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
