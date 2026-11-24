import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

import '../../../core/content/feature_preview.dart';
import '../../../core/localization/civil_hijri_date.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../core/widgets/settings_button.dart';
import '../../adhkar/data/adhkar_catalog.dart';
import '../../adhkar/data/quran_dua_index.dart';
import '../../prayer/application/prayer_preferences.dart';
import '../../prayer/domain/prayer_schedule.dart';
import '../../prayer/presentation/next_prayer_card.dart';
import '../../quran/data/mushaf_edition.dart';
import '../../quran/data/quran_services.dart';
import '../../quran/presentation/quran_meaning_view.dart';
import '../../ramadan/presentation/ramadan_screen.dart';
import '../../worship/application/worship_location.dart';
import '../../worship/data/daily_reading_plan.dart';
import 'worship_now_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.clock = DateTime.now});

  final DateTime Function() clock;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final Timer _timer;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (TickerMode.valuesOf(context).enabled) setState(() {});
    });
    _lifecycle = AppLifecycleListener(onResume: () => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    _lifecycle.dispose();
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
    final place = ref.watch(prayerPlaceProvider);
    final showPrayer =
        !AppSection.prayerTimes.status.isGated || managedReleaseEnabled;
    final showMushaf =
        !AppSection.mushaf.status.isGated || managedReleaseEnabled;
    final schedule = showPrayer && place != null
        ? PrayerSchedule.calculate(place: place, now: now, hanafi: hanafi)
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
            actions: [
              IconButton(
                key: const ValueKey('home-search'),
                tooltip: l10n.searchTitle,
                onPressed: () => context.push(AppRoutes.search),
                icon: const Icon(Icons.search),
              ),
              const SettingsButton(),
            ],
          ),
          SliverResponsiveContent(
            sliver: SliverList.list(
              children: [
                _HomeHeader(
                  gregorian: DateFormat.yMMMMEEEEd(locale.toLanguageTag())
                      .format(date),
                  hijri: hijri,
                  place: location.place?.label(locale.languageCode),
                ),
                const SizedBox(height: AppSpacing.md),
                if (schedule != null &&
                    (!AppSection.adhkar.status.isGated ||
                        managedReleaseEnabled)) ...[
                  RamadanHomeCard(now: now),
                  WorshipNowCard(schedule: schedule, now: now),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (schedule != null)
                  NextPrayerCard(
                    schedule: schedule,
                    now: now,
                    showOverview: true,
                    location:
                        location.place?.label(locale.languageCode) ??
                        l10n.deviceLocation,
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
                Text(l10n.homeQuickAccess, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.82,
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
                      Icons.touch_app_outlined,
                      l10n.tasbihTitle,
                      AppRoutes.tasbih,
                      key: const ValueKey('quick-access-tasbih'),
                    ),
                    _HomeShortcut(
                      Icons.radio_outlined,
                      l10n.homeRadio,
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
                    _HomeShortcut(
                      Icons.auto_stories_outlined,
                      l10n.sectionStoriesTitle,
                      AppRoutes.stories,
                    ),
                    _HomeShortcut(
                      Icons.notifications_none,
                      l10n.remindersTitle,
                      AppRoutes.reminders,
                    ),
                  ],
                ),
                if (edition != null &&
                    (!AppSection.adhkar.status.isGated ||
                        managedReleaseEnabled)) ...[
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.gregorian, this.hijri, this.place});

  final String gregorian;
  final String? hijri;
  final String? place;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hijri != null)
                Tooltip(
                  message: l10n.homeApproximateHijriDate,
                  child: Text(
                    hijri!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Text(
                gregorian,
                key: const ValueKey('home-today-date'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (place != null)
          ActionChip(
            avatar: Icon(Icons.place_outlined, size: 18, color: scheme.primary),
            label: Text(place!, overflow: TextOverflow.ellipsis),
            onPressed: () => context.go(AppRoutes.prayerTimes),
          ),
      ],
    );
  }
}

class _HomeShortcut extends StatelessWidget {
  const _HomeShortcut(this.icon, this.label, this.route, {super.key});

  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      child: InkWell(
        borderRadius: AppRadii.lgAll,
        onTap: () {
          if (route == AppRoutes.dailyReading ||
              route == AppRoutes.cairoRadio ||
              route == AppRoutes.tasbih ||
              route.startsWith(AppRoutes.settings)) {
            context.push(route);
          } else {
            context.go(route);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: AppRadii.lgAll,
                ),
                child: Icon(icon, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(height: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueReading extends ConsumerWidget {
  const _ContinueReading({required this.edition});

  final MushafEdition? edition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final number = decimalFormat(locale).format;
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
            if (book != null) ...[
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: AppRadii.smAll,
                child: LinearProgressIndicator(
                  value: plan.pagesRead / DailyReadingPlanController.totalPages,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.dailyReadingProgress(
                  number(plan.pagesRead),
                  number(DailyReadingPlanController.totalPages),
                ),
                style: theme.textTheme.bodySmall,
              ),
            ],
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

/// Counts calendar days in UTC so a short or long local DST day still advances once.
DuaRange? duaForCivilDay(DateTime day, Iterable<List<DuaRange>> groups) {
  final unique = {for (final group in groups) ...group}.toList();
  if (unique.isEmpty) return null;
  final offset = DateTime.utc(
    day.year,
    day.month,
    day.day,
  ).difference(DateTime.utc(2026, 1, 1)).inDays;
  return unique[offset % unique.length];
}

class _DuaOfDay extends ConsumerWidget {
  const _DuaOfDay({required this.edition, required this.day});

  final MushafEdition edition;
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index =
        ref.watch(quranDuaIndexProvider).asData?.value ?? quranDuaIndex;
    final range = duaForCivilDay(day, index.values);
    if (range == null) return const SizedBox.shrink();
    final locale = Localizations.localeOf(context).languageCode;
    final numbers = decimalFormat(locale);
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
              surah.verses.sublist(range.first - 1, range.last).join(' '),
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
            Text(
              '${surah.name(locale)} · ${numbers.format(range.first)}'
              '${range.last == range.first ? '' : '–${numbers.format(range.last)}'}',
            ),
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
