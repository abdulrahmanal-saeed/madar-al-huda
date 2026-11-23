import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/content/feature_preview.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_detail_scaffold.dart';
import '../../worship/data/daily_reading_plan.dart';
import '../application/reading_preferences.dart';
import '../data/chapter_reciters.dart';
import '../data/local_quran_bookmarks.dart';
import '../data/mushaf_edition.dart';
import '../data/quran_services.dart';
import '../domain/quran_storage_contracts.dart';
import 'mushaf_index.dart';
import 'mushaf_page_view.dart';
import 'quran_meaning_view.dart';
import 'reading_settings_sheet.dart';
import 'recitation_player.dart';

class MushafScreen extends ConsumerWidget {
  const MushafScreen({super.key, this.initialVerse});

  final AyahRef? initialVerse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (AppSection.mushaf.status.isGated && !managedReleaseEnabled) {
      return const SectionDetailScaffold(section: AppSection.mushaf);
    }
    final source = ref.watch(_readingProvider);
    final l10n = context.l10n;
    return source.when(
      data: (reading) => _Reader(
        key: ValueKey(initialVerse),
        edition: reading.edition,
        position: initialVerse ?? reading.position?.ref,
      ),
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.navQuran)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.navQuran)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.readerLoadFailed),
              TextButton(
                onPressed: () {
                  ref.invalidate(mushafEditionProvider);
                  ref.invalidate(_readingProvider);
                },
                child: Text(l10n.readerRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _readingProvider =
    FutureProvider.autoDispose<
      ({MushafEdition edition, ReadingPosition? position})
    >((ref) async {
      final position = ref.watch(quranPositionProvider).lastRead();
      return (
        edition: await ref.watch(mushafEditionProvider.future),
        position: await position,
      );
    });

class _Reader extends ConsumerStatefulWidget {
  const _Reader({super.key, required this.edition, required this.position});
  final MushafEdition edition;
  final AyahRef? position;

  @override
  ConsumerState<_Reader> createState() => _ReaderState();
}

class _ReaderState extends ConsumerState<_Reader> {
  late AyahRef _current;
  late int _initialPage;
  AyahRef? _selected;
  final _scroll = ItemScrollController();
  final _positions = ItemPositionsListener.create();
  final _pageKeys = <int, GlobalKey<MushafPageViewState>>{};
  Timer? _settle;
  var _jump = 0;
  var _navigating = false;

  @override
  void initState() {
    super.initState();
    final saved = widget.position;
    _current = saved != null && widget.edition.contains(saved)
        ? saved
        : widget.edition.verses.first.ref;
    _initialPage = widget.edition.pageOf(_current);
    _selected = saved == null ? null : _current;
    _positions.itemPositions.addListener(_trackPosition);
    if (_selected != null) _scheduleReveal(_current);
  }

  @override
  void dispose() {
    _settle?.cancel();
    _positions.itemPositions.removeListener(_trackPosition);
    super.dispose();
  }

  void _trackPosition() {
    if (_navigating) return;
    _settle?.cancel();
    _settle = Timer(const Duration(milliseconds: 180), () {
      final visible =
          _positions.itemPositions.value
              .where(
                (item) => item.itemTrailingEdge > 0 && item.itemLeadingEdge < 1,
              )
              .map((item) => item.index)
              .toList()
            ..sort();
      if (visible.isEmpty) return;
      var first = widget.edition.page(visible.first).first.ref;
      for (final index in visible) {
        final verse = _pageKeys[index]?.currentState?.firstVisibleVerse();
        if (verse != null) {
          first = verse;
          break;
        }
      }
      if (!mounted || first == _current) return;
      final previousPage = widget.edition.pageOf(_current);
      if (widget.edition.pageOf(first) == previousPage + 1) {
        unawaited(
          ref
              .read(dailyReadingPlanProvider.notifier)
              .completePage(previousPage + 1)
              .catchError((Object _) {}),
        );
      }
      setState(() {
        _current = first;
        _selected = null;
      });
      unawaited(_save(first));
    });
  }

  Future<void> _save(AyahRef verse) async {
    try {
      await ref.read(quranPositionProvider).saveLastRead(verse);
      if (mounted) ref.invalidate(lastReadingPositionProvider);
    } catch (_) {
      // A storage failure must leave the open reading session usable.
    }
  }

  void _scheduleReveal(AyahRef verse) {
    final jump = ++_jump;
    _navigating = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || jump != _jump) return;
      final page = widget.edition.pageOf(verse);
      if (widget.edition.pageStarts[page] != widget.edition.indexOf(verse)) {
        _pageKeys[page]?.currentState?.reveal(verse);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && jump == _jump) _navigating = false;
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    });
  }

  void _navigate(AyahRef verse) {
    _settle?.cancel();
    final page = widget.edition.pageOf(verse);
    _scheduleReveal(verse);
    if (_scroll.isAttached) _scroll.jumpTo(index: page);
    setState(() {
      _current = verse;
      _selected = verse;
    });
    unawaited(_save(verse));
  }

  Future<void> _chooseIndex() async {
    final bookmarks =
        ref.read(quranBookmarkListProvider).asData?.value ??
        const <QuranBookmark>[];
    final selected = await showModalBottomSheet<AyahRef>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .95,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(context.l10n.navQuran),
            actions: [const CloseButton()],
          ),
          body: MushafIndex(
            edition: widget.edition,
            bookmarks: bookmarks,
            current: _current,
          ),
        ),
      ),
    );
    if (mounted && selected != null) _navigate(selected);
  }

  Future<void> _chooseAyah() async {
    final surah = widget.edition.surahs[_current.surah - 1];
    final ayah = await showDialog<int>(
      context: context,
      builder: (_) => _VerseDialog(count: surah.verses.length),
    );
    if (mounted && ayah != null) {
      _navigate(
        widget
            .edition
            .verses[widget.edition.surahStarts[surah.id - 1] + ayah - 1]
            .ref,
      );
    }
  }

  Future<void> _choosePageVerse(int index, QuranCatalog? catalog) async {
    final verses = widget.edition.page(index);
    final language = Localizations.localeOf(context).languageCode;
    final numbers = NumberFormat.decimalPattern(language);
    final selected = await showModalBottomSheet<AyahRef>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .7,
        child: ListView(
          children: [
            for (final verse in verses)
              ListTile(
                title: Text(
                  '${widget.edition.surahs[verse.ref.surah - 1].name(language)} · ${numbers.format(verse.ref.ayah)}',
                ),
                subtitle: Text(
                  verse.text,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.pop(context, verse.ref),
              ),
          ],
        ),
      ),
    );
    if (mounted && selected != null) _openTafsir(selected, catalog);
  }

  bool _matches(QuranCatalog? catalog, int surah) =>
      catalog?.ayatBySurah[surah] ==
      widget.edition.surahs[surah - 1].verses.length;

  void _openTafsir(AyahRef verse, QuranCatalog? catalog) {
    _settle?.cancel();
    setState(() {
      _current = verse;
      _selected = verse;
    });
    unawaited(_save(verse));
    final resources = _matches(catalog, verse.surah)
        ? catalog!.tafsirs
        : const <QuranResource>[];
    final selection = ref.read(reciterSelectionProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: .72,
        child: _TafsirSheet(
          edition: widget.edition,
          verse: verse,
          verseText: widget.edition.verses[widget.edition.indexOf(verse)].text,
          surahName: widget.edition.surahs[verse.surah - 1].name(
            Localizations.localeOf(context).languageCode,
          ),
          resources: resources,
          surah: widget.edition.surahs[verse.surah - 1],
          reciters: chapterRecitersFor(
            verse.surah,
            _matches(catalog, verse.surah) ? catalog!.reciters : const [],
            published: selection.active,
            configured: selection.configured,
          ),
          chapterCount: widget.edition.surahs[verse.surah - 1].verses.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    // Keeps the bookmark list loaded for the index sheet without rebuilding
    // the whole reader on every bookmark change; the page header that shows
    // the bookmark state watches it itself.
    ref.listen(quranBookmarkListProvider, (_, _) {});
    final catalog = ref.watch(quranCatalogProvider(language));
    final data = catalog.asData?.value;
    final surah = widget.edition.surahs[_current.surah - 1];
    final matched = _matches(data, surah.id);
    final verifiedReciters = matched ? data!.reciters : const <QuranResource>[];
    final selection = ref.watch(reciterSelectionProvider);
    final reciters = chapterRecitersFor(
      surah.id,
      verifiedReciters,
      published: selection.active,
      configured: selection.configured,
    );
    final numbers = NumberFormat.decimalPattern(language);
    final edition = widget.edition;
    final reading = ref.watch(readingPreferencesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(surah.name(language)),
            Text(
              l10n.readerPageMeta(
                l10n.readerJuzLabel(
                  numbers.format(edition.juzOf(_current) + 1),
                ),
                l10n.readerHizbLabel(
                  numbers.format(edition.hizbOf(_current) + 1),
                ),
                l10n.readerPageLabel(
                  numbers.format(edition.pageOf(_current) + 1),
                ),
                numbers.format(edition.pageStarts.length),
              ),
              style: Theme.of(context).textTheme.labelSmall,
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const ValueKey('reader-appearance'),
            tooltip: l10n.readerAppearance,
            onPressed: () => showReadingSettings(context),
            icon: const Icon(Icons.text_fields),
          ),
          IconButton(
            tooltip: l10n.readerGoToVerse,
            onPressed: _chooseAyah,
            icon: const Icon(Icons.tag),
          ),
          IconButton(
            tooltip: l10n.readerIndex,
            onPressed: _chooseIndex,
            icon: const Icon(Icons.list_alt),
          ),
          IconButton(
            tooltip: l10n.recitationDownloads,
            onPressed: () => showRecitationDownloads(context, edition),
            icon: const Icon(Icons.file_download_outlined),
          ),
          PopupMenuButton<Uri>(
            tooltip: l10n.readerSources,
            onSelected: launchUrl,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: Uri.https('tanzil.net'),
                child: Text(l10n.readerTanzil),
              ),
              PopupMenuItem(
                value: Uri.https('mp3quran.net', '/ar/privacy/'),
                child: const Text('MP3Quran'),
              ),
              if (matched &&
                  (data!.tafsirs.isNotEmpty || verifiedReciters.isNotEmpty))
                PopupMenuItem(
                  value: Uri.https('quran.foundation'),
                  child: Text(l10n.readerQuranFoundation),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ScrollablePositionedList.builder(
                initialScrollIndex: _initialPage,
                itemScrollController: _scroll,
                itemPositionsListener: _positions,
                itemCount: widget.edition.pageStarts.length,
                itemBuilder: (context, index) => MushafPageView(
                  key: _pageKeys.putIfAbsent(
                    index,
                    GlobalKey<MushafPageViewState>.new,
                  ),
                  edition: widget.edition,
                  index: index,
                  selected: _selected,
                  onVerse: (verse) => _openTafsir(verse, data),
                  onChooseVerse: () => _choosePageVerse(index, data),
                  preferences: reading,
                ),
              ),
            ),
            if (!catalog.isLoading &&
                verifiedReciters.isEmpty &&
                (!matched || data!.tafsirs.isEmpty))
              Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      data?.isPreview == true && !matched
                          ? l10n.readerPreliveCoverage
                          : l10n.readerTafsirUnavailable,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.readerRetry,
                    icon: const Icon(Icons.refresh),
                    onPressed: () =>
                        ref.invalidate(quranCatalogProvider(language)),
                  ),
                ],
              ),
            RecitationPlayer(
              edition: edition,
              surah: surah,
              reciters: reciters,
            ),
          ],
        ),
      ),
    );
  }
}

