import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/app_locales.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/brand_colors.dart';
import '../domain/prayer_schedule.dart';

String prayerName(PrayerSlot slot, AppLocalizations l10n) => switch (slot) {
  PrayerSlot.fajr => l10n.prayerFajr,
  PrayerSlot.sunrise => l10n.prayerSunrise,
  PrayerSlot.dhuhr => l10n.prayerDhuhr,
  PrayerSlot.asr => l10n.prayerAsr,
  PrayerSlot.maghrib => l10n.prayerMaghrib,
  PrayerSlot.isha => l10n.prayerIsha,
};

class NextPrayerCard extends StatelessWidget {
  const NextPrayerCard({
    required this.schedule,
    required this.now,
    required this.location,
    this.showOverview = false,
    super.key,
  });

  final PrayerSchedule schedule;
  final DateTime now;
  final String location;
  final bool showOverview;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final clock = DateFormat.jm(locale);
    final number = decimalFormat(locale);
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final minutes = (schedule.next.time.difference(now).inSeconds / 60).ceil();
    final remaining = minutes < 60
        ? l10n.prayerMinutesLeft(number.format(minutes))
        : l10n.prayerHoursLeft(
            number.format(minutes ~/ 60),
            number.format(minutes % 60),
          );
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: AppRadii.xlAll,
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [BrandColors.primaryGreen, BrandColors.heroGreenEnd],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: BrandColors.ivory),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l10n.nextPrayer} · $location'),
              const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      prayerName(schedule.next.slot, l10n),
                      style: text.headlineMedium?.copyWith(
                        color: BrandColors.ivory,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    clock.format(schedule.next.time),
                    style: text.titleLarge?.copyWith(color: BrandColors.ivory),
                  ),
                ],
              ),
              Text(
                remaining,
                style: const TextStyle(color: BrandColors.goldBright),
              ),
              if (showOverview) ...[
                const SizedBox(height: AppSpacing.sm),
                const Divider(color: BrandColors.goldBright),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final prayer in schedule.today)
                      if (prayer.slot != PrayerSlot.sunrise)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(prayerName(prayer.slot, l10n)),
                            Text(clock.format(prayer.time)),
                          ],
                        ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
