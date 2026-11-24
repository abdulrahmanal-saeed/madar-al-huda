import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/app_locales.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../adhkar/data/adhkar_catalog.dart';
import '../../hadith/data/hadeeth_enc.dart';
import '../../hadith/presentation/hadith_screen.dart';
import '../../quran/data/mushaf_edition.dart';
import '../domain/global_search.dart';

typedef _Place = ({
  String id,
  String route,
  bool push,
  IconData icon,
  String Function(AppLocalizations) label,
});

final List<_Place> _places = [
  (
    id: 'prayer',
    route: AppRoutes.prayerTimes,
    push: false,
    icon: Icons.schedule,
    label: (l) => l.sectionPrayerTimesTitle,
  ),
  (
    id: 'qibla',
    route: AppRoutes.qibla,
    push: false,
    icon: Icons.explore_outlined,
    label: (l) => l.sectionQiblaTitle,
  ),
  (
    id: 'wird',
    route: AppRoutes.dailyReading,
    push: true,
    icon: Icons.menu_book_outlined,
    label: (l) => l.dailyReadingTitle,
  ),
  (
    id: 'tasbih',
    route: AppRoutes.tasbih,
    push: true,
    icon: Icons.touch_app_outlined,
    label: (l) => l.tasbihTitle,
  ),
  (
    id: 'radio',
    route: AppRoutes.cairoRadio,
    push: true,
    icon: Icons.radio_outlined,
    label: (l) => l.radioTitle,
  ),
  (
    id: 'morning',
    route: AppRoutes.morningAdhkar,
    push: false,
    icon: Icons.wb_twilight,
    label: (l) => l.homeMorning,
  ),
  (
    id: 'hadith',
    route: AppRoutes.hadith,
    push: false,
    icon: Icons.format_quote_outlined,
    label: (l) => l.sectionHadithTitle,
  ),
  (
    id: 'stories',
    route: AppRoutes.stories,
    push: false,
    icon: Icons.auto_stories_outlined,
    label: (l) => l.sectionStoriesTitle,
  ),
  (
    id: 'duas',
    route: AppRoutes.quranDuas,
    push: false,
    icon: Icons.volunteer_activism_outlined,
    label: (l) => l.duaTitle,
  ),
  (
    id: 'memorize',
    route: AppRoutes.memorize,
    push: true,
    icon: Icons.psychology_outlined,
    label: (l) => l.memorizeTitle,
  ),
  (
    id: 'stats',
    route: AppRoutes.stats,
    push: true,
    icon: Icons.insights_outlined,
    label: (l) => l.statsTitle,
  ),
  (
    id: 'zakat',
    route: AppRoutes.zakat,
    push: true,
    icon: Icons.calculate_outlined,
    label: (l) => l.zakatTitle,
  ),
  (
    id: 'ramadan',
    route: AppRoutes.ramadan,
    push: true,
    icon: Icons.nightlight_outlined,
    label: (l) => l.ramadanTitle,
  ),
  (
    id: 'reminders',
    route: AppRoutes.reminders,
    push: true,
    icon: Icons.notifications_none,
    label: (l) => l.remindersTitle,
  ),
  (
    id: 'downloads',
    route: AppRoutes.downloads,
    push: true,
    icon: Icons.download_for_offline_outlined,
    label: (l) => l.downloadsTitle,
  ),
  (
    id: 'settings',
    route: AppRoutes.settings,
    push: true,
    icon: Icons.settings_outlined,
    label: (l) => l.settingsTitle,
  ),
];

