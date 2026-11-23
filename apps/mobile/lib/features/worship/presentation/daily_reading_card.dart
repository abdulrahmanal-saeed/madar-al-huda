import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';

import '../../../core/content/feature_preview.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/widgets/section_detail_scaffold.dart';
import '../../quran/data/mushaf_edition.dart';
import '../../quran/domain/quran_search_text.dart';
import '../data/daily_reading_plan.dart';

class DailyReadingCard extends StatelessWidget {
  const DailyReadingCard({super.key});

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.menu_book_outlined),
      title: Text(context.l10n.dailyReadingTitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(AppRoutes.dailyReading),
    ),
  );
}

class DailyReadingScreen extends ConsumerStatefulWidget {
  const DailyReadingScreen({super.key});

  @override
  ConsumerState<DailyReadingScreen> createState() => _DailyReadingScreenState();
}

class _DailyReadingScreenState extends ConsumerState<DailyReadingScreen> {
  final _paceForm = GlobalKey<FormState>();
  bool _saving = false;
  bool _saveFailed = false;

  Future<void> _save(Future<void> Function() update) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      await update();
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editPace(int current, NumberFormat numbers) async {
    final l10n = context.l10n;
    final pace = await showDialog<int>(
      context: context,
      builder: (dialog) {
        int? pages;
        return AlertDialog(
          title: Text(l10n.dailyReadingEdit),
          content: Form(
            key: _paceForm,
            child: TextFormField(
              initialValue: numbers.format(current),
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.dailyReadingPaceLabel,
              ),
              validator: (value) {
                final input = int.tryParse(quranSearchText(value ?? ''));
                if (input == null ||
                    input < 1 ||
                    input > DailyReadingPlanController.totalPages) {
                  return l10n.dailyReadingPaceRange;
                }
                pages = input;
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(),
              child: Text(MaterialLocalizations.of(dialog).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () {
                if (_paceForm.currentState!.validate()) {
                  Navigator.of(dialog).pop(pages);
                }
              },
              child: Text(l10n.dailyReadingSave),
            ),
          ],
        );
      },
    );
    if (pace == null || !mounted) return;
    await _save(
      () => ref.read(dailyReadingPlanProvider.notifier).setPace(pace),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(dailyReadingPlanProvider);
    final edition = ref.watch(mushafEditionProvider).asData?.value;
    final controller = ref.read(dailyReadingPlanProvider.notifier);
    const total = DailyReadingPlanController.totalPages;
    final l10n = context.l10n;
    final numbers = NumberFormat.decimalPattern(
      Localizations.localeOf(context).languageCode,
    );
    final completed = plan.pagesRead == total;
    final progress = l10n.dailyReadingProgress(
      numbers.format(plan.pagesRead),
      numbers.format(total),
    );
    if (AppSection.mushaf.status.isGated && !managedReleaseEnabled) {
      return const SectionDetailScaffold(section: AppSection.mushaf);
    }

    void openPage(int page) {
      if (edition == null) return;
      final verse = edition.verses[edition.pageStarts[page - 1]].ref;
      context.go(AppRoutes.verse(verse.surah, verse.ayah));
    }

    final pace = plan.pagesPerSession;
    final next = plan.pagesRead + 1;
    final end = plan.endPage(total);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.dailyReadingTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              color: theme.colorScheme.primaryContainer,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: SizedBox.square(
                  dimension: 42,
                  child: CircularProgressIndicator(
                    value: plan.pagesRead / total,
                    semanticsLabel: progress,
                  ),
                ),
                title: Text(l10n.dailyReadingCurrentPlan),
                subtitle: Text(progress),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dailyReadingPaceLabel,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (!completed)
                      Text(
                        l10n.dailyReadingRemaining(
                          numbers.format(plan.remainingSessions(total)),
                        ),
                      ),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        IconButton(
                          tooltip: l10n.decreaseReadingPace,
                          onPressed: _saving || pace == 1
                              ? null
                              : () => _save(() => controller.setPace(pace - 1)),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        TextButton(
                          onPressed: _saving
                              ? null
                              : () => _editPace(pace, numbers),
                          child: Text(
                            numbers.format(pace),
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.increaseReadingPace,
                          onPressed: _saving || pace == total
                              ? null
                              : () => _save(() => controller.setPace(pace + 1)),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_saveFailed) Text(l10n.localSaveFailed),
            if (completed) ...[
              Text(l10n.dailyReadingCompleted),
              FilledButton(
                onPressed: _saving ? null : () => _save(controller.startAgain),
                child: Text(l10n.dailyReadingRestart),
              ),
            ] else ...[
              Text(
                l10n.dailyReadingTodaysWird,
                style: theme.textTheme.titleMedium,
              ),
              Text(
                l10n.dailyReadingRange(
                  numbers.format(next),
                  numbers.format(end),
                ),
              ),
              Wrap(
                spacing: 6,
                children: [
                  for (var page = next; page <= math.min(end, next + 6); page++)
                    ActionChip(
                      label: Text(l10n.readerPageLabel(numbers.format(page))),
                      onPressed: edition == null ? null : () => openPage(page),
                    ),
                ],
              ),
              FilledButton.icon(
                onPressed: edition == null || _saving
                    ? null
                    : () => openPage(next),
                icon: const Icon(Icons.menu_book_outlined),
                label: Text(l10n.dailyReadingNextPage(numbers.format(next))),
              ),
              OutlinedButton(
                onPressed: _saving
                    ? null
                    : () => _save(controller.completeSession),
                child: Text(l10n.dailyReadingMarkRead),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
