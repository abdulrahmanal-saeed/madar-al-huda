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
import '../../../core/widgets/madar_panel.dart';
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

    Widget stat(String label, String value, {Color? accent}) => Expanded(
      child: MadarPanel(
        radius: BorderRadius.circular(18),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        child: Column(
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: accent ?? scheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sectionQiblaTitle)),
      body: MadarBackdrop(
        child: CustomScrollView(
          slivers: [
            SliverResponsiveContent(
              sliver: SliverList.list(
                children: [
                  const WorshipLocationPicker(compact: true),
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
                              color: aligned
                                  ? scheme.onPrimary
                                  : scheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                              child: Text(
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
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: ExcludeSemantics(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 282),
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
                                northLabel: language == 'ar' ? 'ش' : 'N',
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
                          accent: scheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        stat(
                          l10n.qiblaDistanceLabel,
                          l10n.qiblaKilometres(
                            numbers.format(distanceToKaaba(point).round()),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        stat(
                          l10n.qiblaPhoneLabel,
                          trueHeading == null
                              ? '—'
                              : '${numbers.format(trueHeading.round() % 360)}°',
                          accent: scheme.secondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    MadarPanel(
                      color: scheme.surfaceContainerHighest,
                      padding: EdgeInsets.zero,
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
                    const SizedBox(height: AppSpacing.md),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A dial that turns with the phone and points to the Kaaba.
class _CompassDial extends CustomPainter {
  const _CompassDial({
    required this.north,
    required this.qibla,
    required this.aligned,
    required this.colors,
    required this.northLabel,
  });

  final double north;
  final double qibla;
  final bool aligned;
  final ColorScheme colors;
  final String northLabel;

  Offset _at(Offset center, double degrees, double distance) {
    final radians = (degrees + north) * math.pi / 180;
    return center + Offset(math.sin(radians), -math.cos(radians)) * distance;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 6;
    final dark = colors.brightness == Brightness.dark;
    final accent = aligned ? colors.secondary : colors.primary;
    final bounds = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.34, -.36),
        radius: .85,
        colors: [
          if (dark)
            Color.alphaBlend(
              colors.onSurface.withValues(alpha: .3),
              colors.surfaceContainerLow,
            )
          else
            colors.surfaceBright,
          colors.surfaceContainerLow,
          colors.surfaceContainer,
        ],
        stops: dark ? const [0, .66, 1] : const [0, .42, 1],
      ).createShader(bounds);
    canvas.drawShadow(
      Path()..addOval(bounds),
      dark ? colors.shadow : colors.secondary.withValues(alpha: .32),
      12,
      false,
    );
    canvas.drawCircle(center, radius, paint);
    paint
      ..shader = null
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = colors.surfaceContainerHigh;
    canvas.drawCircle(center, radius, paint);
    paint.strokeWidth = 1.5;
    canvas.drawCircle(center, radius * .8, paint);

    for (var degrees = 0; degrees < 360; degrees += 10) {
      final major = degrees % 30 == 0;
      paint
        ..strokeWidth = major ? 2.2 : 1.1
        ..color = colors.onSurfaceVariant;
      canvas.drawLine(
        _at(center, degrees.toDouble(), radius * (major ? .88 : .93)),
        _at(center, degrees.toDouble(), radius * .97),
        paint,
      );
    }
    final northText = TextPainter(
      text: TextSpan(
        text: northLabel,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: colors.onSurfaceVariant,
          fontSize: radius * .1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    northText.paint(
      canvas,
      _at(center, 0, radius * .69) -
          Offset(northText.width / 2, northText.height / 2),
    );
    northText.dispose();

    final kaaba = _at(center, qibla, radius * .78);
    paint
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = accent;
    canvas.drawLine(center, kaaba, paint);
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * .062, paint..color = colors.onSurface);
    canvas.drawCircle(kaaba, radius * .12, paint..color = accent);
    canvas
      ..save()
      ..translate(kaaba.dx, kaaba.dy)
      ..rotate(-.2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: radius * .1,
          height: radius * .1,
        ),
        const Radius.circular(1.5),
      ),
      paint..color = colors.onPrimary,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CompassDial old) =>
      old.north != north ||
      old.qibla != qibla ||
      old.aligned != aligned ||
      old.northLabel != northLabel ||
      old.colors != colors;
}
