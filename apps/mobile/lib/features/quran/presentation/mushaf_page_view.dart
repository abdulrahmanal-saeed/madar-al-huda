import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/l10n_extension.dart';
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
  });

  final MushafEdition edition;
  final int index;
  final AyahRef? selected;
  final ValueChanged<AyahRef> onVerse;
  final VoidCallback onChooseVerse;

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

  List<InlineSpan> _verseSpans(List<MushafVerse> verses, Color highlight) {
    final numbers = NumberFormat.decimalPattern('ar');
    final spans = <InlineSpan>[];
    final basmala = widget.edition.surahs.first.verses.first;
    var index = 0;
    for (final verse in verses) {
      final ref = verse.ref;
      final text =
          ref.surah > 1 && ref.ayah == 1 && verse.text.startsWith('$basmala ')
          ? verse.text.substring(basmala.length + 1)
          : verse.text;
      final display = '$text \u06dd${numbers.format(ref.ayah)}';
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
            text: display,
            style: ref == widget.selected
                ? TextStyle(backgroundColor: highlight)
                : null,
            recognizer: recognizer,
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
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? colors.onSurface : const Color(0xff282117);
    final border = dark ? colors.outline : const Color(0xff806647);
    final paper = dark ? colors.surfaceContainerLow : const Color(0xfffffaf0);
    final quranStyle = TextStyle(
      fontFamily: 'AmiriQuran',
      fontSize: 27,
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
    final numbers = NumberFormat.decimalPattern(locale);
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
            border: Border.all(color: border, width: 2),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(border: Border.all(color: border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$pageSurah · ${context.l10n.readerJuzLabel(juz == lastJuz ? juz : '$juz–$lastJuz')}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: border,
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
                        color: colors.tertiaryContainer.withValues(alpha: .35),
                        border: Border.symmetric(
                          horizontal: BorderSide(color: border),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '❖  ${widget.edition.surahs[entry.key - 1].arabicName}  ❖',
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: quranStyle.copyWith(fontSize: 22),
                      ),
                    ),
                    if (entry.key > 1 &&
                        entry.value.first.text.startsWith('$basmala '))
                      Text(
                        basmala,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: quranStyle.copyWith(fontSize: 22),
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
                          colors.tertiaryContainer,
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
