import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:material_ui/material_ui.dart';

import '../../../core/content/feature_preview.dart';
import '../../../core/localization/civil_hijri_date.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../core/widgets/settings_button.dart';
import '../../adhkar/data/quran_dua_index.dart';
import '../../prayer/application/prayer_preferences.dart';
import '../../prayer/domain/prayer_schedule.dart';
import '../../prayer/presentation/next_prayer_card.dart';
import '../../quran/data/mushaf_edition.dart';
import '../../quran/data/quran_services.dart';
import '../../quran/presentation/quran_meaning_view.dart';
import '../../worship/application/worship_location.dart';
import '../../worship/data/daily_reading_plan.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.clock = DateTime.now});

  final DateTime Function() clock;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (TickerMode.valuesOf(context).enabled) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final now = widget.clock();
    final location = ref.watch(worshipLocationProvider);
    final hanafi = ref.watch(hanafiAsrProvider);
    final point = location.point;
    final country = location.country;
    final showPrayer =
        !AppSection.prayerTimes.status.isGated || featurePreviewEnabled;
    final showMushaf =
        !AppSection.mushaf.status.isGated || featurePreviewEnabled;
    final schedule = showPrayer && point != null && country != null
        ? PrayerSchedule.calculate(
            location: point,
            country: country,
            now: now,
            hanafi: hanafi,
          )
        : null;
    final date = schedule?.today.first.time ?? now;
    final hijri = civilHijriDate(date, locale.languageCode);
    final edition = showMushaf
        ? ref.watch(mushafEditionProvider).asData?.value
        : null;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(l10n.homeGreeting),
            actions: const [SettingsButton()],
          ),
          SliverResponsiveContent(
            sliver: SliverList.list(
              children: [
                Text(
                  DateFormat.yMMMMEEEEd(locale.toLanguageTag()).format(date),
                  key: const ValueKey('home-today-date'),
                  style: theme.textTheme.bodyMedium,
                ),
                if (hijri != null)
                  Tooltip(
                    message: l10n.homeApproximateHijriDate,
                    child: Text(hijri, style: theme.textTheme.bodySmall),
                  ),
                const SizedBox(height: AppSpacing.md),
                if (schedule != null)
                  NextPrayerCard(
                    schedule: schedule,
                    now: now,
                    showOverview: true,
                    location: location.devicePoint == null
                        ? location.city!.label(l10n)
                        : l10n.deviceLocation,
                  )
                else
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.mosque_outlined),
                      title: Text(l10n.sectionPrayerTimesTitle),
                      subtitle: Text(l10n.homeOpenPrayer),
                      onTap: () => context.go(AppRoutes.prayerTimes),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                _ContinueReading(edition: edition),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _HomeShortcut(
                      Icons.menu_book_outlined,
                      l10n.homeWird,
                      AppRoutes.dailyReading,
                    ),
                    _HomeShortcut(
                      Icons.explore_outlined,
                      l10n.sectionQiblaTitle,
                      AppRoutes.qibla,
                      key: const ValueKey('quick-access-AppSection.qibla'),
                    ),
                    _HomeShortcut(
                      Icons.radio,
                      l10n.radioTitle,
                      AppRoutes.cairoRadio,
                    ),
                    _HomeShortcut(
                      Icons.wb_twilight,
                      l10n.homeMorning,
                      AppRoutes.morningAdhkar,
                    ),
                    _HomeShortcut(
                      Icons.format_quote_outlined,
                      l10n.sectionHadithTitle,
                      AppRoutes.hadith,
                    ),
                  ],
                ),
                if (edition != null &&
                    (!AppSection.adhkar.status.isGated ||
                        featurePreviewEnabled)) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _DuaOfDay(edition: edition, day: date),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeShortcut extends StatelessWidget {
  const _HomeShortcut(this.icon, this.label, this.route, {super.key});

  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) => ActionChip(
    avatar: Icon(icon, size: 18),
    label: Text(label),
    onPressed: () {
      if (route == AppRoutes.dailyReading || route == AppRoutes.cairoRadio) {
        context.push(route);
      } else {
        context.go(route);
      }
    },
  );
}

class _ContinueReading extends ConsumerWidget {
  const _ContinueReading({required this.edition});

  final MushafEdition? edition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final number = NumberFormat.decimalPattern(locale).format;
    final book = edition;
    final position = book == null
        ? null
        : ref.watch(lastReadingPositionProvider).asData?.value?.ref;
    final verse = position != null && book!.contains(position)
        ? position
        : null;
    final page = verse == null ? null : book!.pageOf(verse) + 1;
    final plan = ref.watch(dailyReadingPlanProvider);
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.homeContinueReading, style: theme.textTheme.titleMedium),
            if (verse != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.readerPosition(
                  book!.surahs[verse.surah - 1].name(locale),
                  number(verse.ayah),
                  number(page),
                ),
              ),
              Text(l10n.readerJuzLabel(number(book.juzOf(verse) + 1))),
            ],
            if (book != null)
              Text(
                l10n.dailyReadingProgress(
                  number(plan.pagesRead),
                  number(DailyReadingPlanController.totalPages),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: () => context.go(
                verse == null
                    ? AppRoutes.quran
                    : AppRoutes.verse(verse.surah, verse.ayah),
              ),
              child: Text(
                page == null
                    ? l10n.homeReadQuran
                    : l10n.homeOpenPage(number(page)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _dailyDuas = [
  for (final ranges in quranDuaIndex.values)
    for (final range in ranges)
      if (range.first == range.last) range,
];

class _DuaOfDay extends StatelessWidget {
  const _DuaOfDay({required this.edition, required this.day});

  final MushafEdition edition;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final offset = DateTime.utc(
      day.year,
      day.month,
      day.day,
    ).difference(DateTime.utc(2026, 1, 1)).inDays;
    final range = _dailyDuas[offset % _dailyDuas.length];
    final locale = Localizations.localeOf(context).languageCode;
    final numbers = NumberFormat.decimalPattern(locale);
    final surah = edition.surahs[range.surah - 1];
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.homeDuaOfDay,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              surah.verses[range.first - 1],
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: AppTheme.quranFontFamily,
                fontSize: 22,
                height: 1.65,
              ),
            ),
            if (locale == 'en')
              QuranMeaningView(
                surah: range.surah,
                first: range.first,
                last: range.last,
                count: surah.verses.length,
              ),
            Text('${surah.name(locale)} · ${numbers.format(range.first)}'),
            TextButton.icon(
              onPressed: () =>
                  context.go(AppRoutes.verse(range.surah, range.first)),
              icon: const Icon(Icons.menu_book_outlined),
              label: Text(l10n.dailyReadingOpen),
            ),
          ],
        ),
      ),
    );
  }
}
