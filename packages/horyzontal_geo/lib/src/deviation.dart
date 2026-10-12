import 'dart:math' as math;

import 'angle.dart';
import 'datum.dart';
import 'geodesic.dart';

/// Position of point C relative to the line from A (observer, gun) to B
/// (target), as seen from A.
class TrackDeviation {
  const TrackDeviation(this.distance, this.angle, this.baseLength);

  /// A to C, metres.
  final double distance;

  /// Direction to C minus direction to B at A, degrees (-180, 180],
  /// positive to the right. The same for true, grid and magnetic angles.
  final double angle;

  /// A to B, metres.
  final double baseLength;

  /// Distance from A along the line A→B to the foot of C, metres.
  double get along => distance * math.cos(angle * math.pi / 180);

  /// Along-line distance beyond B: positive over (переліт), negative short
  /// (недоліт).
  double get range => along - baseLength;

  /// Offset from the line, metres: positive right, negative left.
  double get cross => distance * math.sin(angle * math.pi / 180);
}

/// Deviation of [c] from the line [a]→[b], decomposed in polar coordinates
/// at [a]. Within a few tens of kilometres this differs from the geodesic
/// cross-track distance by well under a metre.
TrackDeviation trackDeviation(Geodetic a, Geodetic b, Geodetic c, {Geodesic? geod}) {
  final g = geod ?? Geodesic.wgs84;
  final ab = g.inverse(a.lat, a.lon, b.lat, b.lon);
  final ac = g.inverse(a.lat, a.lon, c.lat, c.lon);
  final angle = ac.s12 == 0 ? 0.0 : normalizeSignedDegrees(ac.azi1 - ab.azi1);
  return TrackDeviation(ac.s12, angle, ab.s12);
}
