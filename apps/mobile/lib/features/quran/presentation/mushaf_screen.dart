import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/content/feature_preview.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/widgets/section_detail_scaffold.dart';
import '../../../core/widgets/settings_button.dart';
import '../data/mushaf_edition.dart';
import '../data/quran_services.dart';
import '../domain/quran_storage_contracts.dart';
import 'recitation_player.dart';

class MushafScreen extends ConsumerWidget {
  const MushafScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (AppSection.mushaf.status.isGated && !featurePreviewEnabled) {
      return const SectionDetailScaffold(section: AppSection.mushaf);
    }
    final source = ref.watch(_readingProvider);
    final l10n = context.l10n;
    return source.when(
      data: (reading) =>
          _Reader(edition: reading.edition, position: reading.position),
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
  const _Reader({required this.edition, required this.position});
  final MushafEdition edition;
  final ReadingPosition? position;

  @override
  ConsumerState<_Reader> createState() => _ReaderState();
}

class _ReaderState extends ConsumerState<_Reader> {
  late MushafSurah _surah;
  late int _startingAyah;
  late ItemScrollController _scroll;
  late ItemPositionsListener _positions;
  late int _lastSaved;
  Timer? _settle;

  @override
  void initState() {
    super.initState();
    final saved = widget.position?.ref;
    if (saved != null && widget.edition.contains(saved)) {
      _surah = widget.edition.surahs[saved.surah - 1];
      _startingAyah = saved.ayah;
    } else {
      _surah = widget.edition.surahs.first;
      _startingAyah = 1;
    }
    _lastSaved = _startingAyah;
    _attachList();
  }

  void _attachList() {
    _scroll = ItemScrollController();
    _positions = ItemPositionsListener.create();
    _positions.itemPositions.addListener(_trackPosition);
  }

  @override
  void dispose() {
    _settle?.cancel();
    _positions.itemPositions.removeListener(_trackPosition);
    super.dispose();
  }

  void _trackPosition() {
    final visible = _positions.itemPositions.value
        .where((item) => item.itemTrailingEdge > 0 && item.itemLeadingEdge < 1)
        .map((item) => item.index + 1);
    if (visible.isEmpty) return;
    final first = visible.reduce((a, b) => a < b ? a : b);
    if (first == _lastSaved) return;
    _lastSaved = first;
    _settle?.cancel();
    final surah = _surah.id;
    final repository = ref.read(quranPositionProvider);
    _settle = Timer(const Duration(milliseconds: 200), () {
      unawaited(_save(repository, surah, first));
    });
  }

  Future<void> _save(
    ReadingPositionRepository repository,
    int surah,
    int ayah,
  ) async {
    try {
      await repository.saveLastRead(
        AyahRef(editionId: MushafEdition.id, surah: surah, ayah: ayah),
      );
    } catch (_) {
      // A storage failure must leave the open reading session usable.
    }
  }

  void _navigate(MushafSurah surah, int ayah) {
    _settle?.cancel();
    if (surah == _surah && _scroll.isAttached) {
      _scroll.jumpTo(index: ayah - 1);
    } else {
      _positions.itemPositions.removeListener(_trackPosition);
      setState(() {
        _surah = surah;
        _startingAyah = ayah;
        _attachList();
      });
    }
    _lastSaved = ayah;
    unawaited(_save(ref.read(quranPositionProvider), surah.id, ayah));
  }

