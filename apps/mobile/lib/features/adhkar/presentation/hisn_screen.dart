import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/audio/devotional_audio_button.dart';
import '../../quran/domain/quran_search_text.dart';
import '../data/adhkar_catalog.dart';
import '../data/adhkar_progress.dart';
import 'adhkar_widgets.dart';
import 'dhikr_content.dart';

class HisnScreen extends ConsumerStatefulWidget {
  const HisnScreen({required this.catalog, super.key});

  final AdhkarCatalog catalog;

  @override
  ConsumerState<HisnScreen> createState() => _HisnScreenState();
}

class _HisnScreenState extends ConsumerState<HisnScreen> {
  String _query = '';
  bool _favorites = false;

  @override
  Widget build(BuildContext context) {
    final catalog = widget.catalog;
    final language = context.adhkarLanguage;
    final l10n = context.l10n;
    final saved = ref.watch(adhkarProgressProvider).saved;
    final controller = ref.read(adhkarProgressProvider.notifier);
    bool matches(LocalizedLabel title) =>
        quranSearchText(title.ar).contains(_query) ||
        quranSearchText(title.en).contains(_query);

    Widget chapter(int id) {
      final name = catalog.chapterTitles[id].inLanguage(language);
      final favorite = saved.contains('hisn:$id');
      return ListTile(
        title: Text(name),
        trailing: IconButton(
          tooltip: favorite
              ? l10n.adhkarRemoveFavorite
              : l10n.adhkarAddFavorite,
          icon: Icon(favorite ? Icons.favorite : Icons.favorite_border),
          onPressed: () => adhkarSave(
            context,
            controller.setSaved('hisn:$id', selected: !favorite),
          ),
        ),
        onTap: () async {
          final url = Uri.https('hisnmuslim.com', '/i/$language/$id');
          final opened = await launchUrl(url, mode: LaunchMode.inAppWebView);
          if (!opened && context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(l10n.adhkarRetrySource)));
          }
        },
      );
    }

    Widget hadith(int id) {
      final entry =
          [
                ...catalog.groups.expand((group) => group.entries),
                ...catalog.merits,
              ]
              .where(
                (entry) =>
                    entry.variants.any((variant) => variant.hadith == id),
              )
              .firstOrNull;
      final title =
          entry?.title.inLanguage(language) ?? l10n.adhkarHadithNumber('$id');
      return ListTile(
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => openAdhkarPage(
          context,
          _HisnNarration(title: title, id: id, entry: entry),
        ),
      );
    }

    Widget own(DhikrEntry entry) {
      final title = entry.title.inLanguage(language);
      return ListTile(
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            openAdhkarPage(context, _HisnNarration(title: title, entry: entry)),
      );
    }

    final tiles = <Widget>[];
    for (final topic in catalog.hisnTopics) {
      final chapters = topic.chapters
          .where(
            (id) =>
                (!_favorites || saved.contains('hisn:$id')) &&
                (matches(topic.title) || matches(catalog.chapterTitles[id])),
          )
          .toList();
      final owned = topic.entries
          .where(
            (entry) =>
                (!_favorites || saved.contains('own:${entry.id}')) &&
                (matches(topic.title) || matches(entry.title)),
          )
          .toList();
      if (chapters.isEmpty && owned.isEmpty) continue;
      tiles.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            child: ExpansionTile(
              key: ValueKey((topic.title.en, _query.isNotEmpty, _favorites)),
              title: Text(topic.title.inLanguage(language)),
              initiallyExpanded: _query.isNotEmpty || _favorites,
              children: [
                for (final entry in owned) own(entry),
                for (final id in chapters) chapter(id),
                if (!_favorites && _query.isEmpty)
                  for (final id in topic.hadiths) hadith(id),
              ],
            ),
          ),
        ),
      );
    }
    if (_favorites && _query.isEmpty) {
      for (final value in saved.where((value) => value.startsWith('hadith:'))) {
        final id = int.tryParse(value.substring(7));
        if (id != null) tiles.add(Card(child: hadith(id)));
      }
    }
    return AdhkarPage(
      title: catalog.sections['hisn']!.inLanguage(language),
      actions: [
        IconButton(
          tooltip: _favorites ? l10n.duaShowAll : l10n.duaShowSaved,
          icon: Icon(_favorites ? Icons.favorite : Icons.favorite_border),
          onPressed: () => setState(() => _favorites = !_favorites),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        children: [
          Text(l10n.adhkarHisnSubtitle),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              labelText: l10n.adhkarFind,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (value) =>
                setState(() => _query = quranSearchText(value)),
          ),
          const SizedBox(height: 12),
          if (tiles.isEmpty) Text(l10n.adhkarNothingFound),
          ...tiles,
        ],
      ),
    );
  }
}

class _HisnNarration extends ConsumerWidget {
  const _HisnNarration({required this.title, this.id, this.entry});

  final String title;

  /// The narration, or null for an own-text entry.
  final int? id;
  final DhikrEntry? entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final key = id == null ? 'own:${entry?.id}' : 'hadith:$id';
    final saved = ref.watch(adhkarProgressProvider).saved.contains(key);
    return AdhkarPage(
      title: title,
      actions: [
        IconButton(
          tooltip: saved ? l10n.adhkarRemoveFavorite : l10n.adhkarAddFavorite,
          icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
          onPressed: () => adhkarSave(
            context,
            ref
                .read(adhkarProgressProvider.notifier)
                .setSaved(key, selected: !saved),
          ),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DhikrContent(hadith: id, entry: entry),
          if (entry case final selected?)
            if (selected.variants
                    .where((variant) => variant.hadith == id)
                    .firstOrNull
                    ?.recording
                case final recording?)
              DevotionalAudioButton(
                recording: recording,
                title: selected.title.inLanguage(context.adhkarLanguage),
              ),
        ],
      ),
    );
  }
}