class _VerseDialog extends StatefulWidget {
  const _VerseDialog({required this.count});
  final int count;

  @override
  State<_VerseDialog> createState() => _VerseDialogState();
}

class _VerseDialogState extends State<_VerseDialog> {
  final _form = GlobalKey<FormState>();
  var _value = '';

  static int? _parse(String text) => int.tryParse(
    text.trim().replaceAllMapped(RegExp('[٠-٩۰-۹]'), (match) {
      final digit = match[0]!.codeUnitAt(0);
      return (digit >= 0x6f0 ? digit - 0x6f0 : digit - 0x660).toString();
    }),
  );

  void _submit() {
    if (_form.currentState!.validate()) Navigator.pop(context, _parse(_value));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.readerGoToVerse),
      content: Form(
        key: _form,
        child: TextFormField(
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.readerVerseNumber),
          onChanged: (value) => _value = value,
          onFieldSubmitted: (_) => _submit(),
          validator: (value) {
            final verse = _parse(value ?? '');
            return verse != null && verse >= 1 && verse <= widget.count
                ? null
                : l10n.readerVerseInvalid(widget.count);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.readerCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.readerGo)),
      ],
    );
  }
}

class _TafsirSheet extends ConsumerStatefulWidget {
  const _TafsirSheet({
    required this.edition,
    required this.verse,
    required this.verseText,
    required this.surahName,
    required this.surah,
    required this.reciters,
    required this.resources,
    required this.chapterCount,
  });
  final MushafEdition edition;
  final AyahRef verse;
  final String verseText;
  final String surahName;
  final MushafSurah surah;
  final List<ChapterReciter> reciters;
  final List<QuranResource> resources;
  final int chapterCount;

