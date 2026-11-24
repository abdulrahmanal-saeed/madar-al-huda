import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
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
    final day = adhkarDayKey(DateTime.now());
    final progress = ref.watch(adhkarProgressProvider);
    final current = catalog.groups.firstWhere(
      (group) =>
          group.id == progress.lastGroup ||
          (group.isAfterPrayer &&
              (progress.lastGroup?.startsWith('after-prayer-') ?? false)),
      orElse: () => catalog.groups.first,
    );
    final groups = catalog.groups;
    final number = decimalFormat(language).format;
    final selected = groups.where(
      (group) => progress.groups.contains(group.id),
    );
    final done = selected.where(
      (group) =>
          progress.completedInGroup(day, group) == progress.groupGoal(group),
    );
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        children: [
          AdhkarHero(
            onTap: () => _openGroup(context, current),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.adhkarToday),
                  const SizedBox(height: 6),
                  Text(
                    current.title.inLanguage(language),
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(color: const Color(0xFFF5F0E6)),
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.adhkarResume),
                  Text(
                    l10n.adhkarPosition(
                      number(progress.completedInGroup(day, current)),
                      number(progress.groupGoal(current)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.adhkarToday,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final group in groups)
                  SizedBox(
                    width: (constraints.maxWidth - 8) / 2,
                    child: Card(
                      child: InkWell(
                        onTap: () => _openGroup(context, group),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _dailyIcon(group.id),
                                size: 21,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 5),
                              Text(group.title.inLanguage(language)),
                              Text(
                                l10n.adhkarPosition(
                                  number(progress.completedInGroup(day, group)),
                                  number(progress.groupGoal(group)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              leading: const Icon(Icons.fact_check_outlined),
              title: Text(catalog.sections['routine']!.inLanguage(language)),
              subtitle: Text(
                l10n.adhkarPosition(
                  number(done.length),
                  number(selected.length),
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  openAdhkarPage(context, AdhkarRoutine(catalog: catalog)),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, size) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (id, icon, screen) in [
                  ('hisn', Icons.shield_outlined, HisnScreen(catalog: catalog)),
                  (
                    'merits',
                    Icons.auto_awesome_outlined,
                    MeritsScreen(catalog: catalog),
                  ),
                  ('quranDuas', Icons.menu_book_outlined, const QuranDuas()),
                ])
                  SizedBox(
                    width: size.maxWidth >= 550
                        ? (size.maxWidth - 16) / 3
                        : (size.maxWidth - 8) / 2,
                    child: Card(
                      child: ListTile(
                        leading: Icon(icon),
                        title: Text(catalog.sections[id]!.inLanguage(language)),
                        onTap: () => openAdhkarPage(context, screen),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
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
                    color: const Color(0xFFD4AE63),
                    backgroundColor: const Color(0xFF4C756E),
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
