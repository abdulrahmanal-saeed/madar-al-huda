import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/madar_panel.dart';
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

    Widget tile(String value, String label, {bool active = false}) => Expanded(
      child: MadarPanel(
        radius: BorderRadius.circular(17),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 7),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: active ? scheme.primary : scheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Text(title, style: theme.textTheme.titleMedium),
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
      body: MadarBackdrop(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              l10n.statsPrivate,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            section(l10n.statsReading),
            row([
              tile(
                numbers.format(log.pagesOn(now)),
                l10n.statsToday,
                active: true,
              ),
              tile(numbers.format(week), l10n.statsWeek),
              tile(numbers.format(monthTotal), l10n.statsMonth),
            ]),
            const SizedBox(height: AppSpacing.sm),
            row([
              tile(numbers.format(log.streak(now)), l10n.statsStreak),
              tile(numbers.format(bestStreak(log)), l10n.statsBestStreak),
              tile(
                NumberFormat.percentPattern(
                  numberLocale(Localizations.localeOf(context).languageCode),
                ).format(
                  plan.pagesRead / DailyReadingPlanController.totalPages,
                ),
                l10n.statsKhatma,
              ),
            ]),
            section(l10n.statsLast30),
            MadarPanel(
              child: LayoutBuilder(
                builder: (context, size) {
                  final side = (size.maxWidth - 4 * 9) / 10;
                  return Wrap(
                    key: const Key('stats-month'),
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final (index, pages) in month.indexed)
                        Tooltip(
                          message: numbers.format(pages),
                          child: Container(
                            width: side,
                            height: side,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: pages == 0
                                  ? scheme.surfaceContainerHighest
                                  : index == month.length - 1
                                  ? scheme.primary
                                  : scheme.secondary.withValues(
                                      alpha: .45 + .55 * pages / highest,
                                    ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            section(l10n.statsMemorize),
            row([
              tile(numbers.format(verses), l10n.statsVerses),
              tile(
                numbers.format(
                  memorized.entries
                      .where((entry) => entry.value.isNotEmpty)
                      .length,
                ),
                l10n.statsSurahsStarted,
              ),
            ]),
            section(l10n.statsRemembrance),
            row([
              tile(
                numbers.format(adhkarDays(adhkar, now)),
                l10n.statsAdhkarDays,
              ),
              tile(numbers.format(tasbihToday), l10n.statsTasbihToday),
              tile(numbers.format(tasbih.total), l10n.statsTasbihTotal),
            ]),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
