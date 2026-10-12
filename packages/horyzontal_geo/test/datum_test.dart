import 'package:horyzontal_geo/horyzontal_geo.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  test('WGS 84 -> СК-42 and УСК-2000 match PROJ (EPSG:15865, EPSG:7817)', () {
    final sk = MaxError('WGS84->SK42', 'm'), us = MaxError('WGS84->USK2000', 'm');
    for (final r in readCsv('datum_ukraine.csv')) {
      final w = Geodetic(r.d('wgs_lat'), r.d('wgs_lon'));
      final s = Datum.sk42.fromWgs84Geodetic(w);
      final u = Datum.usk2000.fromWgs84Geodetic(w);
      expect(sk.add(groundError(s.lat, s.lon, r.d('sk42_lat'), r.d('sk42_lon'))), lessThan(1e-3));
      expect(us.add(groundError(u.lat, u.lon, r.d('usk_lat'), r.d('usk_lon'))), lessThan(1e-3));
    }
    sk.report();
    us.report();
  });

  test('СК-42 and УСК-2000 -> WGS 84 match PROJ', () {
    final err = MaxError('datum->WGS84', 'm');
    for (final r in readCsv('datum_inverse.csv')) {
      final g = Geodetic(r.d('lat'), r.d('lon'));
      final s = Datum.sk42.toWgs84Geodetic(g);
      final u = Datum.usk2000.toWgs84Geodetic(g);
      expect(
        err.add(groundError(s.lat, s.lon, r.d('sk42_wgs_lat'), r.d('sk42_wgs_lon'))),
        lessThan(1e-3),
      );
      expect(
        err.add(groundError(u.lat, u.lon, r.d('usk_wgs_lat'), r.d('usk_wgs_lon'))),
        lessThan(1e-3),
      );
    }
    err.report();
  });

  test('geodetic <-> ECEF round trip', () {
    for (final h in [-500.0, 0.0, 300.0, 9000.0]) {
      for (final lat in [-89.9, -45.0, 0.0, 12.3, 50.45, 89.99]) {
        final g = Geodetic(lat, 30.52, h);
        final back = ecefToGeodetic(Ellipsoid.krassowsky, geodeticToEcef(Ellipsoid.krassowsky, g));
        expect(back.lat, closeTo(lat, 1e-11));
        expect(back.lon, closeTo(30.52, 1e-11));
        expect(back.h, closeTo(h, 1e-6));
      }
    }
  });
}
