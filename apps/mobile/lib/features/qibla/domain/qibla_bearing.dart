import 'dart:math' as math;

/// Geographic coordinates in decimal degrees (WGS84-like latitude/longitude).
///
/// This type contains no GPS data source and does not request any permission.
/// [QiblaBearing.calculate] validates the coordinates before calculation.
final class GeoCoordinate {
  const GeoCoordinate(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

/// Initial great-circle bearing toward the Kaaba, clockwise from TRUE north.
///
/// This is geometry only. It is NOT a phone-heading/magnetometer bearing:
/// a future compass must handle calibration, magnetic declination, sensor
/// availability and accuracy before drawing a rotating heading indicator.
///
/// Great-circle Qibla is described by the Egyptian Survey Authority:
/// https://www.esa.gov.eg/qebla.aspx
abstract final class QiblaBearing {
  // Approximate position of the Kaaba; precision beyond that of the source
  // location is not claimed (see docs/qibla/README.md).
  static const GeoCoordinate kaaba = GeoCoordinate(21.4225, 39.8262);

  static double calculate(GeoCoordinate origin) {
    _validate(origin);
    _validate(kaaba);

    // A direction from exactly the Kaaba to itself is undefined; at the
    // antipode there are infinitely many shortest great-circle paths.
    const epsilon = 1e-12;
    if ((90 - origin.latitude.abs()) < epsilon) {
      throw StateError('True-north bearing is undefined at a geographic pole');
    }

    final latitude = _radians(origin.latitude);
    final longitude = _radians(origin.longitude);
    final targetLatitude = _radians(kaaba.latitude);
    final deltaLongitude = _radians(kaaba.longitude) - longitude;

    final halfLat = math.sin((targetLatitude - latitude) / 2);
    final halfLon = math.sin(deltaLongitude / 2);
    final haversine =
        halfLat * halfLat +
        math.cos(latitude) * math.cos(targetLatitude) * halfLon * halfLon;

    if (haversine < epsilon || 1 - haversine < epsilon) {
      throw StateError('No unique Qibla bearing for this coordinate');
    }

    final y = math.sin(deltaLongitude) * math.cos(targetLatitude);
    final x =
        math.cos(latitude) * math.sin(targetLatitude) -
        math.sin(latitude) *
            math.cos(targetLatitude) *
            math.cos(deltaLongitude);

    final degrees = math.atan2(y, x) * 180 / math.pi;
    return (degrees + 360) % 360;
  }

  static void _validate(GeoCoordinate point) {
    if (!point.latitude.isFinite ||
        point.latitude < -90 ||
        point.latitude > 90) {
      throw ArgumentError.value(
        point.latitude,
        'latitude',
        'Must be within -90 and 90',
      );
    }
    if (!point.longitude.isFinite ||
        point.longitude < -180 ||
        point.longitude > 180) {
      throw ArgumentError.value(
        point.longitude,
        'longitude',
        'Must be within -180 and 180',
      );
    }
  }

  static double _radians(double degrees) => degrees * math.pi / 180;
}

/// Approximate CITY-CENTRE presets for opt-in manual selection.
///
/// These are not a user's precise position and are never stored as location
/// history. Prayer calculation may later reuse the same city identities but
/// must independently verify the selected city's official prayer method.
enum ManualCity {
  dubai('dubai-ae', 25.2048, 55.2708, 'Asia/Dubai'),
  abuDhabi('abu-dhabi-ae', 24.4539, 54.3773, 'Asia/Dubai'),
  cairo('cairo-eg', 30.0444, 31.2357, 'Africa/Cairo'),
  alexandria('alexandria-eg', 31.2001, 29.9187, 'Africa/Cairo');

  const ManualCity(this.id, this.latitude, this.longitude, this.timeZone);

  final String id;
  final double latitude;
  final double longitude;
  final String timeZone;

  GeoCoordinate get center => GeoCoordinate(latitude, longitude);

  double get approximateQiblaBearing => QiblaBearing.calculate(center);
}
