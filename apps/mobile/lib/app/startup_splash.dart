import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../core/localization/app_locales.dart';
import '../core/localization/l10n_extension.dart';
import '../core/theme/app_theme.dart';

const _background = Color(0xFF0C2B27);
const _gold = Color(0xFFD4AE63);
const _ivory = Color(0xFFF5F0E6);
const _dedicationColor = Color(0xFFEADFC6);

class StartupSplash extends StatefulWidget {
  const StartupSplash({required this.child, super.key});

  final Widget child;

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
    _timer.cancel();
    setState(() => _visible = false);
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
      if (_visible) _SplashScreen(onContinue: _dismiss),
    ],
  );
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final arabic = lookupAppLocalizations(AppLocales.arabic);
    final english = lookupAppLocalizations(AppLocales.english);
    final l10n = context.l10n;
    final showTranslation =
        Localizations.localeOf(context).languageCode == 'en';
    final dedicationStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontFamily: AppTheme.readingFontFamily,
      fontFamilyFallback: const [AppTheme.fontFamily],
      fontSize: 27,
      height: 1.5,
      color: _dedicationColor,
    );
    return Material(
      color: _background,
      child: Semantics(
        button: true,
        label: l10n.splashContinue,
        child: InkWell(
          onTap: onContinue,
          child: CustomPaint(
            painter: const _SplashRings(),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final top = (constraints.maxHeight * 0.29).clamp(24.0, 252.0);
                  final bottom = (constraints.maxHeight * 0.07).clamp(
                    20.0,
                    64.0,
                  );
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24, top, 24, bottom),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: math.max(
                          0.0,
                          constraints.maxHeight - top - bottom,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              const CustomPaint(
                                size: Size.square(136),
                                painter: _SplashMark(),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                arabic.appTitle,
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.center,
                                style: AppTheme.headingStyle(FontWeight.w600)
                                    .copyWith(
                                      fontSize: 46,
                                      height: 1.2,
                                      color: _ivory,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                english.appTitle.toUpperCase(),
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.center,
                                style: AppTheme.headingStyle(FontWeight.w500)
                                    .copyWith(
                                      fontSize: 13,
                                      letterSpacing: 4,
                                      color: _gold,
                                    ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 28),
                            child: Column(
                              children: [
                                const SizedBox(
                                  width: 108,
                                  child: Divider(color: _gold, thickness: 1),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  arabic.appDedication,
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.center,
                                  style: dedicationStyle,
                                ),
                                if (showTranslation)
                                  Text(
                                    english.appDedication,
                                    textAlign: TextAlign.center,
                                    style: dedicationStyle?.copyWith(
                                      fontSize: 19,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashRings extends CustomPainter {
  const _SplashRings();

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(size.width / 2, size.height * 0.38);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final (radius, opacity) in [
      (150.0, 0.16),
      (230.0, 0.10),
      (320.0, 0.06),
      (420.0, 0.04),
    ]) {
      canvas.drawCircle(
        start,
        radius,
        stroke..color = _gold.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SplashRings oldDelegate) => false;
}

class _SplashMark extends CustomPainter {
  const _SplashMark();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 120, size.height / 120);
    const center = Offset(60, 60);
    final stroke = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final fill = Paint()..color = _gold;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 52),
      -math.pi / 6,
      299.5 / 52,
      false,
      stroke,
    );
    canvas.drawCircle(const Offset(96.8, 23.2), 5, fill);
    stroke.strokeWidth = 2.5;
    canvas.translate(center.dx, center.dy);
    const square = Rect.fromLTWH(-23, -23, 46, 46);
    canvas.drawRect(square, stroke);
    canvas.rotate(math.pi / 4);
    canvas.drawRect(square, stroke);
    canvas.drawCircle(Offset.zero, 7, fill);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SplashMark oldDelegate) => false;
}
