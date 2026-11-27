import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../core/localization/l10n_extension.dart';
import '../core/theme/brand_season.dart';

class StartupSplash extends StatefulWidget {
  const StartupSplash({
    required this.child,
    required this.onDismissed,
    this.season = BrandSeason.regular,
    super.key,
  });

  final Widget child;
  final VoidCallback onDismissed;
  final BrandSeason season;

  @override
  State<StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<StartupSplash> {
  late final Timer _timer;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1800), _dismiss);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _dismiss() {
    if (!_visible) return;
    _timer.cancel();
    setState(() => _visible = false);
    widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ExcludeFocus(
        excluding: _visible,
        child: ExcludeSemantics(
          excluding: _visible,
          child: IgnorePointer(ignoring: _visible, child: widget.child),
        ),
      ),
      if (_visible) _SplashScreen(season: widget.season, onContinue: _dismiss),
    ],
  );
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen({required this.season, required this.onContinue});

  final BrandSeason season;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final background = switch ((season, dark)) {
      (BrandSeason.regular, false) => const Color(0xFFEDEAF6),
      (BrandSeason.regular, true) => const Color(0xFF151220),
      (BrandSeason.ramadan, false) => const Color(0xFFFBF5E6),
      (BrandSeason.ramadan, true) => const Color(0xFF0C1626),
      (BrandSeason.eid, false) => const Color(0xFFF1FAF5),
      (BrandSeason.eid, true) => const Color(0xFF0B1B17),
    };
    return Material(
      color: background,
      child: Semantics(
        image: true,
        button: true,
        label:
            '${l10n.appTitle}. ${l10n.appDedication}. ${l10n.splashContinue}',
        onTap: onContinue,
        excludeSemantics: true,
        child: InkWell(
          onTap: onContinue,
          child: Image.asset(
            season.asset('splash', dark: dark),
            key: const ValueKey('approved-startup-splash'),
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}
