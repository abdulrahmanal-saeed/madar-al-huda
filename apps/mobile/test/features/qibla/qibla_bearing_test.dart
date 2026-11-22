import 'package:flutter_test/flutter_test.dart';
import 'package:madar_al_huda/features/qibla/domain/qibla_bearing.dart';

void main() {
  group('QiblaBearing', () {
    test('matches independent reference bearings in different hemispheres', () {
      // Public independent references: London ~119 degrees; New York
      // ~58.5 degrees clockwise from true north (docs/qibla/README.md).
      expect(
        QiblaBearing.calculate(const GeoCoordinate(51.5074, -0.1278)),
        closeTo(119.0, 0.3),
      );
      expect(
        QiblaBearing.calculate(const GeoCoordinate(40.7128, -74.0060)),
        closeTo(58.5, 0.3),
      );
    });

    test('four manual city-centre bearings are finite and plausible', () {
      final expected = <ManualCity, double>{
        ManualCity.dubai: 258.2,
        ManualCity.abuDhabi: 260.2,
        ManualCity.cairo: 136.1,
        ManualCity.alexandria: 135.4,
      };

      for (final entry in expected.entries) {
        final bearing = entry.key.approximateQiblaBearing;
        expect(bearing, inInclusiveRange(0.0, 359.999999));
        expect(bearing, closeTo(entry.value, 0.3), reason: entry.key.id);
      }
    });

    test('coordinates on either side of the date line are equivalent', () {
      final west = QiblaBearing.calculate(const GeoCoordinate(0, -180));
      final east = QiblaBearing.calculate(const GeoCoordinate(0, 180));
      expect(west, closeTo(east, 1e-9));
    });

    test('rejects invalid, infinite and nonnumeric coordinates', () {
      for (final point in <GeoCoordinate>[
        const GeoCoordinate(91, 0),
        const GeoCoordinate(-91, 0),
        const GeoCoordinate(0, 181),
        const GeoCoordinate(0, -181),
        GeoCoordinate(double.nan, 0),
        GeoCoordinate(0, double.infinity),
        GeoCoordinate(double.negativeInfinity, 0),
      ]) {
        expect(() => QiblaBearing.calculate(point), throwsArgumentError);
      }
    });

    test('rejects undefined origin at Kaaba, antipode and poles', () {
      expect(
        () => QiblaBearing.calculate(QiblaBearing.kaaba),
        throwsStateError,
      );
      expect(
        () => QiblaBearing.calculate(const GeoCoordinate(-21.4225, -140.1738)),
        throwsStateError,
      );
      expect(
        () => QiblaBearing.calculate(const GeoCoordinate(90, 0)),
        throwsStateError,
      );
      expect(
        () => QiblaBearing.calculate(const GeoCoordinate(-90, 40)),
        throwsStateError,
      );
    });

    test('manual presets use the official P00-10 city identities and IANA zones', () {
      expect(
        ManualCity.values.map((city) => city.id).toSet(),
        {'dubai-ae', 'abu-dhabi-ae', 'cairo-eg', 'alexandria-eg'},
      );
      expect(ManualCity.dubai.timeZone, 'Asia/Dubai');
      expect(ManualCity.abuDhabi.timeZone, 'Asia/Dubai');
      expect(ManualCity.cairo.timeZone, 'Africa/Cairo');
      expect(ManualCity.alexandria.timeZone, 'Africa/Cairo');
    });
  });
}
