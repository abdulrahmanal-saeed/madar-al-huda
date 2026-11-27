import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/audio/devotional_audio_button.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../data/daily_duas.dart';

class ListeningDuasScreen extends ConsumerWidget {
  const ListeningDuasScreen({this.initialId, super.key});

  final String? initialId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final all = ref.watch(dailyDuasProvider);
    final recordings = ref.watch(dailyDuaRecordingsProvider);
    final entries = all.asData?.value ?? bundledDailyDuas;
    final selected = entries.where((dua) => dua.id == initialId).firstOrNull;
    final ordered = [?selected, ...entries.where((dua) => dua.id != initialId)];
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.listeningDuasTitle)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: ordered.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final dua = ordered[index];
          final recording = recordings[dua.id];
          return Card(
            child: ListTile(
              title: Text(
                dua.ar,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontFamily: AppTheme.quranFontFamily,
                  fontSize: 22,
                  height: 1.65,
                ),
              ),
              subtitle: Text(ar ? dua.sourceAr : '${dua.en}\n${dua.sourceEn}'),
              trailing: recording == null
                  ? null
                  : DevotionalAudioButton(
                      recording: recording,
                      title: ar ? dua.ar : dua.en,
                    ),
            ),
          );
        },
      ),
    );
  }
}
