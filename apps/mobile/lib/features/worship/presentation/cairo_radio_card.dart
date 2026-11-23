import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../quran/presentation/recitation_player.dart';

class CairoRadioCard extends ConsumerStatefulWidget {
  const CairoRadioCard({super.key});

  @override
  ConsumerState<CairoRadioCard> createState() => _CairoRadioCardState();
}

class _CairoRadioCardState extends ConsumerState<CairoRadioCard> {
  static final _station = Uri.https('misrquran.gov.eg', '/home');
  bool _opening = false;

  Future<void> _open(LaunchMode mode) async {
    setState(() => _opening = true);
    try {
      if (mode == LaunchMode.inAppWebView) {
        try {
          await ref.read(pauseQuranRecitationProvider)();
        } on Exception {
          // The official player can still open if the app audio service failed.
        }
      }
      if (!mounted || await launchUrl(_station, mode: mode)) return;
    } on Exception {
      // Provide a manual fallback on devices without a working web activity.
    } finally {
      if (mounted) setState(() => _opening = false);
    }
    if (!mounted) return;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.radioOpenFailed),
        action: mode == LaunchMode.inAppWebView
            ? SnackBarAction(
                label: l10n.radioOpenInBrowser,
                onPressed: () => _open(LaunchMode.externalApplication),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.radio),
      title: Text(context.l10n.radioTitle),
      subtitle: Text(context.l10n.radioOpen),
      trailing: _opening
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.play_circle_outline),
      onTap: _opening ? null : () => _open(LaunchMode.inAppWebView),
    ),
  );
}
