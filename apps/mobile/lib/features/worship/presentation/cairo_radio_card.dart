import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/audio/audio_playback.dart';
import '../../../core/localization/l10n_extension.dart';
import '../application/cairo_radio_control.dart';

/// The radio in the worship section: plays or stops in place.
class CairoRadioCard extends ConsumerWidget {
  const CairoRadioCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final playback = ref.watch(audioPlaybackProvider);
    final on = cairoRadioOn(playback);
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: ListTile(
        key: const Key('worship-radio'),
        leading: const Icon(Icons.radar_outlined),
        title: Text(l10n.radioTitle),
        subtitle: Text(
          cairoRadioConnecting(playback)
              ? l10n.radioConnecting
              : on
              ? l10n.radioLive
              : l10n.radioCairo,
        ),
        trailing: Icon(
          on ? Icons.stop_circle_outlined : Icons.play_circle_outline,
          semanticLabel: on ? l10n.radioStop : l10n.radioPlay,
        ),
        onTap: () => toggleCairoRadio(context, ref),
      ),
    );
  }
}
