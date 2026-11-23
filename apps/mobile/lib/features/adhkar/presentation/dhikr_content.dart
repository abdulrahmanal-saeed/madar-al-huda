import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../../hadith/data/hadeeth_enc.dart';
import '../../quran/data/mushaf_edition.dart';
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

  final int hadith;
  final DhikrEntry? entry;
  final String? period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final arabic = ref.watch(
      hadithDetailProvider((language: 'ar', id: '$hadith')),
    );
    final english = context.adhkarLanguage == 'en';
    final hasDraft = entry?.draftMeaning != null;
    final translation = english && !hasDraft
        ? ref.watch(hadithDetailProvider((language: 'en', id: '$hadith')))
        : null;
    final source = hadith == 65913
        ? Uri.https('sunnah.com', '/bukhari:6324')
        : Uri.https(
            'hadeethenc.com',
            '/${context.adhkarLanguage}/browse/hadith/$hadith',
          );

    final verses = entry?.verses ?? const <VerseRange>[];
    final edition = verses.isEmpty ? null : ref.watch(mushafEditionProvider);
    final quotation = entry?.wording;
    final reading = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontFamily: AppTheme.readingFontFamily,
      fontSize: 23,
      height: 1.75,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      Text(
                        mushaf.surahs[range.surah - 1].verses
                            .sublist(range.first - 1, range.last)
                            .join(' '),
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
            if (english && hasDraft)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '${entry!.draftMeaning!}\n${l10n.adhkarDraftMeaning}',
                ),
              ),
            if (verses.isNotEmpty || quotation != null)
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
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () =>
                    launchUrl(source, mode: LaunchMode.inAppWebView),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(
                  hadith == 65913 ? l10n.adhkarBukhari6324 : 'HadeethEnc',
                ),
              ),
            ),
          ],
        ),
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
