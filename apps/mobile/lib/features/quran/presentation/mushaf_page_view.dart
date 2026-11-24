import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../../core/theme/app_theme.dart';
import '../application/reading_preferences.dart';
import '../data/mushaf_edition.dart';
import '../domain/quran_storage_contracts.dart';

class MushafPageView extends StatefulWidget {
  const MushafPageView({
    required super.key,
    required this.edition,
    required this.index,
    required this.onVerse,
    required this.onChooseVerse,
    this.selected,
    this.preferences = (
      fontSize: defaultReadingFontSize,
      paper: ReadingPaper.auto,
    ),
  });

  final MushafEdition edition;
  final int index;
  final AyahRef? selected;
  final ValueChanged<AyahRef> onVerse;
  final VoidCallback onChooseVerse;

  /// The reader's text size and page background.
  final ReadingPreferences preferences;

  @override
  State<MushafPageView> createState() => MushafPageViewState();
}

class MushafPageViewState extends State<MushafPageView> {
  final _paragraphs = <int, GlobalKey>{};
  final _recognizers = <AyahRef, LongPressGestureRecognizer>{};
  final _ranges = <AyahRef, ({int surah, int start, int end})>{};

  @override
  void dispose() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    super.dispose();
  }

  Iterable<Rect> _boxes(AyahRef verse) sync* {
    final range = _ranges[verse];
    if (range == null) return;
    final paragraph = _paragraphs[range.surah]?.currentContext
        ?.findRenderObject();
    if (paragraph is! RenderParagraph || !paragraph.hasSize) return;
    for (final box in paragraph.getBoxesForSelection(
      TextSelection(baseOffset: range.start, extentOffset: range.end),
    )) {
      yield box.toRect().shift(paragraph.localToGlobal(Offset.zero));
    }
  }

  Rect? get _viewport {
    final render = context.findRenderObject();
    if (render == null) return null;
    if (RenderAbstractViewport.maybeOf(render) case final RenderBox viewport
        when viewport.hasSize) {
      return viewport.localToGlobal(Offset.zero) & viewport.size;
    }
    return null;
  }

  AyahRef? firstVisibleVerse() {
    final viewport = _viewport;
    if (viewport == null) return null;
    for (final verse in _ranges.keys) {
      if (_boxes(verse).any(viewport.overlaps)) return verse;
    }
    return null;
  }

  void reveal(AyahRef verse) {
    final viewport = _viewport;
    final box = _boxes(verse).firstOrNull;
    if (viewport == null || box == null || viewport.contains(box.center)) {
      return;
    }
    final position = Scrollable.of(context).position;
    final offset = position.pixels + box.top - viewport.top - 12;
    position.jumpTo(
      offset.clamp(position.minScrollExtent, position.maxScrollExtent),
    );
  }

  List<InlineSpan> _verseSpans(
    List<MushafVerse> verses,
    Color highlight,
    Color numberColor,
  ) {
    final numbers = decimalFormat('ar');
    final spans = <InlineSpan>[];
    final basmala = widget.edition.surahs.first.verses.first;
    var index = 0;
    for (final verse in verses) {
      final ref = verse.ref;
      final text =
          ref.surah > 1 && ref.ayah == 1 && verse.text.startsWith('$basmala ')
          ? verse.text.substring(basmala.length + 1)
          : verse.text;
      final marker = '\u06dd${numbers.format(ref.ayah)}';
      final display = '$text $marker';
      final recognizer = _recognizers.putIfAbsent(
        ref,
        LongPressGestureRecognizer.new,
      );
      recognizer.onLongPress = () => widget.onVerse(ref);
      _ranges[ref] = (
        surah: ref.surah,
        start: index,
        end: index + display.length,
      );
      spans
        ..add(
          TextSpan(
            style: ref == widget.selected
                ? TextStyle(backgroundColor: highlight)
                : null,
            children: [
              TextSpan(text: '$text ', recognizer: recognizer),
              TextSpan(
                text: marker,
                style: TextStyle(color: numberColor),
                recognizer: recognizer,
              ),
            ],
          ),
        )
        ..add(const TextSpan(text: ' '));
      index += display.length + 1;
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (:paper, :ink, :border, :banner) = paperColors(
      widget.preferences.paper,
      theme,
    );
    final quranStyle = TextStyle(
      fontFamily: AppTheme.quranFontFamily,
      fontSize: widget.preferences.fontSize,
      height: 1.9,
      color: ink,
    );
    final verses = widget.edition.page(widget.index);
    final groups = <int, List<MushafVerse>>{};
    for (final verse in verses) {
      groups.putIfAbsent(verse.ref.surah, () => <MushafVerse>[]).add(verse);
    }
    _ranges.clear();
    final locale = Localizations.localeOf(context).languageCode;
    final numbers = decimalFormat(locale);
    final first = verses.first.ref;
    final juz = numbers.format(widget.edition.juzOf(first) + 1);
    final lastJuz = numbers.format(widget.edition.juzOf(verses.last.ref) + 1);
    final page = numbers.format(widget.index + 1);
    final pageSurah = widget.edition.surahs[first.surah - 1].name(locale);
    final basmala = widget.edition.surahs.first.verses.first;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: paper,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: border),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$pageSurah · ${context.l10n.readerJuzLabel(juz == lastJuz ? juz : '$juz–$lastJuz')}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: context.l10n.readerPageActions,
                      onPressed: widget.onChooseVerse,
                      icon: const Icon(Icons.more_horiz),
                      color: ink,
                    ),
                  ],
                ),
                for (final entry in groups.entries) ...[
                  if (entry.value.first.ref.ayah == 1) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: banner,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: border),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '❖  ${widget.edition.surahs[entry.key - 1].arabicName}  ❖',
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: quranStyle.copyWith(
                          fontSize: widget.preferences.fontSize * 0.82,
                        ),
                      ),
                    ),
                    if (entry.key > 1 &&
                        entry.value.first.text.startsWith('$basmala '))
                      Text(
                        basmala,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: quranStyle.copyWith(
                          fontSize: widget.preferences.fontSize * 0.82,
                        ),
                      ),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: RichText(
                      key: _paragraphs.putIfAbsent(entry.key, GlobalKey.new),
                      textDirection: TextDirection.rtl,
                      textAlign: widget.index < 2
                          ? TextAlign.center
                          : TextAlign.justify,
                      textScaler: MediaQuery.textScalerOf(context),
                      text: TextSpan(
                        style: quranStyle,
                        children: _verseSpans(
                          entry.value,
                          colors.secondaryContainer,
                          colors.secondary,
                        ),
                      ),
                    ),
                  ),
                ],
                Row(
                  children: [
                    Expanded(child: Divider(color: border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        page,
                        semanticsLabel: context.l10n.readerPageLabel(page),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: ink,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: border)),
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
