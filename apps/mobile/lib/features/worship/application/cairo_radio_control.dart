import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/audio/audio_playback.dart';
import '../../../core/localization/l10n_extension.dart';
import 'cairo_radio_stream.dart';

/// Whether the Cairo radio is playing or connecting.
bool cairoRadioOn(Playback playback) =>
    playback.track?.id == cairoRadioMediaId ||
    playback.pending?.id == cairoRadioMediaId;

bool cairoRadioConnecting(Playback playback) =>
    playback.pending?.id == cairoRadioMediaId;

final _station = Uri.https('misrquran.gov.eg', '/home');

/// Starts the live radio in the app's player, or stops it when it is on.
/// Every radio button in the app (library, home, search, worship) uses
/// this, so there is no separate radio page.
Future<void> toggleCairoRadio(BuildContext context, WidgetRef ref) async {
  final playback = ref.read(audioPlaybackProvider.notifier);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l10n = context.l10n;
  if (cairoRadioOn(ref.read(audioPlaybackProvider))) {
    try {
      await playback.stop();
    } on Object {
      messenger?.showSnackBar(SnackBar(content: Text(l10n.radioStreamFailed)));
    }
    return;
  }
  final stream = ref.read(cairoRadioStreamProvider);
  if (stream != null) {
    try {
      await playback.start(
        MediaItem(
          id: cairoRadioMediaId,
          title: l10n.radioTitle,
          artist: l10n.radioCairo,
          isLive: true,
        ),
        () async => (url: stream, start: null),
      );
      return;
    } on Object {
      // Falls through to the station's own page below.
    }
  }
  messenger?.showSnackBar(
    SnackBar(
      content: Text(l10n.radioStreamFailed),
      action: SnackBarAction(
        label: l10n.radioOpenInBrowser,
        onPressed: () =>
            launchUrl(_station, mode: LaunchMode.externalApplication),
      ),
    ),
  );
}
