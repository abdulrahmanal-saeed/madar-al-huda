import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';

import '../../../core/content/feature_preview.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_sections.dart';
import '../../../core/theme/app_tokens.dart';
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

class QiblaScreen extends ConsumerWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final numbers = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final rotation = bearing != null && trueHeading != null
        ? (bearing - trueHeading + 540) % 360 - 180
        : null;
    final turn = heading?.reliable == true ? rotation : null;
    final message = switch (heading) {
      (reliable: false, degrees: _) => l10n.compassCalibrate,
      _ when turn != null => l10n.compassHoldFlat,
      _ when sensor?.isLoading == true || declination?.isLoading == true =>
        l10n.compassWaiting,
      _ => l10n.compassUnavailable,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sectionQiblaTitle)),
      body: CustomScrollView(
        slivers: [
          SliverResponsiveContent(
            sliver: SliverList.list(
              children: [
                const WorshipLocationPicker(),
                const SizedBox(height: AppSpacing.lg),
                if (bearing != null) ...[
                  if (turn != null)
                    Center(
                      child: Chip(
                        avatar: Icon(
                          turn.abs() < 3
                              ? Icons.check_circle_outline
                              : turn > 0
                              ? Icons.turn_right
                              : Icons.turn_left,
                        ),
                        label: Text(
                          turn.abs() < 3
                              ? l10n.compassAligned
                              : turn > 0
                              ? l10n.compassTurnRight(
                                  numbers.format(turn.round()),
                                )
                              : l10n.compassTurnLeft(
                                  numbers.format(turn.abs().round()),
                                ),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: ExcludeSemantics(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 280),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: CustomPaint(
                            painter: _CompassDial(
                              angle: rotation ?? bearing,
                              north: -(trueHeading ?? 0),
                              colors: theme.colorScheme,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Text(
                      '${numbers.format(bearing.round() % 360)}°',
                      style: theme.textTheme.displaySmall,
                    ),
                  ),
                  Text(
                    l10n.trueBearing(numbers.format(bearing.round() % 360)),
                    textAlign: TextAlign.center,
                  ),
                  if (trueHeading != null)
                    Text(
                      (heading?.reliable == true
                          ? l10n.compassPhoneHeading
                          : l10n.compassApproximateHeading)(
                        numbers.format(trueHeading.round() % 360),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  if (location.devicePoint == null)
                    Text(
                      l10n.cityBearingApproximate,
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: AppSpacing.md),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        turn == null ? Icons.info_outline : Icons.explore,
                      ),
                      title: Text(message),
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

/// The dial needle points to the Qibla. With no heading sample the dial
/// remains north-up and represents a geographic bearing.
class _CompassDial extends CustomPainter {
  const _CompassDial({
    required this.angle,
    required this.north,
    required this.colors,
  });

  final double angle;
  final double north;
  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 2;
    final paint = Paint()..color = colors.primaryContainer;
    canvas.drawCircle(center, radius, paint);
    paint
      ..color = colors.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius * .78, paint);
    for (var degrees = 0; degrees < 360; degrees += 10) {
      final radians = (degrees + north) * math.pi / 180;
      final vector = Offset(math.sin(radians), -math.cos(radians));
      paint.strokeWidth = degrees % 30 == 0 ? 2 : 1;
      canvas.drawLine(
        center + vector * (radius * (degrees % 30 == 0 ? .83 : .88)),
        center + vector * (radius * .94),
        paint,
      );
    }
    final northRadians = north * math.pi / 180;
    final label = TextPainter(
      text: TextSpan(
        text: 'N',
        style: TextStyle(color: colors.onPrimaryContainer),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(
      canvas,
      center +
          Offset(math.sin(northRadians), -math.cos(northRadians)) *
              radius *
              .74 -
          Offset(label.width / 2, label.height / 2),
    );
    label.dispose();
    final radians = angle * math.pi / 180;
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(radians);
    final needle = Path()
      ..moveTo(0, -radius * .62)
      ..lineTo(radius * .13, 0)
      ..lineTo(0, radius * .4)
      ..lineTo(-radius * .13, 0)
      ..close();
    paint
      ..style = PaintingStyle.fill
      ..color = colors.primary;
    canvas.drawPath(needle, paint);
    paint.color = colors.onPrimary;
    canvas.drawCircle(Offset.zero, radius * .05, paint);
    canvas.restore();

    final marker =
        center + Offset(math.sin(radians), -math.cos(radians)) * (radius * .54);
    _paintKaaba(canvas, marker, radius * .13);
  }

  void _paintKaaba(Canvas canvas, Offset center, double radius) {
    final paint = Paint()..color = colors.surface;
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(
      center,
      radius,
      paint
        ..color = colors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
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
      old.angle != angle || old.north != north || old.colors != colors;
}