/// One search for the whole app: sections, surahs, verses, adhkar and
/// hadith topics.
class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _input = TextEditingController();
  Timer? _delay;
  String _query = '';
  bool _allVerses = false;
  GlobalSearchIndex? _index;
  Object? _indexKey;

  @override
  void dispose() {
    _delay?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _changed(String value) {
    _delay?.cancel();
    _delay = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          _query = value;
          _allVerses = false;
        });
      }
    });
  }

  GlobalSearchIndex? _indexFor(
    MushafEdition? edition,
    AdhkarCatalog? adhkar,
    HadithCatalog? hadith,
  ) {
    if (edition == null) return null;
    final key = (edition, adhkar, hadith);
    if (key != _indexKey) {
      final names = [
        lookupAppLocalizations(const Locale('ar')),
        lookupAppLocalizations(const Locale('en')),
      ];
      _index = GlobalSearchIndex(
        edition: edition,
        adhkar: adhkar,
        hadith: hadith,
        shortcuts: [
          for (final place in _places)
            (id: place.id, names: [for (final l in names) place.label(l)]),
        ],
      );
      _indexKey = key;
    }
    return _index;
  }

  void _open(String route, {bool push = false}) =>
      push ? context.push(route) : context.go(route);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    final numbers = decimalFormat(language);
    final edition = ref.watch(mushafEditionProvider).asData?.value;
    final adhkar = ref.watch(adhkarCatalogProvider).asData?.value;
    final hadith = ref.watch(hadithCatalogProvider(language)).asData?.value;
    final index = _indexFor(edition, adhkar, hadith);
    final results = index?.search(_query, verseLimit: _allVerses ? 300 : 20);

    Widget header(String title, IconData icon, [int? count]) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            count == null ? title : '$title (${numbers.format(count)})',
            style: theme.textTheme.titleSmall?.copyWith(color: scheme.primary),
          ),
        ],
      ),
    );

    final children = <Widget>[];
    if (results != null && !results.isEmpty) {
      if (results.shortcuts.isNotEmpty) {
        children
          ..add(header(l10n.searchSections, Icons.apps))
          ..add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final hit in results.shortcuts)
                    for (final place in _places.where((p) => p.id == hit.id))
                      ActionChip(
                        avatar: Icon(place.icon, size: 18),
                        label: Text(place.label(l10n)),
                        onPressed: () => _open(place.route, push: place.push),
                      ),
                ],
              ),
            ),
          );
      }
      if (results.surahs.isNotEmpty) {
        children.add(header(l10n.searchSurahs, Icons.menu_book_outlined));
        for (final surah in results.surahs) {
          children.add(
            ListTile(
              key: ValueKey('search-surah-${surah.id}'),
              leading: CircleAvatar(
                backgroundColor: scheme.secondaryContainer,
                foregroundColor: scheme.onSecondaryContainer,
                child: Text(numbers.format(surah.id)),
              ),
              title: Text(surah.name(language)),
              subtitle: Text(
                l10n.searchVerseCount(numbers.format(surah.verses.length)),
              ),
              onTap: () => _open(AppRoutes.verse(surah.id, 1)),
            ),
          );
        }
      }
      if (results.versesTotal > 0 && edition != null) {
        children.add(
          header(
            l10n.searchVerses,
            Icons.format_align_right,
            results.versesTotal,
          ),
        );
        for (final verse in results.verses) {
          final surah = edition.surahs[verse.ref.surah - 1];
          children.add(
            ListTile(
              key: ValueKey(
                'search-verse-${verse.ref.surah}-${verse.ref.ayah}',
              ),
              title: Text(
                verse.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontFamily: AppTheme.quranFontFamily,
                  fontSize: 19,
                  height: 1.8,
                ),
              ),
              subtitle: Text(
                '${surah.name(language)} ${numbers.format(verse.ref.ayah)}',
              ),
              onTap: () =>
                  _open(AppRoutes.verse(verse.ref.surah, verse.ref.ayah)),
            ),
          );
        }
        if (results.versesTotal > results.verses.length && !_allVerses) {
          children.add(
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: TextButton(
                  onPressed: () => setState(() => _allVerses = true),
                  child: Text(
                    l10n.searchShowAll(numbers.format(results.versesTotal)),
                  ),
                ),
              ),
            ),
          );
        }
      }
      if (results.adhkar.isNotEmpty) {
        children.add(header(l10n.sectionAdhkarTitle, Icons.wb_twilight));
        for (final hit in results.adhkar) {
          children.add(
            ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: Text(hit.entry.title.inLanguage(language)),
              subtitle: Text(hit.group.title.inLanguage(language)),
              onTap: () => _open(AppRoutes.adhkarGroup(hit.group.id)),
            ),
          );
        }
      }
      if (results.hadithTopics.isNotEmpty) {
        children.add(
          header(l10n.searchHadithTopics, Icons.format_quote_outlined),
        );
        for (final topic in results.hadithTopics) {
          children.add(
            ListTile(
              leading: const Icon(Icons.topic_outlined),
              title: Text(topic.title),
              subtitle: Text(
                l10n.hadithCount(numbers.format(topic.count), topic.count),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => HadithListScreen(category: topic),
                ),
              ),
            ),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          key: const Key('global-search'),
          controller: _input,
          autofocus: true,
          onChanged: _changed,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_input.text.isNotEmpty)
            IconButton(
              tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
              onPressed: () {
                _input.clear();
                _changed('');
              },
              icon: const Icon(Icons.close),
            ),
        ],
      ),
      body: index == null
          ? const Center(child: CircularProgressIndicator())
          : _query.trim().isEmpty
          ? _Suggestions(
              onPick: (text) {
                _input.text = text;
                setState(() => _query = text);
              },
            )
          : results == null || results.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(l10n.searchNoResults, textAlign: TextAlign.center),
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              children: children,
            ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final ideas = ar
        ? const [
            'الكهف',
            'الصبر',
            'الرحمن',
            '2:255',
            'الاستغفار',
            'الصلاة',
            'القبلة',
          ]
        : const [
            'Al-Kahf',
            'patience',
            'mercy',
            '2:255',
            'forgiveness',
            'prayer',
            'Qibla',
          ];
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(l10n.searchIntro, style: theme.textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.searchTry, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final idea in ideas)
              ActionChip(label: Text(idea), onPressed: () => onPick(idea)),
          ],
        ),
      ],
    );
  }
}
