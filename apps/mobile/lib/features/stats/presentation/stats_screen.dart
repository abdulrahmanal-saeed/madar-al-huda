import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../adhkar/data/adhkar_progress.dart';
import '../../quran/application/memorization.dart';
import '../../tasbih/application/tasbih_controller.dart';
import '../../worship/data/daily_reading_plan.dart';
import '../../worship/data/khatma.dart';

/// The longest run of days with reading in [log].
int bestStreak(Map<String, int> log) {
  final days = [
    for (final MapEntry(:key, :value) in log.entries)
      if (value > 0) DateTime.tryParse(key),
  ].whereType<DateTime>().toList()..sort();
  var best = 0;
  var run = 0;
  DateTime? previous;
  for (final day in days) {
    run = previous != null && day.difference(previous).inDays == 1
        ? run + 1
        : 1;
    best = math.max(best, run);
    previous = day;
  }
  return best;
}

/// Days in the last [days] days with any remembrance counted.
int adhkarDays(AdhkarProgress progress, DateTime now, {int days = 30}) {
  final recent = {
    for (var i = 0; i < days; i++)
      adhkarDayKey(now.subtract(Duration(days: i))),
  };
  return {
    for (final MapEntry(:key, :value) in progress.counts.entries)
      if (value > 0 && recent.contains(key.split('/').first))
        key.split('/').first,
  }.length;
}

/// Personal statistics, from what the app already keeps on the device.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key, this.clock = DateTime.now});

  final DateTime Function() clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final numbers = decimalFormat(Localizations.localeOf(context).languageCode);
    final now = clock();
    final log = ref.watch(readingLogProvider);
    final plan = ref.watch(dailyReadingPlanProvider);
    final memorized = ref.watch(memorizedProvider);
    final tasbih = ref.watch(tasbihProvider);
    final adhkar = ref.watch(adhkarProgressProvider);
    final month = log.lastDays(now, 30);
    final week = month.sublist(23).fold<int>(0, (a, b) => a + b);
    final monthTotal = month.fold<int>(0, (a, b) => a + b);
    final verses = memorized.values.fold<int>(0, (a, b) => a + b.length);
    final tasbihToday = tasbih.day == tasbihDay(now) ? tasbih.today : 0;

    Widget tile(String value, String label, IconData icon) => Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          child: Column(
            children: [
              Icon(icon, color: scheme.primary, size: 22),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Widget section(String title, IconData icon) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(title, style: theme.textTheme.titleMedium),
        ],
      ),
    );

    Widget row(List<Widget> tiles) => Row(
      children: [
        for (final (index, child) in tiles.indexed) ...[
          if (index > 0) const SizedBox(width: AppSpacing.sm),
          child,
        ],
      ],
    );

    final highest = month.fold<int>(1, math.max);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            l10n.statsPrivate,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          section(l10n.statsReading, Icons.menu_book_outlined),
          row([
            tile(
              numbers.format(log.pagesOn(now)),
              l10n.statsToday,
              Icons.today,
            ),
            tile(numbers.format(week), l10n.statsWeek, Icons.date_range),
            tile(
              numbers.format(monthTotal),
              l10n.statsMonth,
              Icons.calendar_month,
            ),
          ]),
          const SizedBox(height: AppSpacing.sm),
          row([
            tile(
              numbers.format(log.streak(now)),
              l10n.statsStreak,
              Icons.local_fire_department_outlined,
            ),
            tile(
              numbers.format(bestStreak(log)),
              l10n.statsBestStreak,
              Icons.emoji_events_outlined,
            ),
            tile(
              NumberFormat.percentPattern(
                numberLocale(Localizations.localeOf(context).languageCode),
              ).format(plan.pagesRead / DailyReadingPlanController.totalPages),
              l10n.statsKhatma,
              Icons.flag_outlined,
            ),
          ]),
          const SizedBox(height: AppSpacing.md),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.statsLast30, style: theme.textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    key: const Key('stats-month'),
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final pages in month)
                        Tooltip(
                          message: numbers.format(pages),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: pages == 0
                                  ? scheme.surfaceContainerHighest
                                  : scheme.primary.withValues(
                                      alpha: 0.25 + 0.75 * pages / highest,
                                    ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          section(l10n.statsMemorize, Icons.psychology_outlined),
          row([
            tile(
              numbers.format(verses),
              l10n.statsVerses,
              Icons.format_list_numbered,
            ),
            tile(
              numbers.format(
                memorized.entries
                    .where((entry) => entry.value.isNotEmpty)
                    .length,
              ),
              l10n.statsSurahsStarted,
              Icons.bookmark_added_outlined,
            ),
          ]),
          section(l10n.statsRemembrance, Icons.wb_twilight),
          row([
            tile(
              numbers.format(adhkarDays(adhkar, now)),
              l10n.statsAdhkarDays,
              Icons.event_available_outlined,
            ),
            tile(
              numbers.format(tasbihToday),
              l10n.statsTasbihToday,
              Icons.touch_app_outlined,
            ),
            tile(
              numbers.format(tasbih.total),
              l10n.statsTasbihTotal,
              Icons.all_inclusive,
            ),
          ]),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
