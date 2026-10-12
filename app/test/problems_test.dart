import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal/core/widgets/point_input.dart';
import 'package:horyzontal/features/tasks/problems.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

void main() {
  const kyiv = Geodetic(50.4501, 30.5234);

  test('plane frame: typed grid wins, else default grid, else СК-42', () {
    final typed = PointValue(kyiv, CoordinateSystem.usk2000Gk, zone: 5);
    expect(planeFrameFor(typed, CoordinateSystem.wgs84).system, CoordinateSystem.usk2000Gk);
    expect(planeFrameFor(typed, CoordinateSystem.wgs84).zone, 5);
    const wgs = PointValue(kyiv, CoordinateSystem.wgs84);
    expect(
      planeFrameFor(wgs, CoordinateSystem.usk2000Tm3).system,
      CoordinateSystem.usk2000Tm3,
    );
    final f = planeFrameFor(wgs, CoordinateSystem.mgrs);
    expect((f.system, f.zone), (CoordinateSystem.utm, 36));
    final g = planeFrameFor(wgs, CoordinateSystem.sk42);
    expect((g.system, g.zone), (CoordinateSystem.sk42Gk, 6));
  });

  for (final method in ProblemMethod.values) {
    test('$method: direct then inverse gives the input back', () {
      final frame = planeFrameFor(
        const PointValue(kyiv, CoordinateSystem.wgs84),
        CoordinateSystem.sk42Gk,
      );
      final d = solveDirect(kyiv, 12345.6, 123.45, method, frame);
      final i = solveInverse(kyiv, d.end, method, frame);
      expect(i.distance, closeTo(12345.6, 1e-3));
      expect(i.angle, closeTo(123.45, 1e-6));
      expect(i.backAngle, closeTo(d.backAngle, 1e-6));
    });
  }

  test('plane and ellipsoid agree up to convergence and scale', () {
    final frame = planeFrameFor(
      const PointValue(kyiv, CoordinateSystem.wgs84),
      CoordinateSystem.sk42Gk,
    );
    const lviv = Geodetic(49.8397, 24.0297);
    final e = solveInverse(kyiv, lviv, ProblemMethod.ellipsoid, frame);
    expect(e.distance, closeTo(468952.868, 1e-3)); // GeographicLib
    final p = solveInverse(kyiv, lviv, ProblemMethod.plane, frame);
    // Lviv is 9° west of the zone 6 meridian: grid distance is stretched.
    expect(p.distance / e.distance, inInclusiveRange(1.002, 1.01));
  });
}
