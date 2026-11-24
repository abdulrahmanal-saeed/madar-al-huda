import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/content/feature_preview.dart';
import '../../../core/localization/civil_hijri_date.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../core/widgets/section_detail_scaffold.dart';
import '../../worship/application/worship_location.dart';
import '../../worship/presentation/worship_location_picker.dart';
import '../application/prayer_preferences.dart';
import '../domain/prayer_schedule.dart';
import 'next_prayer_card.dart';
import 'prayer_method_tile.dart';

IconData prayerIcon(PrayerSlot slot) => switch (slot) {
  PrayerSlot.fajr => Icons.wb_twilight,
  PrayerSlot.sunrise => Icons.wb_sunny_outlined,
  PrayerSlot.dhuhr => Icons.light_mode_outlined,
  PrayerSlot.asr => Icons.filter_drama_outlined,
  PrayerSlot.maghrib => Icons.brightness_4_outlined,
  PrayerSlot.isha => Icons.nights_stay_outlined,
};

class PrayerTimesScreen extends StatelessWidget {
  const PrayerTimesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (AppSection.prayerTimes.status.isGated && !managedReleaseEnabled) {
      return const SectionDetailScaffold(section: AppSection.prayerTimes);
    }
    return const _PrayerTimes();
  }
}

class _PrayerTimes extends ConsumerStatefulWidget {
  const _PrayerTimes();

  @override
  ConsumerState<_PrayerTimes> createState() => _PrayerTimesState();
}

class _PrayerTimesState extends ConsumerState<_PrayerTimes> {
  late final Timer _timer;
  bool _saving = false;

