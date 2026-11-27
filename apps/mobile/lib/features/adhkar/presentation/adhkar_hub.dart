import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/madar_panel.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../worship/application/current_worship_moment.dart';
import '../data/adhkar_catalog.dart';
import '../data/adhkar_progress.dart';
import 'adhkar_widgets.dart';
import 'dhikr_reader.dart';
import 'hisn_screen.dart';
import 'merits_screen.dart';
import 'quran_duas.dart';

class AdhkarHub extends ConsumerWidget {
  const AdhkarHub({required this.catalog, super.key});

  final AdhkarCatalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = context.adhkarLanguage;
    final l10n = context.l10n;
    final now = ref.watch(adhkarClockProvider).asData?.value ?? DateTime.now();
    final day = adhkarDayKey(now);
    final progress = ref.watch(adhkarProgressProvider);
    final moment = ref.watch(currentWorshipMomentProvider);
    final current = catalog.groups
        .where((group) => group.id == moment?.groupId)
        .firstOrNull;
    final groups = catalog.groups;
    final number = decimalFormat(language).format;
    final selected = groups.where(
      (group) => progress.groups.contains(group.id),
    );
    final done = selected.where(
      (group) =>
          progress.completedInGroup(day, group) == progress.groupGoal(group),
    );
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final routineTitle = catalog.sections['routine']!.inLanguage(language);
    final cards = [
      for (final group in groups)
        (
          title: group.title.inLanguage(language),
          icon: _dailyIcon(group.id),
          progress: l10n.adhkarPosition(
            number(progress.completedInGroup(day, group)),
            number(progress.groupGoal(group)),
          ),
          active: group == current,
          open: () => _openGroup(context, group),
        ),
      (
        title: routineTitle,
        icon: Icons.menu_book_outlined,
        progress: l10n.adhkarPosition(
          number(done.length),
          number(selected.length),
        ),
        active: false,
        open: () => openAdhkarPage(context, AdhkarRoutine(catalog: catalog)),
      ),
    ];
    return AdhkarPage(
      title: l10n.adhkarHubTitle,
      actions: [
        IconButton(
          tooltip: l10n.adhkarFind,
          onPressed: () =>
              openAdhkarPage(context, HisnScreen(catalog: catalog)),
          icon: const Icon(Icons.search),
        ),
      ],
      body: MadarBackdrop(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            ResponsiveContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (current != null)
                    MadarPanel(
                      radius: const BorderRadius.vertical(
                        top: Radius.circular(104),
                        bottom: Radius.circular(22),
                      ),
                      color: scheme.surfaceContainerHighest,
                      onTap: () => _openGroup(context, current),
                      child: Column(
                        children: [
                          Text(
                            l10n.adhkarToday,
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            current.title.inLanguage(language),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineLarge?.merge(
                              AppTheme.headingStyle(FontWeight.w800),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 6,
                            children: [
                              Text(l10n.adhkarResume),
                              Text(
                                l10n.adhkarPosition(
                                  number(
                                    progress.completedInGroup(day, current),
                                  ),
                                  number(progress.groupGoal(current)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          FilledButton(
                            onPressed: () => _openGroup(context, current),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(120, 44),
                            ),
                            child: Text(l10n.homeNowStart),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, size) => Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final (index, card) in cards.indexed)
                          SizedBox(
                            width: (size.maxWidth - 10) / 2,
                            child: MadarPanel(
                              radius: BorderRadiusDirectional.only(
                                topStart: const Radius.circular(19),
                                topEnd: const Radius.circular(19),
                                bottomStart: Radius.circular(
                                  index.isEven ? 19 : 6,
                                ),
                                bottomEnd: Radius.circular(
                                  index.isEven ? 6 : 19,
                                ),
                              ),
                              color: card.active ? scheme.primary : null,
                              padding: const EdgeInsets.all(13),
                              onTap: card.open,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    card.icon,
                                    size: 20,
                                    color: card.active
                                        ? scheme.onPrimary
                                        : scheme.secondary,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    card.title,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: card.active
                                          ? scheme.onPrimary
                                          : scheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    card.progress,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: card.active
                                          ? scheme.onPrimary
                                          : scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (id, screen) in [
                          ('hisn', HisnScreen(catalog: catalog)),
                          ('merits', MeritsScreen(catalog: catalog)),
                          ('quranDuas', const QuranDuas()),
                        ])
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: MadarPanel(
                                radius: BorderRadius.circular(32),
                                padding: const EdgeInsets.all(10),
                                onTap: () => openAdhkarPage(context, screen),
                                child: Center(
                                  child: Text(
                                    catalog.sections[id]!.inLanguage(language),
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleSmall,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
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

IconData _dailyIcon(String group) => switch (group) {
  'morning' => Icons.wb_sunny_outlined,
  'evening' => Icons.nights_stay_outlined,
  'after-prayer' => Icons.mosque_outlined,
  'bedtime' => Icons.bedtime_outlined,
  _ => Icons.alarm_outlined,
};

class AdhkarRoutine extends ConsumerWidget {
  const AdhkarRoutine({required this.catalog, super.key});

  final AdhkarCatalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = this.catalog;
    final language = context.adhkarLanguage;
    final number = decimalFormat(language).format;
    final l10n = context.l10n;
    final date = DateTime.now();
    final day = adhkarDayKey(date);
    final progress = ref.watch(adhkarProgressProvider);
    final controller = ref.read(adhkarProgressProvider.notifier);
    final selected = [
      for (final group in catalog.groups)
        if (progress.groups.contains(group.id)) group,
      for (final entry in catalog.merits)
        if (progress.merits.contains(entry.id)) meritGroup(entry),
    ];
    final finished = selected
        .where(
          (group) =>
              progress.completedInGroup(day, group) ==
              progress.groupGoal(group),
        )
        .length;
    final total = selected.length;
    return AdhkarPage(
      title: catalog.sections['routine']!.inLanguage(language),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        children: [
          AdhkarHero(
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 66,
                  child: CircularProgressIndicator(
                    value: total == 0 ? 0 : finished / total,
                    color: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .outlineVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.adhkarWirdToday(
                          DateFormat.EEEE(language).format(date),
                        ),
                      ),
                      Text(
                        l10n.adhkarPosition(number(finished), number(total)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.adhkarWirdGroups,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (final group in catalog.groups)
                  SwitchListTile(
                    title: Text(group.title.inLanguage(language)),
                    value: progress.groups.contains(group.id),
                    onChanged: (checked) => adhkarSave(
                      context,
                      controller.setGroup(group.id, selected: checked),
                    ),
                  ),
              ],
            ),
          ),
          if (selected.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final group in selected)
              Card(
                child: ListTile(
                  title: Text(group.title.inLanguage(language)),
                  subtitle: Text(
                    l10n.adhkarPosition(
                      number(progress.completedInGroup(day, group)),
                      number(progress.groupGoal(group)),
                    ),
                  ),
                  trailing: const Icon(Icons.play_arrow_outlined),
                  onTap: () => _openGroup(context, group),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

DhikrGroup meritGroup(DhikrEntry entry) =>
    DhikrGroup('merit-${entry.id}', entry.title, [entry]);

Future<void> _openGroup(BuildContext context, DhikrGroup group) =>
    openAdhkarPage(context, adhkarGroupPage(group));

/// The page that opens a remembrance group: after-prayer groups first ask
/// which prayer, the others open the reader directly.
Widget adhkarGroupPage(DhikrGroup group) => group.isAfterPrayer
    ? _PrayerSessions(group: group)
    : DhikrReader(group: group);

class _PrayerSessions extends ConsumerWidget {
  const _PrayerSessions({required this.group});

  final DhikrGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = context.adhkarLanguage;
    final number = decimalFormat(locale).format;
    final names = [
      l10n.prayerFajr,
      l10n.prayerDhuhr,
      l10n.prayerAsr,
      l10n.prayerMaghrib,
      l10n.prayerIsha,
    ];
    final day = adhkarDayKey(DateTime.now());
    final progress = ref.watch(adhkarProgressProvider);
    return AdhkarPage(
      title: group.title.inLanguage(locale),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (var i = 0; i < DhikrGroup.prayers.length; i++)
            Card(
              child: ListTile(
                title: Text(names[i]),
                subtitle: Text(
                  l10n.adhkarPosition(
                    number(
                      progress.completedEntries(
                        day,
                        group.prayerSession(DhikrGroup.prayers[i]),
                      ),
                    ),
                    number(group.entries.length),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => openAdhkarPage(
                  context,
                  DhikrReader(
                    group: group.prayerSession(DhikrGroup.prayers[i]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
