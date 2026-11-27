import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/audio/audio_playback.dart';
import '../../../core/audio/devotional_audio_button.dart';
import '../../../core/content/app_settings.dart';
import '../../../core/content/feature_preview.dart';
import '../../../core/localization/civil_hijri_date.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/brand_season.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../core/widgets/settings_button.dart';
import '../../adhkar/data/quran_dua_index.dart';
import '../../prayer/application/prayer_preferences.dart';
import '../../prayer/domain/prayer_schedule.dart';
import '../../prayer/presentation/next_prayer_card.dart';
import '../../quran/data/mushaf_edition.dart';
import '../../quran/data/quran_services.dart';
import '../../ramadan/presentation/ramadan_screen.dart';
import '../../settings/presentation/settings_updates.dart';
import '../../tasbih/application/tasbih_controller.dart';
import '../../worship/application/cairo_radio_control.dart';
import '../../worship/application/worship_location.dart';
import '../data/daily_duas.dart';
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
    final season = BrandSeason.on(date);
    final hijri = civilHijriDate(date, locale.languageCode);
    final edition = showMushaf
        ? ref.watch(mushafEditionProvider).asData?.value
        : null;
    final settings = ref.watch(appSettingsProvider);
    bool shows(AppFeature feature) => settings.shows(feature);
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          image: season == BrandSeason.regular
              ? null
              : DecorationImage(
                  image: AssetImage(
                    season.asset(
                      'screen-background',
                      dark: theme.brightness == Brightness.dark,
                    ),
                  ),
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Image.asset(
                season.asset('logo', dark: theme.brightness == Brightness.dark),
                width: 46,
                height: 46,
                semanticLabel: l10n.appTitle,
              ),
              actions: [
                if (shows(AppFeature.stats))
                  IconButton(
                    tooltip: l10n.statsTitle,
                    onPressed: () => context.push(AppRoutes.stats),
                    icon: const Icon(Icons.insights_outlined),
                  ),
                if (shows(AppFeature.search))
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
                    season: season,
                    gregorian: DateFormat.yMMMMEEEEd(locale.toLanguageTag())
                        .format(date),
                    hijri: hijri,
                    place: location.place?.label(locale.languageCode),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const HomeUpdateBanner(),
                  if (settings.announcement case final announcement?) ...[
                    _AnnouncementCard(announcement: announcement),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _ContinueReading(edition: edition, season: season),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _WorshipTile(schedule: schedule, now: now),
                      ),
                      if (shows(AppFeature.tasbih)) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: _WorshipTile(tasbih: true, now: now)),
                      ],
                    ],
                  ),
                  if (schedule != null &&
                      (!AppSection.adhkar.status.isGated ||
                          managedReleaseEnabled)) ...[
                    const SizedBox(height: AppSpacing.sm),
                    WorshipNowCard(schedule: schedule, now: now),
                    if (shows(AppFeature.ramadan)) RamadanHomeCard(now: now),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.homeQuickAccess,
                    style: theme.textTheme.titleMedium,
                  ),
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
                      if (shows(AppFeature.qibla))
                        _HomeShortcut(
                          Icons.explore_outlined,
                          l10n.sectionQiblaTitle,
                          AppRoutes.qibla,
                          key: const ValueKey('quick-access-AppSection.qibla'),
                        ),
                      if (shows(AppFeature.tasbih))
                        _HomeShortcut(
                          Icons.touch_app_outlined,
                          l10n.tasbihTitle,
                          AppRoutes.tasbih,
                          key: const ValueKey('quick-access-tasbih'),
                        ),
                      if (shows(AppFeature.radio))
                        _HomeShortcut(
                          cairoRadioOn(ref.watch(audioPlaybackProvider))
                              ? Icons.stop_circle_outlined
                              : Icons.radio_outlined,
                          l10n.homeRadio,
                          AppRoutes.cairoRadio,
                          key: const ValueKey('quick-access-radio'),
                          onTap: () => toggleCairoRadio(context, ref),
                        ),
                      _HomeShortcut(
                        Icons.wb_twilight,
                        l10n.homeMorning,
                        AppRoutes.morningAdhkar,
                      ),
                      if (shows(AppFeature.hadith))
                        _HomeShortcut(
                          Icons.format_quote_outlined,
                          l10n.sectionHadithTitle,
                          AppRoutes.hadith,
                        ),
                      if (shows(AppFeature.stories))
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
                    _DuaOfDay(day: date),
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
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.gregorian,
    required this.season,
    this.hijri,
    this.place,
  });

  final BrandSeason season;

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
              Tooltip(
                message: l10n.homeApproximateHijriDate,
                child: Text(
                  hijri == null ? gregorian : '$gregorian · $hijri',
                  key: const ValueKey('home-today-date'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                switch (season) {
                  BrandSeason.regular => l10n.homeGreeting,
                  BrandSeason.ramadan =>
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'رمضان كريم'
                        : 'Ramadan Kareem',
                  BrandSeason.eid =>
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'عيد مبارك'
                        : 'Eid Mubarak',
                },
                style: theme.textTheme.headlineLarge?.merge(
                  AppTheme.headingStyle(FontWeight.w800),
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
  const _HomeShortcut(
    this.icon,
    this.label,
    this.route, {
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String route;

  /// Acts in place instead of opening [route] (the radio).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iconFile = switch (route) {
      AppRoutes.dailyReading => '1_book',
      AppRoutes.qibla => '2_compass',
      AppRoutes.tasbih => '3_hand',
      AppRoutes.cairoRadio when icon == Icons.radio_outlined => '4_radio',
      AppRoutes.morningAdhkar => '5_sun',
      AppRoutes.hadith => '6_quote',
      AppRoutes.stories => '7_story',
      AppRoutes.reminders => '8_bell',
      _ => null,
    };
    final tone = theme.brightness == Brightness.dark ? 'dark' : 'light';
    return Semantics(
      button: true,
      child: InkWell(
        borderRadius: AppRadii.lgAll,
        onTap:
            onTap ??
            () {
              if (route == AppRoutes.dailyReading ||
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
              if (iconFile != null)
                Image.asset(
                  'assets/brand/shortcuts/qa_${iconFile}_$tone.png',
                  width: 52,
                  height: 52,
                  excludeFromSemantics: true,
                )
              else
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
  const _ContinueReading({required this.edition, required this.season});

  final BrandSeason season;

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
    final theme = Theme.of(context);
    final colors = switch (season) {
      BrandSeason.regular => const [Color(0xFF3A2A99), Color(0xFF1F1558)],
      BrandSeason.ramadan => const [Color(0xFF14606B), Color(0xFF0A2230)],
      BrandSeason.eid => const [Color(0xFF0E8A62), Color(0xFF063D2C)],
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
          ),
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              end: -35,
              bottom: -15,
              width: 210,
              child: Image.asset(
                BrandSeason.regular.asset(
                  'book',
                  dark: theme.brightness == Brightness.dark,
                ),
                excludeFromSemantics: true,
              ),
            ),
            FractionallySizedBox(
              widthFactor: 0.62,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homeContinueReading,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    if (verse != null)
                      Text(
                        book!.surahs[verse.surah - 1].name(locale),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _WorshipTile extends ConsumerWidget {
  const _WorshipTile({required this.now, this.schedule, this.tasbih = false});

  final DateTime now;
  final PrayerSchedule? schedule;
  final bool tasbih;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = schedule?.next;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final remaining = next?.time.difference(now);
    final state = tasbih ? ref.watch(tasbihProvider) : null;
    final number = decimalFormat(language).format;
    return Card(
      child: InkWell(
        onTap: () {
          if (tasbih) {
            context.push(AppRoutes.tasbih);
          } else {
            context.go(AppRoutes.prayerTimes);
          }
        },
        child: SizedBox(
          height: 128,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (remaining != null)
                  SizedBox.square(
                    dimension: 99,
                    child: CircularProgressIndicator(
                      value: (1 - remaining.inMinutes / 360)
                          .clamp(.02, 1)
                          .toDouble(),
                      strokeWidth: 5,
                      strokeCap: StrokeCap.round,
                      backgroundColor: theme.colorScheme.primaryContainer,
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (next == null && state == null)
                      const Icon(Icons.mosque_outlined),
                    Text(
                      state != null
                          ? l10n.tasbihTitle
                          : next == null
                          ? l10n.sectionPrayerTimesTitle
                          : prayerName(next.slot, l10n),
                      style: theme.textTheme.titleMedium,
                    ),
                    if (remaining != null)
                      Text(
                        clockDuration(remaining, language, seconds: false),
                        key: const Key('next-prayer-countdown'),
                        textDirection: TextDirection.ltr,
                      ),
                    if (state != null)
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: const Alignment(-.45, -.5),
                            colors: [
                              theme.colorScheme.primaryContainer,
                              theme.colorScheme.primary,
                            ],
                          ),
                        ),
                        child: Text(
                          number(state.day == tasbihDay(now) ? state.today : 0),
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    if (state != null && state.goal > 0)
                      Text(
                        number(state.goal),
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ],
            ),
          ),
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
  const _DuaOfDay({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(dailyDuasProvider).asData?.value ?? bundledDailyDuas;
    final dua = dailyDuaForCivilDay(day, list);
    final recording = ref.watch(dailyDuaRecordingsProvider)[dua.id];
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.homeDuaOfDay,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              dua.ar,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: AppTheme.quranFontFamily,
                fontSize: 22,
                height: 1.65,
              ),
            ),
            if (!ar) Text(dua.en),
            Text(ar ? dua.sourceAr : dua.sourceEn),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => context.go(AppRoutes.listeningDuas),
                    icon: const Icon(Icons.headphones),
                    label: Text(ar ? 'أدعية مسموعة' : 'Listen to duas'),
                  ),
                ),
                if (recording != null)
                  DevotionalAudioButton(
                    recording: recording,
                    title: ar ? dua.ar : dua.en,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The dashboard's announcement, shown until its end date.
class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final link = announcement.link;
    return Card(
      key: const ValueKey('home-announcement'),
      margin: EdgeInsets.zero,
      color: scheme.tertiaryContainer,
      child: ListTile(
        leading: Icon(
          Icons.campaign_outlined,
          color: scheme.onTertiaryContainer,
        ),
        title: Text(
          ar ? announcement.ar : announcement.en,
          style: TextStyle(color: scheme.onTertiaryContainer),
        ),
        trailing: link == null
            ? null
            : Icon(Icons.open_in_new, color: scheme.onTertiaryContainer),
        onTap: link == null
            ? null
            : () => launchUrl(link, mode: LaunchMode.externalApplication),
      ),
    );
  }
}