  @override
  ConsumerState<_TafsirSheet> createState() => _TafsirSheetState();
}

class _TafsirSheetState extends ConsumerState<_TafsirSheet> {
  QuranResource? _resource;
  Future<String>? _text;
  bool _showMeaning = false;

  @override
  void initState() {
    super.initState();
    final source = widget.resources.firstOrNull;
    if (source != null) _load(source);
  }

  void _load(QuranResource resource) {
    _resource = resource;
    _text = ref.read(quranApiProvider).tafsir(widget.verse, resource.id);
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.verseText));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.readerCopied)));
    }
  }

  Future<void> _share() async {
    try {
      await const MethodChannel('madar/share').invokeMethod<void>(
        'shareText',
        '${widget.verseText}\n${widget.surahName} ${widget.verse.surah}:${widget.verse.ayah}',
      );
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.readerShareFailed)));
      }
    }
  }

  Future<void> _toggleBookmark(QuranBookmark? bookmark) async {
    try {
      final repository = ref.read(quranBookmarksProvider);
      if (bookmark == null) {
        await repository.add(widget.verse);
      } else {
        await repository.remove(bookmark.id);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.localSaveFailed)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bookmarks = ref.watch(quranBookmarkListProvider).asData?.value;
    final bookmark = bookmarks
        ?.where((item) => item.ref == widget.verse)
        .firstOrNull;
    final verse = widget.verse;
    final reciter = selectedReciter(ref, widget.reciters);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.surahName} · ${l10n.readerTafsirFor(verse.ayah)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (Localizations.localeOf(context).languageCode == 'en')
                IconButton(
                  tooltip: _showMeaning
                      ? l10n.readerTafsirFor(verse.ayah)
                      : l10n.readerEnglishMeaning,
                  onPressed: () => setState(() => _showMeaning = !_showMeaning),
                  icon: const Icon(Icons.translate),
                ),
              const CloseButton(),
            ],
          ),
          if (!_showMeaning && _resource != null)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final resource in widget.resources)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        label: Text(resource.name),
                        selected: _resource == resource,
                        onSelected: (_) => setState(() => _load(resource)),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      widget.verseText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontFamily: AppTheme.quranFontFamily,
                        fontSize: 22,
                        height: 1.75,
                      ),
                    ),
                  ),
                ),
                if (_showMeaning)
                  QuranMeaningView(
                    surah: verse.surah,
                    first: verse.ayah,
                    last: verse.ayah,
                    count: widget.chapterCount,
                  )
                else if (_text == null)
                  Text(l10n.readerTafsirUnavailable)
                else
                  FutureBuilder<String>(
                    future: _text,
                    builder: (context, state) {
                      if (state.connectionState != ConnectionState.done) {
                        return Text(l10n.readerTafsirLoading);
                      }
                      if (!state.hasData) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.readerTafsirUnavailable),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _load(_resource!)),
                              child: Text(l10n.readerRetry),
                            ),
                          ],
                        );
                      }
                      return Text(
                        state.data!,
                        textDirection: _resource?.language == 'english'
                            ? TextDirection.ltr
                            : TextDirection.rtl,
                      );
                    },
                  ),
              ],
            ),
          ),
          Wrap(
            spacing: 4,
            children: [
              IconButton(
                tooltip: bookmark == null
                    ? l10n.readerAddBookmark
                    : l10n.readerRemoveBookmark,
                onPressed: () => _toggleBookmark(bookmark),
                icon: Icon(
                  bookmark == null ? Icons.bookmark_border : Icons.bookmark,
                ),
              ),
              if (reciter != null)
                IconButton(
                  tooltip: reciter.foundationId != null
                      ? l10n.readerListenFromVerse
                      : l10n.readerListenChapter,
                  icon: const Icon(Icons.play_circle_outline),
                  onPressed: () => playRecitation(
                    context,
                    ref,
                    edition: widget.edition,
                    surah: widget.surah,
                    reader: reciter,
                    verse: reciter.foundationId == null ? null : verse,
                  ),
                ),
              IconButton(
                tooltip: l10n.readerCopy,
                onPressed: _copy,
                icon: const Icon(Icons.copy_outlined),
              ),
              IconButton(
                tooltip: l10n.readerShare,
                onPressed: _share,
                icon: const Icon(Icons.share_outlined),
              ),
            ],
          ),
          if (!_showMeaning && _resource != null)
            TextButton(
              onPressed: () => launchUrl(Uri.https('quran.foundation')),
              child: Text(l10n.readerQuranFoundation),
            ),
        ],
      ),
    );
  }
}
