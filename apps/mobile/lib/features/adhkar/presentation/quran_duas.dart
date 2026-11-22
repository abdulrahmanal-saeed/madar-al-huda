import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/app_locales.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/widgets/settings_button.dart';
import '../../quran/data/mushaf_edition.dart';
import '../../quran/presentation/quran_meaning_view.dart';

enum DuaTopic {
  forgiveness,
  guidance,
  family,
  hardship,
  gratitude,
  worship,
  hereafter,
  protection;

  String title(AppLocalizations l10n) => switch (this) {
    forgiveness => l10n.duaTopicForgiveness,
    guidance => l10n.duaTopicGuidance,
    family => l10n.duaTopicFamily,
    hardship => l10n.duaTopicHardship,
    gratitude => l10n.duaTopicGratitude,
    worship => l10n.duaTopicWorship,
    hereafter => l10n.duaTopicHereafter,
    protection => l10n.duaTopicProtection,
  };
}

typedef DuaRange = ({int surah, int first, int last});

// Original thematic index. Display text is resolved by verse from Tanzil.
const quranDuaIndex = <DuaTopic, List<DuaRange>>{
  DuaTopic.forgiveness: [
    (surah: 3, first: 147, last: 147),
    (surah: 7, first: 23, last: 23),
    (surah: 7, first: 151, last: 151),
    (surah: 11, first: 47, last: 47),
    (surah: 23, first: 109, last: 109),
    (surah: 23, first: 118, last: 118),
    (surah: 40, first: 7, last: 9),
    (surah: 59, first: 10, last: 10),
  ],
  DuaTopic.guidance: [
    (surah: 1, first: 6, last: 7),
    (surah: 3, first: 8, last: 9),
    (surah: 18, first: 10, last: 10),
    (surah: 20, first: 25, last: 28),
    (surah: 20, first: 114, last: 114),
    (surah: 26, first: 83, last: 84),
  ],
  DuaTopic.family: [
    (surah: 3, first: 38, last: 38),
    (surah: 14, first: 40, last: 41),
    (surah: 17, first: 24, last: 24),
    (surah: 21, first: 89, last: 89),
    (surah: 25, first: 74, last: 74),
    (surah: 71, first: 28, last: 28),
  ],
  DuaTopic.hardship: [
    (surah: 2, first: 250, last: 250),
    (surah: 7, first: 126, last: 126),
    (surah: 21, first: 83, last: 83),
    (surah: 21, first: 87, last: 87),
    (surah: 28, first: 21, last: 22),
  ],
  DuaTopic.gratitude: [
    (surah: 5, first: 114, last: 114),
    (surah: 27, first: 19, last: 19),
    (surah: 28, first: 24, last: 24),
    (surah: 46, first: 15, last: 15),
  ],
  DuaTopic.worship: [
    (surah: 2, first: 127, last: 128),
    (surah: 6, first: 162, last: 163),
  ],
  DuaTopic.hereafter: [
    (surah: 2, first: 201, last: 201),
    (surah: 3, first: 193, last: 194),
    (surah: 12, first: 101, last: 101),
    (surah: 25, first: 65, last: 66),
    (surah: 26, first: 85, last: 85),
  ],
  DuaTopic.protection: [
    (surah: 2, first: 286, last: 286),
    (surah: 23, first: 97, last: 98),
    (surah: 113, first: 1, last: 5),
    (surah: 114, first: 1, last: 6),
  ],
};

class QuranDuas extends ConsumerStatefulWidget {
  const QuranDuas({super.key});

  @override
  ConsumerState<QuranDuas> createState() => _QuranDuasState();
}

class _QuranDuasState extends ConsumerState<QuranDuas> {
  DuaTopic? _topic;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final source = ref.watch(mushafEditionProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.duaTitle),
        actions: const [SettingsButton()],
      ),
      body: source.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(mushafEditionProvider),
            child: Text(l10n.readerRetry),
          ),
        ),
        data: (edition) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButton<DuaTopic?>(
                isExpanded: true,
                value: _topic,
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.duaTopics)),
                  for (final topic in DuaTopic.values)
                    DropdownMenuItem(
                      value: topic,
                      child: Text(topic.title(l10n)),
                    ),
                ],
                onChanged: (topic) => setState(() => _topic = topic),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                children: [
                  for (final entry in quranDuaIndex.entries)
                    if (_topic == null || _topic == entry.key)
                      for (final range in entry.value)
                        _DuaCard(
                          key: ValueKey(range),
                          edition: edition,
                          topic: entry.key,
                          range: range,
                        ),
                  TextButton(
                    onPressed: () => launchUrl(Uri.https('tanzil.net')),
                    child: Text(l10n.readerTanzil),
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

class _DuaCard extends StatefulWidget {
  const _DuaCard({
    required super.key,
    required this.edition,
    required this.topic,
    required this.range,
  });

  final MushafEdition edition;
  final DuaTopic topic;
  final DuaRange range;

  @override
  State<_DuaCard> createState() => _DuaCardState();
}

class _DuaCardState extends State<_DuaCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final numbers = NumberFormat.decimalPattern(language);
    final range = widget.range;
    final surah = widget.edition.surahs[range.surah - 1];
    final first = numbers.format(range.first);
    final last = numbers.format(range.last);
    return Card(
      child: ExpansionTile(
        title: Text(surah.name(language)),
        subtitle: Text(
          '${widget.topic.title(l10n)} · ${first == last ? first : '$first–$last'}',
        ),
        onExpansionChanged: (expanded) => setState(() => _expanded = expanded),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          for (var index = range.first - 1; index < range.last; index++)
            Text(
              surah.verses[index],
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 24,
                height: 1.85,
              ),
            ),
          if (_expanded && language == 'en')
            QuranMeaningView(
              surah: range.surah,
              first: range.first,
              last: range.last,
              count: surah.verses.length,
            ),
          TextButton.icon(
            onPressed: () => context.go(
              Uri(
                path: AppRoutes.quran,
                queryParameters: {
                  'surah': '${range.surah}',
                  'ayah': '${range.first}',
                },
              ).toString(),
            ),
            icon: const Icon(Icons.menu_book_outlined),
            label: Text(l10n.duaOpenVerse),
          ),
        ],
      ),
    );
  }
}
