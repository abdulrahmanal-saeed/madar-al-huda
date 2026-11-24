import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../prayer/application/prayer_preferences.dart';
import '../../prayer/domain/prayer_schedule.dart';
import '../../quran/data/mushaf_edition.dart';
import '../../worship/application/worship_location.dart';
import '../domain/ramadan.dart';

/// Ramadan days for the current location, or null outside Ramadan or
/// without a location.
final ramadanDaysProvider = Provider.autoDispose
    .family<List<RamadanDay>?, DateTime>((ref, now) {
      final dates = ramadanDates(now);
      if (dates == null) return null;
      final location = ref.watch(worshipLocationProvider);
      final point = location.point;
      final country = location.country;
      if (point == null || country == null) return null;
      final hanafi = ref.watch(hanafiAsrProvider);
      return imsakiya(
        dates,
        (noon) => PrayerSchedule.calculate(
          location: point,
          country: country,
          now: noon,
          hanafi: hanafi,
        ),
      );
    });

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

String _countdown(Duration left, String Function(num) number) {
  final seconds = left.inSeconds.clamp(0, 86400 * 2);
  String two(int value) => number(value).padLeft(2, number(0));
  return '${number(seconds ~/ 3600)}:${two(seconds ~/ 60 % 60)}:${two(seconds % 60)}';
}

/// Shown on the home screen during Ramadan: the next iftar or imsak.
class RamadanHomeCard extends ConsumerWidget {
  const RamadanHomeCard({required this.now, super.key});

  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(ramadanDaysProvider(_today()));
    final state = days == null ? null : ramadanNow(days, now);
    if (state == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final number = decimalFormat(language).format;
    final time = DateFormat.jm(language);
    final left = state.at.difference(now);
    final scheme = theme.colorScheme;
    return Card(
      key: const ValueKey('ramadan-home-card'),
      color: scheme.secondaryContainer,
      child: InkWell(
        onTap: () => context.push(AppRoutes.ramadan),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(Icons.nightlight_round, color: scheme.secondary, size: 32),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.ramadanDay(number(state.day)),
                      style: theme.textTheme.labelLarge,
                    ),
                    Text(
                      state.target == RamadanCountdown.iftar
                          ? l10n.ramadanUntilIftar
                          : l10n.ramadanUntilImsak,
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      '${number(left.inHours)}:${number(left.inMinutes % 60).padLeft(2, number(0))}'
                      ' · ${time.format(state.at)}',
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class RamadanScreen extends ConsumerStatefulWidget {
  const RamadanScreen({super.key, this.clock = DateTime.now});

  final DateTime Function() clock;

  @override
  ConsumerState<RamadanScreen> createState() => _RamadanScreenState();
}

class _RamadanScreenState extends ConsumerState<RamadanScreen> {
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final number = decimalFormat(language).format;
    final time = DateFormat.jm(language);
    final now = widget.clock();
    final today = DateTime(now.year, now.month, now.day);
    final days = ref.watch(ramadanDaysProvider(today));
    final location = ref.watch(worshipLocationProvider);
    final edition = ref.watch(mushafEditionProvider).asData?.value;
    final state = days == null ? null : ramadanNow(days, now);
    final upcoming = days == null ? ramadanDates(now, upcoming: true) : null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ramadanTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.ramadanGreeting,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
                if (location.point == null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.remindersNeedsLocation),
                ] else if (days == null) ...[
                  const SizedBox(height: AppSpacing.md),
                  if (upcoming != null)
                    Text(
                      l10n.ramadanNotNow(
                        DateFormat.yMMMMd(language).format(upcoming.first),
                      ),
                      style: theme.textTheme.bodyLarge,
                    ),
                ] else ...[
                  if (state != null) ...[
                    Text(l10n.ramadanDay(number(state.day))),
                    const SizedBox(height: AppSpacing.md),
                    Card(
                      color: theme.colorScheme.primary,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.target == RamadanCountdown.iftar
                                  ? l10n.ramadanUntilIftar
                                  : l10n.ramadanUntilImsak,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                            Text(
                              _countdown(state.at.difference(now), number),
                              key: const ValueKey('ramadan-countdown'),
                              style: theme.textTheme.displaySmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            Text(
                              state.target == RamadanCountdown.iftar
                                  ? l10n.ramadanMaghrib(time.format(state.at))
                                  : l10n.ramadanImsak(time.format(state.at)),
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (edition != null && state != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _Khatma(day: state.day, edition: edition),
                    const SizedBox(height: AppSpacing.md),
                    _LastTen(day: state.day, edition: edition),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.ramadanImsakiya,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l10n.ramadanImsakNote, style: theme.textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.sm),
                  Card(
                    child: Table(
                      key: const ValueKey('ramadan-imsakiya'),
                      columnWidths: const {0: FlexColumnWidth(1.4)},
                      children: [
                        TableRow(
                          children: [
                            for (final header in [
                              l10n.ramadanColumnDay,
                              l10n.ramadanColumnImsak,
                              l10n.prayerFajr,
                              l10n.prayerMaghrib,
                            ])
                              _cell(header, theme.textTheme.labelMedium),
                          ],
                        ),
                        for (final day in days)
                          TableRow(
                            decoration: BoxDecoration(
                              color: state?.day == day.day
                                  ? theme.colorScheme.primaryContainer
                                  : null,
                            ),
                            children: [
                              _cell(
                                '${number(day.day)} · ${DateFormat.MMMd(language).format(day.date)}',
                                theme.textTheme.bodySmall,
                              ),
                              _cell(
                                time.format(day.imsak),
                                theme.textTheme.bodySmall,
                              ),
                              _cell(
                                time.format(day.fajr),
                                theme.textTheme.bodySmall,
                              ),
                              _cell(
                                time.format(day.maghrib),
                                theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _cell(String text, TextStyle? style) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.sm,
    ),
    child: Text(text, style: style, textAlign: TextAlign.center),
  );
}

/// A juz a day finishes the Quran in the month.
class _Khatma extends StatelessWidget {
  const _Khatma({required this.day, required this.edition});

  final int day;
  final MushafEdition edition;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final number = decimalFormat(language).format;
    final juz = day.clamp(1, edition.juzStarts.length);
    final start = edition.verses[edition.juzStarts[juz - 1]].ref;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.menu_book_outlined),
        title: Text(l10n.ramadanKhatma),
        subtitle: Text(l10n.ramadanKhatmaToday(number(juz))),
        trailing: TextButton(
          onPressed: () => context.go(AppRoutes.verse(start.surah, start.ayah)),
          child: Text(l10n.ramadanOpenJuz),
        ),
      ),
    );
  }
}

class _LastTen extends StatelessWidget {
  const _LastTen({required this.day, required this.edition});

  final int day;
  final MushafEdition edition;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final number = decimalFormat(language).format;
    final inLastTen = day >= 20;
    // Al-Qadr 97:3, from the verified bundled edition.
    final verse = edition.surahs[96].verses[2];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.ramadanLastTen,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              inLastTen
                  ? l10n.ramadanLastTenNow
                  : l10n.ramadanLastTenIn(number(20 - day)),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              verse,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: AppTheme.quranFontFamily,
                fontSize: 22,
                height: 1.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
