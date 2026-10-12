import 'dart:math' as math;

/// Reference ellipsoid given by semi-major axis and flattening.
class Ellipsoid {
  const Ellipsoid(this.name, this.a, this.f);

  final String name;

  /// Semi-major axis, metres.
  final double a;

  /// Flattening.
  final double f;

  static const wgs84 = Ellipsoid('WGS 84', 6378137.0, 1 / 298.257223563);
  static const grs80 = Ellipsoid('GRS 1980', 6378137.0, 1 / 298.257222101);
  static const krassowsky = Ellipsoid('Krassowsky 1940', 6378245.0, 1 / 298.3);

  /// Semi-minor axis.
  double get b => a * (1 - f);

  /// First eccentricity squared.
  double get e2 => f * (2 - f);

  /// First eccentricity.
  double get e => math.sqrt(e2);

  /// Third flattening.
  double get n => f / (2 - f);
}
