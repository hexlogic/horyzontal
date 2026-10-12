import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal/core/widgets/point_input.dart';
import 'package:horyzontal/features/tasks/problems.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

void main() {
  const kyiv = Geodetic(50.4501, 30.5234);
  final at = DateTime.utc(2026, 10, 12);
  const sk42zone6 = PlaneFrame(CoordinateSystem.sk42Gk, 6);

  test('plane frame: typed grid wins, else default grid, else СК-42', () {
    final typed = PointValue(kyiv, CoordinateSystem.usk2000Gk, zone: 5);
    expect(planeFrameFor(typed, CoordinateSystem.wgs84), const PlaneFrame(CoordinateSystem.usk2000Gk, 5));
    const wgs = PointValue(kyiv, CoordinateSystem.wgs84);
    expect(planeFrameFor(wgs, CoordinateSystem.usk2000Tm3).system, CoordinateSystem.usk2000Tm3);
    expect(planeFrameFor(wgs, CoordinateSystem.mgrs), const PlaneFrame(CoordinateSystem.utm, 36));
    expect(planeFrameFor(wgs, CoordinateSystem.sk42), sk42zone6);
    const mgrs = PointValue(kyiv, CoordinateSystem.mgrs);
    expect(planeFrameFor(mgrs, CoordinateSystem.sk42Gk).system, CoordinateSystem.utm);
  });

  test('angle context: the three norths', () {
    const c = AngleContext(-1.5, 7.0); // west of the central meridian
    expect(c.directionCorrection, 8.5);
    final s = c.fromTrue(100);
    expect(s.grid, closeTo(101.5, 1e-12));
    expect(s.magnetic, closeTo(93, 1e-12));
    for (final k in AngleKind.values) {
      expect(c.toTrue(s.of(k), k), closeTo(100, 1e-12));
    }
    // Grid bearing = magnetic azimuth + ПН.
    expect(s.magnetic + c.directionCorrection, closeTo(s.grid, 1e-12));
  });

  test('convergence sign east and west of the central meridian', () {
    expect(angleContextAt(const Geodetic(50, 34), sk42zone6, at: at).convergence, greaterThan(0));
    expect(angleContextAt(const Geodetic(50, 31), sk42zone6, at: at).convergence, lessThan(0));
  });

  for (final method in ProblemMethod.values) {
    for (final kind in AngleKind.values) {
      test('$method, $kind: direct then inverse gives the input back', () {
        final d = solveDirect(kyiv, 12345.6, 123.45, kind, method, sk42zone6, at: at);
        final i = solveInverse(kyiv, d.end, method, sk42zone6, at: at);
        final dist = method == ProblemMethod.plane ? i.gridDistance : i.ellipsoidDistance;
        expect(dist, closeTo(12345.6, 1e-3));
        expect(i.forward.of(kind), closeTo(123.45, 1e-6));
        expect(i.back.of(kind), closeTo(d.back.of(kind), 1e-6));
      });
    }
  }

  test('plane and ellipsoid agree up to convergence and scale', () {
    const lviv = Geodetic(49.8397, 24.0297);
    final e = solveInverse(kyiv, lviv, ProblemMethod.ellipsoid, sk42zone6, at: at);
    expect(e.ellipsoidDistance, closeTo(468952.868, 1e-3)); // GeographicLib
    // Lviv is 9° west of the zone 6 meridian: grid distance is stretched.
    expect(e.scale, inInclusiveRange(1.002, 1.01));
    final p = solveInverse(kyiv, lviv, ProblemMethod.plane, sk42zone6, at: at);
    expect(p.gridDistance, e.gridDistance);
    // True azimuths agree up to the arc-to-chord correction of a 470 km line.
    expect(p.forward.trueAzimuth, closeTo(e.forward.trueAzimuth, 0.3));
  });

  test('ground distance near a zone edge', () {
    const start = Geodetic(49.9, 35.6); // 2.6° east of the zone 6 meridian
    for (final az in [10.0, 80.0, 200.0]) {
      final d = solveDirect(start, 30000, az, AngleKind.grid, ProblemMethod.plane, sk42zone6, groundDistance: true, at: at);
      final i = solveInverse(start, d.end, ProblemMethod.ellipsoid, sk42zone6, at: at);
      expect(i.ellipsoidDistance, closeTo(30000, 0.05));
      final grid = solveDirect(start, 30000, az, AngleKind.grid, ProblemMethod.plane, sk42zone6, at: at);
      final j = solveInverse(start, grid.end, ProblemMethod.ellipsoid, sk42zone6, at: at);
      expect(j.ellipsoidDistance, lessThan(29990)); // grid metres are longer here
    }
  });

  test('magnetic azimuth on the ellipsoid uses the declination at the start', () {
    final d = solveDirect(kyiv, 5000, 45, AngleKind.magnetic, ProblemMethod.ellipsoid, sk42zone6, at: at);
    final i = solveInverse(kyiv, d.end, ProblemMethod.ellipsoid, sk42zone6, at: at);
    expect(i.forward.trueAzimuth, closeTo(45 + declinationAt(kyiv, at), 1e-6));
    expect(i.forward.magnetic, closeTo(45, 1e-6));
  });
}
