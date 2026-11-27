import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/content/feature_preview.dart';
import '../../../core/localization/civil_hijri_date.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/madar_panel.dart';
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
  const PrayerTimesScreen({this.showLocationOnOpen = false, super.key});

  final bool showLocationOnOpen;

  @override
  Widget build(BuildContext context) {
    if (AppSection.prayerTimes.status.isGated && !managedReleaseEnabled) {
      return const SectionDetailScaffold(section: AppSection.prayerTimes);
    }
    return _PrayerTimes(showLocationOnOpen: showLocationOnOpen);
  }
}

class _PrayerTimes extends ConsumerStatefulWidget {
  const _PrayerTimes({required this.showLocationOnOpen});

  final bool showLocationOnOpen;

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
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (TickerMode.valuesOf(context).enabled) setState(() {});
    });
    if (widget.showLocationOnOpen) _openLocation();
  }

  @override
  void didUpdateWidget(covariant _PrayerTimes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showLocationOnOpen && !oldWidget.showLocationOnOpen) {
      _openLocation();
    }
  }

  void _openLocation() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showWorshipLocationSheet(context);
      if (mounted && widget.showLocationOnOpen) {
        context.replace(AppRoutes.prayerTimes);
      }
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
      body: MadarBackdrop(
        child: CustomScrollView(
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
                    _Timetable(schedule: shown, today: _offset == 0),
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
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context);
    final next = schedule.next;
    final total = next.time.difference(previous).inSeconds;
    final left = next.time.difference(now);
    final progress = total <= 0
        ? 0.0
        : (1 - left.inSeconds / total).clamp(0.0, 1.0);
    return Center(
      key: const Key('next-prayer-hero'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 222),
        child: AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(
            painter: _RingPainter(
              progress: progress,
              accent: scheme.primary,
              track: scheme.surfaceContainerHighest,
              thumb: scheme.secondary,
              outline: theme.scaffoldBackgroundColor,
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.nextPrayer, style: text.bodySmall),
                    const SizedBox(height: 9),
                    Text(
                      prayerName(next.slot, l10n),
                      style: text.headlineLarge?.copyWith(fontSize: 41),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      DateFormat.jm(locale.toLanguageTag()).format(next.time),
                      style: text.headlineSmall?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.prayerIn(clockDuration(left, locale.languageCode)),
                      key: const Key('next-prayer-countdown'),
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.accent,
    required this.track,
    required this.thumb,
    required this.outline,
  });

  final double progress;
  final Color accent;
  final Color track;
  final Color thumb;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(10);
    const start = -math.pi / 2;
    final sweep = -math.pi * 2 * progress;
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..color = track,
    );
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..color = accent,
    );
    final angle = start + sweep;
    final tip =
        rect.center + Offset(math.cos(angle), math.sin(angle)) * rect.width / 2;
    canvas.drawCircle(tip, 12, Paint()..color = outline);
    canvas.drawCircle(tip, 10, Paint()..color = thumb);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.accent != accent ||
      old.track != track ||
      old.thumb != thumb ||
      old.outline != outline;
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
    final scheme = theme.colorScheme;
    return Row(
      children: [
        IconButton(
          tooltip: l10n.prayerPreviousDay,
          onPressed: offset > -30 ? () => onChange(offset - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ActionChip(
                onPressed: () => onChange(0),
                backgroundColor: offset == 0 ? scheme.primary : null,
                label: Text(
                  l10n.prayerToday,
                  style: TextStyle(
                    color: offset == 0 ? scheme.onPrimary : null,
                  ),
                ),
              ),
              Chip(
                label: Text(
                  DateFormat.MMMEd(locale.toLanguageTag()).format(date),
                ),
              ),
              if (hijri != null) Chip(label: Text(hijri)),
            ],
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
  const _Timetable({required this.schedule, required this.today});

  final PrayerSchedule schedule;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final clock = DateFormat.jm(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return Column(
      children: [
        for (final entry in schedule.today)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: _PrayerTimeRow(
              key: ValueKey('prayer-row-${entry.slot.name}'),
              title: prayerName(entry.slot, l10n),
              time: clock.format(entry.time),
              active: today && entry == schedule.next,
              background: scheme.surfaceContainerLow,
            ),
          ),
      ],
    );
  }
}

class _PrayerTimeRow extends StatelessWidget {
  const _PrayerTimeRow({
    required this.title,
    required this.time,
    required this.active,
    required this.background,
    super.key,
  });

  final String title;
  final String time;
  final bool active;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = theme.textTheme.titleMedium?.copyWith(
      color: active ? scheme.onPrimary : scheme.onSurface,
      fontWeight: FontWeight.w800,
    );
    return Semantics(
      selected: active,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: active ? scheme.primary : background,
          borderRadius: BorderRadius.circular(21),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
          child: Row(
            children: [
              Expanded(child: Text(title, style: style)),
              const SizedBox(width: 8),
              Text(time, style: style),
            ],
          ),
        ),
      ),
    );
  }
}
