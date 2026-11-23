import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../adhkar/data/adhkar_catalog.dart';
import '../../adhkar/data/adhkar_progress.dart';
import '../../prayer/domain/prayer_schedule.dart';
import '../../reminders/application/reminder_settings_controller.dart';
import '../../worship/domain/worship_moment.dart';

/// Suggests the remembrance that fits the time of day — morning, after the
/// prayer, evening or before sleep — and opens it in one tap.
class WorshipNowCard extends ConsumerWidget {
  const WorshipNowCard({required this.schedule, required this.now, super.key});

  final PrayerSchedule schedule;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(reminderSettingsProvider);
    final moment = worshipMomentAt(
      schedule,
      now,
      bedtimeMinutes: settings.bedtimeMinutes,
    );
    if (moment == null) return const SizedBox.shrink();
    final catalog = ref.watch(adhkarCatalogProvider).asData?.value;
    final group = catalog?.groups
        .where((group) => group.id == moment.groupId)
        .firstOrNull;
    if (group == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    final number = NumberFormat.decimalPattern(language).format;
    final progress = ref.watch(adhkarProgressProvider);
    final day = adhkarDayKey(now);
    final done = progress.completedInGroup(day, group);
    final goal = progress.groupGoal(group);
    final kicker = switch (moment) {
      WorshipMoment.morning => l10n.homeNowMorning,
      WorshipMoment.afterPrayer => l10n.homeNowAfterPrayer,
      WorshipMoment.evening => l10n.homeNowEvening,
      WorshipMoment.bedtime => l10n.homeNowBedtime,
    };
    final onPrimary = scheme.onPrimary;
    return Card(
      key: ValueKey('worship-now-${moment.name}'),
      color: scheme.primary,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(AppRoutes.adhkarGroup(group.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: onPrimary.withValues(alpha: 0.14),
                      borderRadius: AppRadii.lgAll,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      child: Text(
                        l10n.homeNowLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: onPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      kicker,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: onPrimary.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                group.title.inLanguage(language),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: onPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: AppRadii.smAll,
                child: LinearProgressIndicator(
                  value: goal == 0 ? 0 : done / goal,
                  minHeight: 6,
                  color: scheme.secondary,
                  backgroundColor: onPrimary.withValues(alpha: 0.18),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.adhkarPosition(number(done), number(goal)),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: onPrimary.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: onPrimary,
                  foregroundColor: scheme.primary,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => context.go(AppRoutes.adhkarGroup(group.id)),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  done == 0 ? l10n.homeNowStart : l10n.homeNowContinue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
