import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:material_ui/material_ui.dart';

import '../../../core/content/feature_preview.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/widgets/section_detail_scaffold.dart';
import '../../quran/data/mushaf_edition.dart';
import '../../quran/domain/quran_search_text.dart';
import '../data/daily_reading_plan.dart';
import '../data/khatma.dart';

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
    final numbers = decimalFormat(Localizations.localeOf(context).languageCode);
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
      appBar: AppBar(
        title: Text(l10n.dailyReadingTitle),
        actions: [
          IconButton(
            key: const ValueKey('open-stats'),
            tooltip: l10n.statsTitle,
            onPressed: () => context.push(AppRoutes.stats),
            icon: const Icon(Icons.insights_outlined),
          ),
        ],
      ),
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
            const KhatmaCard(),
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

/// The khatma goal, today's share of it and the reading streak.
class KhatmaCard extends ConsumerWidget {
  const KhatmaCard({super.key, this.clock = DateTime.now});

  final DateTime Function() clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context);
    final numbers = decimalFormat(locale.languageCode);
    final now = clock();
    final goal = ref.watch(khatmaGoalProvider);
    final plan = ref.watch(dailyReadingPlanProvider);
    final log = ref.watch(readingLogProvider);
    final today = log.pagesOn(now);
    final streak = log.streak(now);
    final week = log.lastDays(now, 7);
    final highest = week.fold<int>(1, math.max);

    Future<void> choose(int days) async {
      try {
        await ref.read(khatmaGoalProvider.notifier).choose(days, now: now);
      } on Object {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.localSaveFailed)));
        }
      }
    }

    final target = goal?.todayTarget(
      pagesRead: plan.pagesRead,
      readToday: today,
      now: now,
    );
    return Card(
      key: const Key('khatma-card'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.khatmaGoalTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (goal != null)
                  TextButton(
                    onPressed: () async {
                      try {
                        await ref.read(khatmaGoalProvider.notifier).clear();
                      } on Object {
                        // Keeps the goal; nothing to undo.
                      }
                    },
                    child: Text(l10n.khatmaCancel),
                  ),
              ],
            ),
            if (goal == null) ...[
              Text(l10n.khatmaGoalHint),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final days in KhatmaGoalController.choices)
                    ActionChip(
                      key: ValueKey('khatma-$days'),
                      label: Text(l10n.khatmaDays(numbers.format(days), days)),
                      onPressed: () => choose(days),
                    ),
                ],
              ),
            ] else ...[
              Text(
                l10n.khatmaEndsOn(
                  DateFormat.yMMMMEEEEd(locale.toLanguageTag())
                      .format(goal.end),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              if (target == 0 || (target != null && today >= target))
                Row(
                  children: [
                    Icon(Icons.check_circle, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(l10n.khatmaTodayDone)),
                  ],
                )
              else if (target != null) ...[
                Text(
                  l10n.khatmaToday(
                    numbers.format(target),
                    numbers.format(today),
                  ),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: target == 0 ? 1 : today / target,
                    minHeight: 8,
                  ),
                ),
              ],
            ],
            const Divider(height: 28),
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: streak > 0 ? Colors.deepOrange : scheme.outline,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    streak == 0
                        ? l10n.khatmaNoStreak
                        : l10n.khatmaStreak(numbers.format(streak), streak),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 104,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final (index, pages) in week.indexed)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (pages > 0)
                            Text(
                              numbers.format(pages),
                              style: theme.textTheme.labelSmall,
                            ),
                          const SizedBox(height: 2),
                          Container(
                            height: 4 + 44 * pages / highest,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: index == 6
                                  ? scheme.primary
                                  : scheme.primary.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat(
                              'EEEEE',
                              locale.toLanguageTag(),
                            ).format(now.subtract(Duration(days: 6 - index))),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
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
