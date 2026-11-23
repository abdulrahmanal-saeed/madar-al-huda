import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../core/widgets/orbit_motif.dart';
import '../../quran/presentation/recitation_player.dart';

class CairoRadioCard extends StatelessWidget {
  const CairoRadioCard({super.key});

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: ListTile(
      leading: const Icon(Icons.radar_outlined),
      title: Text(context.l10n.radioTitle),
      subtitle: Text(context.l10n.radioCairo),
      trailing: const Icon(Icons.play_circle_outline),
      onTap: () => context.push(AppRoutes.cairoRadio),
    ),
  );
}

class CairoRadioScreen extends ConsumerStatefulWidget {
  const CairoRadioScreen({super.key});

  @override
  ConsumerState<CairoRadioScreen> createState() => _CairoRadioScreenState();
}

class _CairoRadioScreenState extends ConsumerState<CairoRadioScreen> {
  static final _station = Uri.https('misrquran.gov.eg', '/home');
  bool _opening = false;

  Future<void> _open(LaunchMode mode) async {
    setState(() => _opening = true);
    try {
      try {
        await ref.read(pauseQuranRecitationProvider)();
      } on Exception {
        // The station remains usable when the app's audio service fails.
      }
      if (!mounted || await launchUrl(_station, mode: mode)) return;
    } on Exception {
      // Show the browser fallback if the embedded player cannot open.
    } finally {
      if (mounted) setState(() => _opening = false);
    }
    if (!mounted) return;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.radioOpenFailed)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.radioTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          children: [
            ClipRRect(
              borderRadius: AppRadii.xlAll,
              child: ColoredBox(
                color: BrandColors.heroGreenEnd,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Positioned.fill(
                      child: OrbitMotif(color: BrandColors.goldBright),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 48,
                        horizontal: 20,
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.radio,
                            color: BrandColors.goldBright,
                            size: 72,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            l10n.radioTitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: BrandColors.ivory,
                            ),
                          ),
                          Text(
                            l10n.radioCairo,
                            style: const TextStyle(
                              color: BrandColors.goldBright,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _opening ? null : () => _open(LaunchMode.inAppWebView),
              icon: _opening
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(l10n.radioOpen),
            ),
            TextButton.icon(
              onPressed: _opening
                  ? null
                  : () => _open(LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new),
              label: Text(l10n.radioOpenInBrowser),
            ),
          ],
        ),
      ),
    );
  }
}