  /// Days from today shown in the timetable.
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (TickerMode.valuesOf(context).enabled) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _setHanafi(bool value) async {
    setState(() => _saving = true);
    try {
      await ref.read(hanafiAsrProvider.notifier).select(value);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.localSaveFailed)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final place = ref.watch(prayerPlaceProvider);
    final now = DateTime.now();
    final hanafi = ref.watch(hanafiAsrProvider);
    final schedule = place == null
        ? null
        : PrayerSchedule.calculate(place: place, now: now, hanafi: hanafi);
    final shown = place == null || _offset == 0
        ? schedule
        : PrayerSchedule.calculate(
            place: place,
            now: now.add(Duration(days: _offset)),
            hanafi: hanafi,
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sectionPrayerTimesTitle),
        actions: [
          IconButton(
            tooltip: l10n.sectionQiblaTitle,
            onPressed: () => context.push(AppRoutes.qibla),
            icon: const Icon(Icons.explore_outlined),
          ),
          IconButton(
            tooltip: l10n.remindersTitle,
            onPressed: () => context.push(AppRoutes.reminders),
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverResponsiveContent(
            sliver: SliverList.list(
              children: [
                const WorshipLocationPicker(),
                if (AppSection.prayerTimes.status.isGated) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(l10n.prayerPreview, style: theme.textTheme.bodySmall),
                ],
                if (schedule != null && shown != null && place != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _NextPrayerHero(
                    schedule: schedule,
                    previous: _previousEvent(schedule, place, now, hanafi),
                    now: now,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _DayBar(
                    date: shown.today.first.time,
                    offset: _offset,
                    onChange: (offset) => setState(() => _offset = offset),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _Timetable(schedule: shown, now: now, today: _offset == 0),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.prayerSettingsTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PrayerMethodTile(place: place),
                          const Divider(height: 1),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            l10n.prayerAsrCalculation,
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SegmentedButton<bool>(
                            key: const Key('asr-method'),
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(
                                value: false,
                                label: Text(l10n.asrStandard),
                              ),
                              ButtonSegment(
                                value: true,
                                label: Text(l10n.asrHanafi),
                              ),
                            ],
                            selected: {hanafi},
                            onSelectionChanged: _saving
                                ? null
                                : (value) => _setHanafi(value.single),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The prayer time that started the current interval, for the ring.
  DateTime _previousEvent(
    PrayerSchedule schedule,
    PrayerPlace place,
    DateTime now,
    bool hanafi,
  ) {
    final passed = schedule.today.where((event) => !event.time.isAfter(now));
    if (passed.isNotEmpty) return passed.last.time;
    return PrayerSchedule.calculate(
      place: place,
      now: now.subtract(const Duration(days: 1)),
      hanafi: hanafi,
    ).today.last.time;
  }
}

class _NextPrayerHero extends StatelessWidget {
  const _NextPrayerHero({
    required this.schedule,
    required this.previous,
    required this.now,
  });

  final PrayerSchedule schedule;
  final DateTime previous;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final number = decimalFormat(locale);
    final next = schedule.next;
    final total = next.time.difference(previous).inSeconds;
    final left = next.time.difference(now).inSeconds;
    final progress = total <= 0 ? 0.0 : (1 - left / total).clamp(0.0, 1.0);
    final minutes = (left / 60).ceil();
    final remaining = minutes < 60
        ? l10n.prayerMinutesLeft(number.format(minutes))
        : l10n.prayerHoursLeft(
            number.format(minutes ~/ 60),
            number.format(minutes % 60),
          );
    return DecoratedBox(
      key: const Key('next-prayer-hero'),
      decoration: const BoxDecoration(
        borderRadius: AppRadii.xlAll,
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [BrandColors.primaryGreen, BrandColors.heroGreenEnd],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 112,
              child: CustomPaint(
                painter: _RingPainter(progress),
                child: Center(
                  child: Icon(
                    prayerIcon(next.slot),
                    size: 40,
                    color: BrandColors.goldBright,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.nextPrayer,
                    style: text.labelLarge?.copyWith(
                      color: BrandColors.ivory.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    prayerName(next.slot, l10n),
                    style: text.headlineMedium?.copyWith(
                      color: BrandColors.ivory,
                    ),
                  ),
                  Text(
                    DateFormat.jm(locale).format(next.time),
                    style: text.titleLarge?.copyWith(color: BrandColors.ivory),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    remaining,
                    style: text.titleSmall?.copyWith(
                      color: BrandColors.goldBright,
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

class _RingPainter extends CustomPainter {
  const _RingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(6);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = BrandColors.ivory.withValues(alpha: 0.15);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = BrandColors.goldBright;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.date,
    required this.offset,
    required this.onChange,
  });

  final DateTime date;
  final int offset;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final hijri = civilHijriDate(date, locale.languageCode);
    return Row(
      children: [
        IconButton(
          tooltip: l10n.prayerPreviousDay,
          onPressed: offset > -30 ? () => onChange(offset - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: InkWell(
            borderRadius: AppRadii.lgAll,
            onTap: offset == 0 ? null : () => onChange(0),
            child: Column(
              children: [
                Text(
                  offset == 0
                      ? '${l10n.prayerToday} · ${DateFormat.MMMEd(locale.toLanguageTag()).format(date)}'
                      : DateFormat.yMMMMEEEEd(locale.toLanguageTag())
                            .format(date),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall,
                ),
                if (hijri != null)
                  Text(
                    hijri,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.prayerNextDay,
          onPressed: offset < 30 ? () => onChange(offset + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _Timetable extends StatelessWidget {
  const _Timetable({
    required this.schedule,
    required this.now,
    required this.today,
  });

  final PrayerSchedule schedule;
  final DateTime now;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final clock = DateFormat.jm(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (index, entry) in schedule.today.indexed) ...[
            if (index > 0) const Divider(height: 1, indent: 64),
            Builder(
              builder: (context) {
                final next = today && entry == schedule.next;
                final passed = today && !entry.time.isAfter(now);
                final color = next
                    ? scheme.onPrimaryContainer
                    : passed
                    ? scheme.onSurfaceVariant.withValues(alpha: 0.7)
                    : scheme.onSurface;
                return Container(
                  key: ValueKey('prayer-row-${entry.slot.name}'),
                  color: next ? scheme.primaryContainer : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: next
                            ? scheme.primary
                            : scheme.surfaceContainerHighest,
                        foregroundColor: next
                            ? scheme.onPrimary
                            : scheme.onSurfaceVariant,
                        child: Icon(prayerIcon(entry.slot), size: 20),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                prayerName(entry.slot, l10n),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: color,
                                  fontWeight: next ? FontWeight.w700 : null,
                                ),
                              ),
                            ),
                            if (next) ...[
                              const SizedBox(width: AppSpacing.sm),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  borderRadius: AppRadii.lgAll,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xxs,
                                  ),
                                  child: Text(
                                    l10n.prayerNextBadge,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: scheme.onPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        clock.format(entry.time),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: color,
                          fontWeight: next ? FontWeight.w700 : null,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