  Future<void> _chooseSurah(String locale) async {
    final selected = await showModalBottomSheet<MushafSurah>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .8,
        child: Column(
          children: [
            ListTile(title: Text(context.l10n.readerSurahs)),
            Expanded(
              child: ListView.builder(
                itemCount: widget.edition.surahs.length,
                itemBuilder: (context, index) {
                  final surah = widget.edition.surahs[index];
                  return ListTile(
                    leading: Text(
                      NumberFormat.decimalPattern(locale).format(surah.id),
                    ),
                    title: Text(surah.name(locale)),
                    selected: surah == _surah,
                    onTap: () => Navigator.pop(context, surah),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (mounted && selected != null) _navigate(selected, 1);
  }

  Future<void> _chooseAyah() async {
    final ayah = await showDialog<int>(
      context: context,
      builder: (_) => _VerseDialog(count: _surah.verses.length),
    );
    if (mounted && ayah != null) _navigate(_surah, ayah);
  }

  void _openTafsir(int ayah, List<QuranResource> resources) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: .82,
        child: _TafsirSheet(
          verse: AyahRef(
            editionId: MushafEdition.id,
            surah: _surah.id,
            ayah: ayah,
          ),
          resources: resources,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final numbers = NumberFormat.decimalPattern(language);
    final catalog = ref.watch(quranCatalogProvider(language));
    final data = catalog.asData?.value;
    final matched = data?.ayatBySurah[_surah.id] == _surah.verses.length;
    final tafsirs = matched ? data!.tafsirs : const <QuranResource>[];
    final reciters = matched ? data!.reciters : const <QuranResource>[];
    return Scaffold(
      appBar: AppBar(
        title: Text(_surah.name(language)),
        actions: [
          IconButton(
            tooltip: l10n.readerGoToVerse,
            onPressed: _chooseAyah,
            icon: const Icon(Icons.tag),
          ),
          IconButton(
            tooltip: l10n.readerSurahs,
            onPressed: () => _chooseSurah(language),
            icon: const Icon(Icons.list_alt),
          ),
          const SettingsButton(),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                TextButton(
                  onPressed: () => launchUrl(Uri.https('tanzil.net')),
                  child: Text(l10n.readerTanzil),
                ),
                if (matched && (tafsirs.isNotEmpty || reciters.isNotEmpty))
                  TextButton(
                    onPressed: () => launchUrl(Uri.https('quran.foundation')),
                    child: Text(l10n.readerQuranFoundation),
                  ),
              ],
            ),
            Expanded(
              child: ScrollablePositionedList.builder(
                key: ValueKey(_surah.id),
                initialScrollIndex: _startingAyah - 1,
                itemScrollController: _scroll,
                itemPositionsListener: _positions,
                itemCount: _surah.verses.length,
                itemBuilder: (context, index) {
                  final verse = _surah.verses[index];
                  final ayah = index + 1;
                  void explain() => _openTafsir(ayah, tafsirs);
                  return InkWell(
                    key: ValueKey('ayah-${_surah.id}-$ayah'),
                    onLongPress: explain,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            16,
                            8,
                            16,
                            4,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IconButton(
                                tooltip: l10n.readerTafsirFor(ayah),
                                onPressed: explain,
                                icon: const Icon(Icons.notes),
                              ),
                              Expanded(
                                child: Text(
                                  verse,
                                  textDirection: TextDirection.rtl,
                                  style: const TextStyle(
                                    fontFamily: 'AmiriQuran',
                                    fontSize: 28,
                                    height: 1.9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              end: 20,
                              bottom: 6,
                            ),
                            child: Text(numbers.format(ayah)),
                          ),
                        ),
                        const Divider(height: 1),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (!catalog.isLoading && reciters.isEmpty && tafsirs.isEmpty)
              Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      data?.isPreview == true && !matched
                          ? l10n.readerPreliveCoverage
                          : l10n.readerResourcesUnavailable,
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
              surah: _surah,
              reciters: reciters,
              language: language,
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
  const _TafsirSheet({required this.verse, required this.resources});
  final AyahRef verse;
  final List<QuranResource> resources;

  @override
  ConsumerState<_TafsirSheet> createState() => _TafsirSheetState();
}

class _TafsirSheetState extends ConsumerState<_TafsirSheet> {
  QuranResource? _resource;
  Future<String>? _text;

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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.readerTafsirFor(widget.verse.ayah),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (_resource != null)
            DropdownButton<QuranResource>(
              isExpanded: true,
              value: _resource,
              items: [
                for (final resource in widget.resources)
                  DropdownMenuItem(value: resource, child: Text(resource.name)),
              ],
              onChanged: (resource) {
                if (resource != null) setState(() => _load(resource));
              },
            ),
          Expanded(
            child: ListView(
              children: [
                if (_text == null)
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
          if (_resource != null)
            TextButton(
              onPressed: () => launchUrl(Uri.https('quran.foundation')),
              child: Text(l10n.readerQuranFoundation),
            ),
        ],
      ),
    );
  }
}
