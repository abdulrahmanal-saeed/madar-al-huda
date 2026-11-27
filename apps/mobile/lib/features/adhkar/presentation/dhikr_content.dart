import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/madar_panel.dart';
import '../../hadith/data/hadeeth_enc.dart';
import '../../quran/data/mushaf_edition.dart';
import '../../quran/presentation/basmala_line.dart';
import '../../quran/presentation/quran_meaning_view.dart';
import '../data/adhkar_catalog.dart';
import 'adhkar_widgets.dart';

class DhikrContent extends ConsumerWidget {
  const DhikrContent({
    required this.hadith,
    this.entry,
    this.period,
    super.key,
  });

  /// Null for a dhikr written on the dashboard with its own text.
  final int? hadith;
  final DhikrEntry? entry;
  final String? period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final own = hadith == null;
    final arabic = own
        ? null
        : ref.watch(hadithDetailProvider((language: 'ar', id: '$hadith')));
    final english = context.adhkarLanguage == 'en';
    final hasDraft = entry?.draftMeaning != null;
    final translation = english && !hasDraft && !own
        ? ref.watch(hadithDetailProvider((language: 'en', id: '$hadith')))
        : null;
    final source = entry?.source;

    final verses = entry?.verses ?? const <VerseRange>[];
    final edition = verses.isEmpty ? null : ref.watch(mushafEditionProvider);
    // Quran ranges already provide the complete recitation from the Mushaf.
    final quotation = verses.isEmpty ? entry?.wording : null;
    final reading = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontFamily: AppTheme.readingFontFamily,
      fontSize: 23,
      height: 1.75,
    );
    return MadarPanel(
      radius: const BorderRadiusDirectional.only(
        topStart: Radius.circular(24),
        topEnd: Radius.circular(24),
        bottomStart: Radius.circular(24),
        bottomEnd: Radius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (edition != null)
            edition.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => TextButton(
                onPressed: () => ref.invalidate(mushafEditionProvider),
                child: Text(l10n.readerRetry),
              ),
              data: (mushaf) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final range in verses) ...[
                    if (mushaf.openingBasmala(range.surah, range.first)
                        case final basmala?)
                      BasmalaLine(basmala),
                    Text(
                      numberedQuranRange(
                        mushaf.surahs[range.surah - 1].verses,
                        first: range.first,
                        last: range.last,
                        openingBasmala: mushaf.openingBasmala(
                          range.surah,
                          range.first,
                        ),
                      ),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: reading?.copyWith(
                        fontFamily: AppTheme.quranFontFamily,
                      ),
                    ),
                    if (english)
                      QuranMeaningView(
                        surah: range.surah,
                        first: range.first,
                        last: range.last,
                        count: mushaf.surahs[range.surah - 1].verses.length,
                      ),
                  ],
                ],
              ),
            ),
          if (quotation != null)
            Text(
              quotation,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: reading,
            ),
          if (english && verses.isEmpty && hasDraft)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${entry!.draftMeaning!}\n${l10n.adhkarDraftMeaning}',
              ),
            ),
          if (english && verses.isEmpty && own && entry?.meaning != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(entry!.meaning!),
            ),
          if (arabic == null)
            ...[]
          else if (verses.isNotEmpty || quotation != null)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(l10n.adhkarHadithSource),
              children: [
                _narration(context, arabic, ref, 'ar', reading),
                if (translation != null)
                  _narration(context, translation, ref, 'en', reading),
              ],
            )
          else ...[
            if (period == 'morning' || period == 'evening')
              if (hadith == 5490 || hadith == 3008)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(l10n.adhkarUsePeriodWording),
                ),
            _narration(context, arabic, ref, 'ar', reading),
            if (translation != null)
              _narration(context, translation, ref, 'en', reading),
          ],
          if (source != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                source.inLanguage(context.adhkarLanguage),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          // The book reference stays (part of the narration); the website
          // it came from is credited on the licences page only.
          if (hadith == 65913)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.adhkarBukhari6324,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  Widget _narration(
    BuildContext context,
    AsyncValue<HadithDetail> result,
    WidgetRef ref,
    String language,
    TextStyle? reading,
  ) => result.when(
    loading: () => const LinearProgressIndicator(),
    error: (_, _) => TextButton(
      onPressed: () => ref.invalidate(
        hadithDetailProvider((language: language, id: '$hadith')),
      ),
      child: Text(context.l10n.adhkarRetrySource),
    ),
    data: (item) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            item.text,
            textDirection: language == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
            textAlign: language == 'ar' ? TextAlign.right : TextAlign.left,
            style: reading,
          ),
          if (language == context.adhkarLanguage && item.grade.isNotEmpty)
            Text(
              [item.grade, item.attribution, item.reference]
                  .whereType<String>()
                  .where((value) => value.isNotEmpty)
                  .join(' · '),
            ),
        ],
      ),
    ),
  );
}

/// Uses the same numbered end-of-ayah mark as the Mushaf reader.
String numberedQuranRange(
  List<String> verses, {
  required int first,
  required int last,
  String? openingBasmala,
}) {
  final numbers = decimalFormat('ar');
  return [
    for (var ayah = first; ayah <= last; ayah++)
      '${MushafEdition.withoutOpeningBasmala(verses[ayah - 1], ayah == first ? openingBasmala : null)} \u06dd${numbers.format(ayah)}',
  ].join(' ');
}
