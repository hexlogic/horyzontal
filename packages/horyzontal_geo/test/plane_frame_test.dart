import 'package:horyzontal_geo/horyzontal_geo.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  test('СК-42 convergence and scale match PROJ', () {
    for (final r in readCsv('tm_factors.csv')) {
      final g = Geodetic(r.d('lat'), r.d('lon'));
      final zone = ((r.d('lon0') + 3) / 6).round();
      final f = GaussKruger.sk42.factors(g, zone: zone);
      expect(f.convergence, closeTo(r.d('convergence'), 1e-6));
      expect(f.scale, closeTo(r.d('scale'), 1e-8)); // PROJ prints 8 decimals
    }
  });

  test('frame choice', () {
    const kyiv = Geodetic(50.45, 30.52);
    expect(PlaneFrame.auto(kyiv, CoordinateSystem.wgs84), const PlaneFrame(CoordinateSystem.sk42Gk, 6));
    expect(PlaneFrame.auto(kyiv, CoordinateSystem.mgrs), const PlaneFrame(CoordinateSystem.utm, 36));
    expect(PlaneFrame.auto(kyiv, CoordinateSystem.usk2000Tm3), const PlaneFrame(CoordinateSystem.usk2000Tm3, 10));
    expect(PlaneFrame.auto(kyiv, CoordinateSystem.sk42Gk, zone: 5).zone, 5);
    expect(CoordinateSystem.utm.canBePlane, isTrue);
    expect(CoordinateSystem.mgrs.canBePlane, isFalse);
  });

  test('UTM frame round trip, convergence sign and scale', () {
    const f = PlaneFrame(CoordinateSystem.utm, 36);
    const p = Geodetic(48.9, 34.1); // east of the central meridian 33°E
    final xy = f.project(p);
    final back = f.unproject(xy);
    expect(groundError(back.lat, back.lon, p.lat, p.lon), lessThan(1e-6));
    expect(f.convergence(p), greaterThan(0));
    expect(f.convergence(const Geodetic(48.9, 31.5)), lessThan(0));
    expect(f.scale(const Geodetic(48.9, 33)), closeTo(0.9996, 1e-6));
  });

  test('mean scale relates grid and ellipsoid distances', () {
    for (final f in [
      const PlaneFrame(CoordinateSystem.sk42Gk, 6),
      const PlaneFrame(CoordinateSystem.utm, 36),
    ]) {
      const a = Geodetic(49.8, 35.2), b = Geodetic(50.1, 35.6); // near the GK zone edge
      final grid = planeInverse(f.project(a), f.project(b)).distance;
      // Gauss-Krüger lives on the datum's own ellipsoid.
      final da = f.system.datum.fromWgs84Geodetic(a), db = f.system.datum.fromWgs84Geodetic(b);
      final ell = Geodesic(f.system.datum.ellipsoid).inverse(da.lat, da.lon, db.lat, db.lon).s12;
      expect(grid, closeTo(ell * f.meanScale(a, b), 0.01));
    }
  });

  test('grid bearing plus convergence is the true azimuth', () {
    const f = PlaneFrame(CoordinateSystem.sk42Gk, 6);
    const a = Geodetic(50.0, 35.5), b = Geodetic(50.02, 35.53);
    final grid = planeInverse(f.project(a), f.project(b)).bearing;
    final az = Geodesic.wgs84.inverse(a.lat, a.lon, b.lat, b.lon).azi1;
    // The grid line and the geodesic differ by the arc-to-chord correction,
    // seconds of arc at this length.
    expect(grid + f.convergence(a), closeTo(az, 0.002));
  });
}
