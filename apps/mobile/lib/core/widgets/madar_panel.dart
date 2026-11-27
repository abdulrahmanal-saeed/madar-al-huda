import 'package:material_ui/material_ui.dart';

/// The surfaced cards and controls used in the approved light and dark layouts.
class MadarPanel extends StatelessWidget {
  const MadarPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = const BorderRadius.all(Radius.circular(20)),
    this.color,
    this.gradient,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry radius;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final border = BorderSide(
      color: Colors.white.withValues(alpha: dark ? .07 : .78),
    );
    final shadow = dark ? scheme.shadow : scheme.secondary;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: shadow.withValues(alpha: dark ? .36 : .18),
            blurRadius: 16,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: shadow.withValues(alpha: dark ? .18 : .09),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: radius, side: border),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: color,
            gradient:
                gradient ??
                (color == null
                    ? LinearGradient(
                        begin: AlignmentDirectional.topStart,
                        end: AlignmentDirectional.bottomEnd,
                        colors: [
                          scheme.surfaceContainerLow,
                          scheme.surfaceContainer,
                        ],
                      )
                    : null),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class MadarBackdrop extends StatelessWidget {
  const MadarBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: CustomPaint(
            painter: _BackdropPainter(
              glow: scheme.secondary.withValues(alpha: dark ? .14 : .10),
              stroke: scheme.onSurface.withValues(alpha: .085),
              onLeft: Directionality.of(context) == TextDirection.rtl,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter({
    required this.glow,
    required this.stroke,
    required this.onLeft,
  });

  final Color glow;
  final Color stroke;
  final bool onLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width.clamp(0.0, 600.0);
    final center = Offset(onLeft ? width * .16 : size.width - width * .16, 30);
    final radius = width * .51;
    if (radius <= 0) return;
    final fill = Paint()
      ..shader = RadialGradient(colors: [glow, glow.withValues(alpha: 0)])
          .createShader(Rect.fromCircle(center: center, radius: radius * 1.2));
    canvas.drawCircle(center, radius * 1.2, fill);
    final outline = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius * .75, outline);
    canvas.drawCircle(center, radius, outline);
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) =>
      glow != oldDelegate.glow ||
      stroke != oldDelegate.stroke ||
      onLeft != oldDelegate.onLeft;
}
