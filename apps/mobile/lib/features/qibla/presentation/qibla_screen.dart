import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/content/feature_preview.dart';
import '../../../core/localization/l10n_extension.dart';
import '../../../core/routing/app_sections.dart';
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
    .family<double?, GeoCoordinate>(
      (_, point) => const MethodChannel('madar/geomagnetic')
          .invokeMethod<double>('declination', {
            'latitude': point.latitude,
            'longitude': point.longitude,
          }),
    );

class QiblaScreen extends StatelessWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (AppSection.qibla.status.isGated && !featurePreviewEnabled) {
      return const SectionDetailScaffold(section: AppSection.qibla);
    }
    return const _QiblaCompass();
  }
}

class _QiblaCompass extends ConsumerWidget {
  const _QiblaCompass();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(worshipLocationProvider);
    final point = location.point;
    final bearing = point == null ? null : QiblaBearing.calculate(point);
    final active =
        TickerMode.valuesOf(context).enabled &&
        ModalRoute.isCurrentOf(context) == true;
    final sensor = active && point != null
        ? ref.watch(magneticHeadingProvider)
        : null;
    final declination = point == null
        ? null
        : ref.watch(_declinationProvider(point));
    final heading = sensor?.asData?.value;
    final correction = declination?.asData?.value;
    final live = heading != null && heading.reliable && correction != null;
    final l10n = context.l10n;
    final decimal = NumberFormat.decimalPatternDigits(
      locale: Localizations.localeOf(context).toLanguageTag(),
      decimalDigits: 1,
    );
    final direction = bearing == null
        ? null
        : l10n.trueBearing(decimal.format(bearing));
    final message = switch ((heading, live)) {
      (_, true) => l10n.compassHoldFlat,
      ((reliable: false, degrees: _), _) => l10n.compassCalibrate,
      _ when sensor?.isLoading == true => l10n.compassWaiting,
      _ => l10n.compassUnavailable,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sectionQiblaTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const WorshipLocationPicker(),
            if (point != null && bearing != null && direction != null) ...[
              const SizedBox(height: 24),
              if (live)
                Center(
                  child: Semantics(
                    label: direction,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: SizedBox.square(
                        dimension: 144,
                        child: Transform.rotate(
                          angle:
                              (bearing - heading.degrees - correction) *
                              math.pi /
                              180,
                          child: const Icon(Icons.navigation, size: 64),
                        ),
                      ),
                    ),
                  ),
                ),
              ListTile(
                title: Text(direction),
                subtitle: Text(
                  location.devicePoint == null
                      ? l10n.cityBearingApproximate
                      : l10n.deviceLocation,
                ),
              ),
              Text(message),
            ],
          ],
        ),
      ),
    );
  }
}
