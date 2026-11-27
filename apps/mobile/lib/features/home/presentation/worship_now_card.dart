import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/madar_panel.dart';
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
    final number = decimalFormat(language).format;
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
    void open() => context.go(AppRoutes.adhkarGroup(group.id));
    return MadarPanel(
      key: ValueKey('worship-now-${moment.name}'),
      radius: BorderRadius.circular(23),
      onTap: open,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          MadarPanel(
            radius: AppRadii.lgAll,
            padding: const EdgeInsets.all(12),
            child: Tooltip(
              message: kicker,
              child: Icon(
                moment == WorshipMoment.morning
                    ? Icons.wb_twilight
                    : Icons.nights_stay_outlined,
                size: 22,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.title.inLanguage(language),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.adhkarPosition(number(done), number(goal)),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: FilledButton(
              onPressed: open,
              style: FilledButton.styleFrom(
                minimumSize: const Size(68, 42),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: Text(
                done == 0 ? l10n.homeNowStart : l10n.homeNowContinue,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
