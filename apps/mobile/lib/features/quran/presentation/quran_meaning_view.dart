import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/l10n_extension.dart';
import '../data/quran_enc.dart';

class QuranMeaningView extends ConsumerWidget {
  const QuranMeaningView({
    super.key,
    required this.surah,
    required this.first,
    required this.last,
    required this.count,
  });

  final int surah;
  final int first;
  final int last;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final meaning = ref.watch(quranEnglishMeaningProvider(surah));
    Widget unavailable() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.duaTranslationUnavailable),
        TextButton(
          onPressed: () => ref.invalidate(quranEnglishMeaningProvider(surah)),
          child: Text(l10n.readerRetry),
        ),
      ],
    );
    return meaning.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => unavailable(),
      data: (chapter) {
        if (chapter.verses.length != count || first < 1 || last > count) {
          return unavailable();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var ayah = first; ayah <= last; ayah++) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  chapter.verses[ayah]!.text,
                  textDirection: TextDirection.ltr,
                ),
              ),
              if (chapter.verses[ayah]!.footnotes.isNotEmpty)
                Text(
                  chapter.verses[ayah]!.footnotes,
                  style: Theme.of(context).textTheme.bodySmall,
                  textDirection: TextDirection.ltr,
                ),
            ],
            TextButton(
              onPressed: () => launchUrl(
                Uri.https('quranenc.com', '/en/browse/english_rwwad'),
              ),
              child: Text('${l10n.duaTranslationSource} · ${chapter.version}'),
            ),
          ],
        );
      },
    );
  }
}
