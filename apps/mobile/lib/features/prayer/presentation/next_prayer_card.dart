import 'dart:async';

import 'package:intl/intl.dart' show DateFormat;
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

/// «2:05:09» or «5:09», in the language's digits.
String clockDuration(Duration value, String language, {bool seconds = true}) {
  final total = value.inSeconds.abs();
  String two(int n) => n.toString().padLeft(2, '0');
  final hours = total ~/ 3600;
  final minutes = total ~/ 60 % 60;
  final text = seconds
      ? (hours > 0
            ? '$hours:${two(minutes)}:${two(total % 60)}'
            : '$minutes:${two(total % 60)}')
      : '$hours:${two(minutes)}';
  return localizedDigits(text, language);
}

/// Rebuilds every second with the current time, counted from [start] so
/// tests can fix the clock.
class _Ticking extends StatefulWidget {
  const _Ticking({required this.start, required this.builder});

  final DateTime start;
  final Widget Function(BuildContext context, DateTime now) builder;

  @override
  State<_Ticking> createState() => _TickingState();
}

class _TickingState extends State<_Ticking> {
  final _watch = Stopwatch()..start();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && TickerMode.valuesOf(context).enabled) setState(() {});
    });
  }

  @override
  void didUpdateWidget(_Ticking old) {
    super.didUpdateWidget(old);
    if (old.start != widget.start) _watch.reset();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, widget.start.add(_watch.elapsed));
}

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
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;
    final clock = DateFormat.jm(locale.toLanguageTag());
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
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
          child: _Ticking(
            start: now,
            builder: (context, now) {
              final next = schedule.next;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${l10n.nextPrayer} · $location'),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prayerName(next.slot, l10n),
                              style: text.headlineMedium?.copyWith(
                                color: BrandColors.ivory,
                              ),
                            ),
                            Text(
                              clock.format(next.time),
                              style: text.titleMedium?.copyWith(
                                color: BrandColors.ivory,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            l10n.prayerRemaining,
                            style: text.labelMedium?.copyWith(
                              color: BrandColors.ivory.withValues(alpha: 0.8),
                            ),
                          ),
                          Text(
                            clockDuration(next.time.difference(now), language),
                            key: const Key('next-prayer-countdown'),
                            textDirection: TextDirection.ltr,
                            style: text.headlineSmall?.copyWith(
                              color: BrandColors.goldBright,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (showOverview) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(color: BrandColors.goldBright),
                    for (final event in schedule.today)
                      _PrayerLine(
                        event: event,
                        now: now,
                        next: event == next,
                        time: clock.format(event.time),
                      ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PrayerLine extends StatelessWidget {
  const _PrayerLine({
    required this.event,
    required this.now,
    required this.next,
    required this.time,
  });

  final PrayerEvent event;
  final DateTime now;
  final bool next;
  final String time;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final text = Theme.of(context).textTheme;
    final left = event.time.difference(now);
    final passed = left.isNegative;
    final relative = passed
        ? l10n.prayerSince(clockDuration(left, language, seconds: false))
        : l10n.prayerIn(clockDuration(left, language));
    final color = next
        ? BrandColors.goldBright
        : BrandColors.ivory.withValues(alpha: passed ? 0.6 : 1);
    final style = text.bodyMedium?.copyWith(
      color: color,
      fontWeight: next ? FontWeight.w700 : null,
    );
    return Padding(
      key: ValueKey('home-prayer-${event.slot.name}'),
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(prayerName(event.slot, l10n), style: style),
          ),
          SizedBox(width: 72, child: Text(time, style: style)),
          Expanded(
            child: Text(
              relative,
              textAlign: TextAlign.end,
              style: style?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
