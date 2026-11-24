import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/content/feature_preview.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/localization/numbers.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../core/widgets/section_detail_scaffold.dart';
import '../../worship/application/worship_location.dart';
import '../../worship/presentation/worship_location_picker.dart';
import '../domain/qibla_bearing.dart';

typedef MagneticHeading = ({double degrees, bool reliable});

final magneticHeadingProvider = StreamProvider.autoDispose<MagneticHeading>(
  (_) =>
      const EventChannel('madar/compass')
          .receiveBroadcastStream()
          .map((sample) {
            final data = sample as Map<dynamic, dynamic>;
            return (
              degrees: (data['degrees'] as num).toDouble(),
              reliable: data['reliable'] == true,
            );
          }),
);

final _declinationProvider = FutureProvider.autoDispose
    .family<double?, ({double latitude, double longitude})>(
      (_, point) => const MethodChannel('madar/geomagnetic')
          .invokeMethod<double>('declination', {
            'latitude': point.latitude,
            'longitude': point.longitude,
          }),
    );

/// Great-circle distance to the Kaaba in kilometres.
double distanceToKaaba(GeoCoordinate point) {
  const earth = 6371.0;
  double rad(double degrees) => degrees * math.pi / 180;
  final dLat = rad(QiblaBearing.kaaba.latitude - point.latitude);
  final dLng = rad(QiblaBearing.kaaba.longitude - point.longitude);
  final a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(point.latitude)) *
          math.cos(rad(QiblaBearing.kaaba.latitude)) *
          math.pow(math.sin(dLng / 2), 2);
  return earth * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen> {
  bool _aligned = false;

  @override
  Widget build(BuildContext context) {
    if (AppSection.qibla.status.isGated && !managedReleaseEnabled) {
      return const SectionDetailScaffold(section: AppSection.qibla);
    }
    final location = ref.watch(worshipLocationProvider);
    final point = location.point;
    final bearing = point == null ? null : QiblaBearing.calculate(point);
    final active =
        TickerMode.valuesOf(context).enabled &&
        ModalRoute.isCurrentOf(context) != false;
    final sensor = active && point != null
        ? ref.watch(magneticHeadingProvider)
        : null;
    // City centers can be reconstructed on each build. Key by coordinates
    // so a new sensor reading does not restart the declination request.
    final declination = point == null
        ? null
        : ref.watch(
            _declinationProvider((
              latitude: point.latitude,
              longitude: point.longitude,
            )),
          );
    final heading = sensor?.asData?.value;
    final correction = declination?.asData?.value;
    final trueHeading = heading != null && correction != null
        ? (heading.degrees + correction) % 360
        : null;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    final numbers = decimalFormat(language);
    final rotation = bearing != null && trueHeading != null
        ? (bearing - trueHeading + 540) % 360 - 180
        : null;
    final turn = heading?.reliable == true ? rotation : null;
    final aligned = turn != null && turn.abs() < 3;
    if (aligned != _aligned) {
      _aligned = aligned;
      if (aligned) unawaited(HapticFeedback.mediumImpact());
    }
    final message = switch (heading) {
      (reliable: false, degrees: _) => l10n.compassCalibrate,
      _ when turn != null => l10n.compassHoldFlat,
      _ when sensor?.isLoading == true || declination?.isLoading == true =>
        l10n.compassWaiting,
      _ => l10n.compassUnavailable,
    };

    Widget stat(String label, String value, IconData icon) => Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: scheme.primary),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sectionQiblaTitle)),
      body: CustomScrollView(
        slivers: [
          SliverResponsiveContent(
            sliver: SliverList.list(
              children: [
                const WorshipLocationPicker(),
                const SizedBox(height: AppSpacing.lg),
                if (bearing != null && point != null) ...[
                  Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: aligned
                            ? scheme.primary
                            : scheme.surfaceContainerHighest,
                        borderRadius: AppRadii.xlAll,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            aligned
                                ? Icons.check_circle
                                : turn == null
                                ? Icons.explore_outlined
                                : turn > 0
                                ? Icons.turn_right
                                : Icons.turn_left,
                            size: 20,
                            color: aligned ? scheme.onPrimary : scheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            aligned
                                ? l10n.compassAligned
                                : turn == null
                                ? l10n.trueBearing(
                                    numbers.format(bearing.round() % 360),
                                  )
                                : turn > 0
                                ? l10n.compassTurnRight(
                                    numbers.format(turn.round()),
                                  )
                                : l10n.compassTurnLeft(
                                    numbers.format(turn.abs().round()),
                                  ),
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: aligned ? scheme.onPrimary : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: ExcludeSemantics(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: CustomPaint(
                            key: const Key('qibla-dial'),
                            painter: _CompassDial(
                              // The dial turns with the phone: north sits
                              // where north is, the Kaaba where the Qibla is.
                              north: -(trueHeading ?? 0),
                              qibla: bearing,
                              aligned: aligned,
                              colors: scheme,
                              cardinals: language == 'ar'
                                  ? const ['ش', 'ق', 'ج', 'غ']
                                  : const ['N', 'E', 'S', 'W'],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      stat(
                        l10n.qiblaAngle,
                        '${numbers.format(bearing.round() % 360)}°',
                        Icons.explore_outlined,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      stat(
                        l10n.qiblaDistanceLabel,
                        l10n.qiblaKilometres(
                          numbers.format(distanceToKaaba(point).round()),
                        ),
                        Icons.mosque_outlined,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      stat(
                        l10n.qiblaPhoneLabel,
                        trueHeading == null
                            ? '—'
                            : '${numbers.format(trueHeading.round() % 360)}°',
                        Icons.smartphone,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: Icon(
                        heading?.reliable == false
                            ? Icons.screen_rotation_alt
                            : turn == null
                            ? Icons.info_outline
                            : Icons.stay_current_portrait,
                        color: scheme.primary,
                      ),
                      title: Text(message),
                      subtitle: location.fromDevice
                          ? null
                          : Text(l10n.cityBearingApproximate),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A dial that turns with the phone. The fixed mark at the top is where the
/// phone points; the Kaaba on the ring is the Qibla.
class _CompassDial extends CustomPainter {
  const _CompassDial({
    required this.north,
    required this.qibla,
    required this.aligned,
    required this.colors,
    required this.cardinals,
  });

  final double north;
  final double qibla;
  final bool aligned;
  final ColorScheme colors;
  final List<String> cardinals;

  Offset _at(Offset center, double degrees, double distance) {
    final radians = (degrees + north) * math.pi / 180;
    return center + Offset(math.sin(radians), -math.cos(radians)) * distance;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 14;
    final accent = aligned ? BrandColors.goldBright : colors.primary;
    final paint = Paint()..color = colors.surfaceContainerLow;
    canvas.drawCircle(center, radius, paint);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = aligned ? 6 : 3
      ..color = accent;
    canvas.drawCircle(center, radius, paint);

    for (var degrees = 0; degrees < 360; degrees += 5) {
      final major = degrees % 30 == 0;
      paint
        ..strokeWidth = major ? 2 : 1
        ..color = major ? colors.onSurfaceVariant : colors.outlineVariant;
      canvas.drawLine(
        _at(center, degrees.toDouble(), radius * (major ? .84 : .89)),
        _at(center, degrees.toDouble(), radius * .95),
        paint,
      );
    }
    for (final (index, label) in cardinals.indexed) {
      final text = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: index == 0 ? colors.error : colors.onSurface,
            fontSize: radius * .12,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(
        canvas,
        _at(center, index * 90.0, radius * .7) -
            Offset(text.width / 2, text.height / 2),
      );
      text.dispose();
    }

    // The line from the centre to the Kaaba.
    final kaaba = _at(center, qibla, radius * .78);
    paint
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.6);
    canvas.drawLine(center, kaaba, paint);
    canvas.drawCircle(center, 6, Paint()..color = accent);
    _paintKaaba(canvas, kaaba, radius * .14);

    // Where the phone points: a fixed mark above the dial.
    final top = Path()
      ..moveTo(center.dx, center.dy - radius - 12)
      ..lineTo(center.dx - 9, center.dy - radius + 4)
      ..lineTo(center.dx + 9, center.dy - radius + 4)
      ..close();
    canvas.drawPath(top, Paint()..color = accent);
  }

  void _paintKaaba(Canvas canvas, Offset center, double radius) {
    final paint = Paint()..color = colors.surface;
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(
      center,
      radius,
      paint
        ..color = aligned ? BrandColors.goldBright : colors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..scale(radius / 12);
    final front = Path()
      ..moveTo(-7, -5)
      ..lineTo(3, -5)
      ..lineTo(3, 7)
      ..lineTo(-7, 7)
      ..close();
    final side = Path()
      ..moveTo(3, -5)
      ..lineTo(7, -8)
      ..lineTo(7, 4)
      ..lineTo(3, 7)
      ..close();
    paint.style = PaintingStyle.fill;
    canvas.drawPath(
      Path()
        ..moveTo(-7, -5)
        ..lineTo(-3, -8)
        ..lineTo(7, -8)
        ..lineTo(3, -5)
        ..close(),
      paint..color = const Color(0xFF4B4035),
    );
    canvas.drawPath(side, paint..color = const Color(0xFF3A3430));
    canvas.drawPath(front, paint..color = const Color(0xFF211E1B));
    canvas.drawPath(
      Path()
        ..moveTo(-7, -2)
        ..lineTo(3, -2)
        ..lineTo(7, -5)
        ..lineTo(7, -3)
        ..lineTo(3, 0)
        ..lineTo(-7, 0)
        ..close(),
      paint..color = const Color(0xFFE1BD70),
    );
    canvas.drawRect(const Rect.fromLTWH(-2, 2, 2, 4), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CompassDial old) =>
      old.north != north ||
      old.qibla != qibla ||
      old.aligned != aligned ||
      old.colors != colors;
}
