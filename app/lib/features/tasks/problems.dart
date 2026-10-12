import 'package:horyzontal_geo/horyzontal_geo.dart';

import '../../core/widgets/point_input.dart';

enum ProblemMethod { plane, ellipsoid }

/// Grid and zone a plane problem is solved in: the grid the first point was
/// typed in, else the default system's grid, else СК-42.
class PlaneFrame {
  const PlaneFrame(this.system, this.zone);
  final CoordinateSystem system;
  final int zone;

  GaussKruger get grid => system.grid!;

  factory PlaneFrame.forPoint(PointValue p, CoordinateSystem defaultSystem) {
    if (p.system.isGrid && p.zone != null) return PlaneFrame(p.system, p.zone!);
    final s = defaultSystem.isGrid ? defaultSystem : CoordinateSystem.sk42Gk;
    return PlaneFrame(s, s.grid!.zoneFor(s.datum.fromWgs84Geodetic(p.wgs).lon));
  }

  PlanePoint project(Geodetic wgs) {
    final p = grid.fromWgs84(wgs, zone: zone);
    return PlanePoint(p.x, p.y);
  }

  Geodetic unproject(PlanePoint p) => grid.toWgs84(GkPoint(zone, p.x, p.y));
}

class DirectSolution {
  const DirectSolution(this.end, this.backAngle);
  final Geodetic end;

  /// Grid bearing (plane) or azimuth (ellipsoid) from the end point back.
  final double backAngle;
}

/// [angle] is a grid bearing on the plane and a true azimuth on the
/// ellipsoid, degrees; [distance] in metres.
DirectSolution solveDirect(
  Geodetic start,
  double distance,
  double angle,
  ProblemMethod method,
  PlaneFrame frame,
) {
  switch (method) {
    case ProblemMethod.plane:
      final end = planeDirect(frame.project(start), distance, angle);
      return DirectSolution(frame.unproject(end), normalizeDegrees(angle + 180));
    case ProblemMethod.ellipsoid:
      final r = Geodesic.wgs84.direct(start.lat, start.lon, angle, distance);
      return DirectSolution(Geodetic(r.lat2, r.lon2), normalizeDegrees(r.azi2 + 180));
  }
}

class InverseSolution {
  const InverseSolution(this.distance, this.angle, this.backAngle);
  final double distance, angle, backAngle;
}

InverseSolution solveInverse(Geodetic a, Geodetic b, ProblemMethod method, PlaneFrame frame) {
  switch (method) {
    case ProblemMethod.plane:
      final r = planeInverse(frame.project(a), frame.project(b));
      return InverseSolution(r.distance, r.bearing, r.backBearing);
    case ProblemMethod.ellipsoid:
      final r = Geodesic.wgs84.inverse(a.lat, a.lon, b.lat, b.lon);
      return InverseSolution(r.s12, normalizeDegrees(r.azi1), normalizeDegrees(r.azi2 + 180));
  }
}

/// Magnetic declination now at [p], degrees east.
double declinationAt(Geodetic p, [DateTime? at]) =>
    Wmm.wmm2025.at(p.lat, p.lon, p.h, decimalYear(at ?? DateTime.now())).declination;
