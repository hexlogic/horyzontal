import 'dart:math' as math;

import 'angle.dart';

/// Direct and inverse problems on the plane of rectangular coordinates
/// (ПГЗ / ОГЗ на площині): [x] northing, [y] easting, angles are grid
/// bearings (дирекційні кути) in degrees clockwise from grid north.
class PlanePoint {
  const PlanePoint(this.x, this.y);
  final double x, y;
}

/// Point at [distance] metres along grid bearing [bearing] from [from].
PlanePoint planeDirect(PlanePoint from, double distance, double bearing) {
  final a = bearing * math.pi / 180;
  return PlanePoint(from.x + distance * math.cos(a), from.y + distance * math.sin(a));
}

class PlaneInverse {
  const PlaneInverse(this.distance, this.bearing);
  final double distance;

  /// Grid bearing from the first point to the second, [0, 360).
  final double bearing;

  /// Grid bearing back from the second point, [0, 360).
  double get backBearing => normalizeDegrees(bearing + 180);
}

PlaneInverse planeInverse(PlanePoint a, PlanePoint b) {
  final dx = b.x - a.x, dy = b.y - a.y;
  final d = math.sqrt(dx * dx + dy * dy);
  final bearing = d == 0 ? 0.0 : normalizeDegrees(math.atan2(dy, dx) * 180 / math.pi);
  return PlaneInverse(d, bearing);
}
