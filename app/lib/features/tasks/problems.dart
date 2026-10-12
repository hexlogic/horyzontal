import 'package:horyzontal_geo/horyzontal_geo.dart';

import '../../core/widgets/point_input.dart';

enum ProblemMethod { plane, ellipsoid }

/// What a direction is measured from: grid north (дирекційний кут), true
/// north (істинний азимут) or magnetic north.
enum AngleKind { grid, trueAzimuth, magnetic }

/// Grid and zone a plane problem is solved in: the grid the first point was
/// typed in (MGRS counts as UTM), else the default system's grid, else СК-42.
PlaneFrame planeFrameFor(PointValue p, CoordinateSystem defaultSystem) {
  final typed = p.system.canBePlane || p.system == CoordinateSystem.mgrs;
  return PlaneFrame.auto(p.wgs, typed ? p.system : defaultSystem, zone: typed ? p.zone : null);
}

/// Corrections between the three norths at one point, degrees east.
class AngleContext {
  const AngleContext(this.convergence, this.declination);

  /// Meridian convergence γ: grid north from true north.
  final double convergence;

  /// Magnetic declination δ: magnetic north from true north.
  final double declination;

  /// Поправка напрямку: grid bearing = magnetic azimuth + this.
  double get directionCorrection => declination - convergence;

  double toTrue(double angle, AngleKind kind) => normalizeDegrees(switch (kind) {
    AngleKind.grid => angle + convergence,
    AngleKind.trueAzimuth => angle,
    AngleKind.magnetic => angle + declination,
  });

  AngleSet fromTrue(double azimuth) => AngleSet(
    normalizeDegrees(azimuth - convergence),
    normalizeDegrees(azimuth),
    normalizeDegrees(azimuth - declination),
  );
}

AngleContext angleContextAt(Geodetic wgs, PlaneFrame frame, {DateTime? at}) =>
    AngleContext(frame.convergence(wgs), declinationAt(wgs, at));

/// One direction in all three kinds, degrees [0, 360).
class AngleSet {
  const AngleSet(this.grid, this.trueAzimuth, this.magnetic);
  final double grid, trueAzimuth, magnetic;

  double of(AngleKind k) => switch (k) {
    AngleKind.grid => grid,
    AngleKind.trueAzimuth => trueAzimuth,
    AngleKind.magnetic => magnetic,
  };
}

class DirectSolution {
  const DirectSolution(this.end, this.back, this.atStart, this.atEnd);
  final Geodetic end;

  /// Direction from the end point back to the start.
  final AngleSet back;
  final AngleContext atStart, atEnd;
}

/// [angle] of [kind] in degrees, [distance] in metres. On the plane the
/// distance is a grid distance unless [groundDistance], when it is reduced
/// to the grid with the mean scale factor of the line. On the ellipsoid it is
/// always the geodesic length.
DirectSolution solveDirect(
  Geodetic start,
  double distance,
  double angle,
  AngleKind kind,
  ProblemMethod method,
  PlaneFrame frame, {
  bool groundDistance = false,
  DateTime? at,
}) {
  final atStart = angleContextAt(start, frame, at: at);
  final azimuth = atStart.toTrue(angle, kind);
  switch (method) {
    case ProblemMethod.plane:
      final bearing = atStart.fromTrue(azimuth).grid;
      final from = frame.project(start);
      var d = distance;
      if (groundDistance) {
        final rough = frame.unproject(planeDirect(from, distance, bearing));
        d = distance * frame.meanScale(start, rough);
      }
      final end = frame.unproject(planeDirect(from, d, bearing));
      final atEnd = angleContextAt(end, frame, at: at);
      final back = atEnd.toTrue(bearing + 180, AngleKind.grid);
      return DirectSolution(end, atEnd.fromTrue(back), atStart, atEnd);
    case ProblemMethod.ellipsoid:
      final r = Geodesic.wgs84.direct(start.lat, start.lon, azimuth, distance);
      final end = Geodetic(r.lat2, r.lon2);
      final atEnd = angleContextAt(end, frame, at: at);
      return DirectSolution(end, atEnd.fromTrue(r.azi2 + 180), atStart, atEnd);
  }
}

class InverseSolution {
  const InverseSolution({
    required this.gridDistance,
    required this.ellipsoidDistance,
    required this.forward,
    required this.back,
    required this.atA,
    required this.atB,
  });

  final double gridDistance, ellipsoidDistance;
  final AngleSet forward, back;
  final AngleContext atA, atB;

  /// Grid distance divided by the geodesic length.
  double get scale => gridDistance / ellipsoidDistance;
}

/// On the plane the grid bearing is exact and the others follow from the
/// convergence at each end; on the ellipsoid the geodesic azimuths are.
InverseSolution solveInverse(
  Geodetic a,
  Geodetic b,
  ProblemMethod method,
  PlaneFrame frame, {
  DateTime? at,
}) {
  final atA = angleContextAt(a, frame, at: at), atB = angleContextAt(b, frame, at: at);
  final grid = planeInverse(frame.project(a), frame.project(b));
  final geo = Geodesic.wgs84.inverse(a.lat, a.lon, b.lat, b.lon);
  final (double fwd, double back) = switch (method) {
    ProblemMethod.plane => (grid.bearing + atA.convergence, grid.backBearing + atB.convergence),
    ProblemMethod.ellipsoid => (geo.azi1, geo.azi2 + 180),
  };
  return InverseSolution(
    gridDistance: grid.distance,
    ellipsoidDistance: geo.s12,
    forward: atA.fromTrue(fwd),
    back: atB.fromTrue(back),
    atA: atA,
    atB: atB,
  );
}

/// Magnetic declination at [p], degrees east, now or [at].
double declinationAt(Geodetic p, [DateTime? at]) =>
    Wmm.wmm2025.at(p.lat, p.lon, p.h, decimalYear(at ?? DateTime.now())).declination;
