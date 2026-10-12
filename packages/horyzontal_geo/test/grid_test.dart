import 'package:horyzontal_geo/horyzontal_geo.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  void checkGrid(String fixture, GaussKruger grid) {
    final fwd = MaxError('$fixture forward', 'm');
    final inv = MaxError('$fixture inverse', 'm');
    for (final r in readCsv(fixture)) {
      final g = Geodetic(r.d('lat'), r.d('lon'));
      final zone = r.i('zone');
      final p = grid.fromGeodetic(g, zone: zone);
      expect(p.zone, zone);
      final dx = p.x - r.d('x'), dy = p.y - r.d('y');
      expect(fwd.add((dx * dx + dy * dy)), lessThan(1e-6)); // squared, 1 mm
      final back = grid.toGeodetic(GkPoint(zone, r.d('x'), r.d('y')));
      expect(inv.add(groundError(back.lat, back.lon, g.lat, g.lon)), lessThan(1e-3));
    }
    fwd.report();
    inv.report();
  }

  test('СК-42 6° Gauss-Krüger matches PROJ tmerc', () {
    checkGrid('gk_sk42.csv', GaussKruger.sk42);
  });

  test('УСК-2000 6° Gauss-Krüger matches PROJ tmerc', () {
    checkGrid('gk_usk2000.csv', GaussKruger.usk2000);
  });

  test('УСК-2000 3° TM zones match PROJ tmerc', () {
    checkGrid('tm3_usk2000.csv', GaussKruger.usk2000Tm3);
  });

  test('zones', () {
    expect(GaussKruger.sk42.zoneFor(30.52), 6);
    expect(GaussKruger.sk42.zoneFor(23.99), 4);
    expect(GaussKruger.sk42.zoneFor(24.0), 5);
    expect(GaussKruger.usk2000Tm3.zoneFor(30.52), 10);
    expect(GaussKruger.usk2000Tm3.zoneFor(22.4), 7);
    expect(GaussKruger.usk2000Tm3.zoneFor(22.5), 8);
    expect(GaussKruger.sk42.zoneFromEasting(6324231), 6);
  });

  test('meridian convergence and scale match PROJ', () {
    final tm = TransverseMercator(Ellipsoid.krassowsky);
    final err = MaxError('convergence', 'deg');
    for (final r in readCsv('tm_factors.csv')) {
      final p = tm.forward(r.d('lat'), r.d('lon'), r.d('lon0'));
      expect(err.add((p.convergence - r.d('convergence')).abs()), lessThan(1e-7));
      expect(p.scale, closeTo(r.d('scale'), 1e-8));
    }
    err.report();
  });

  test('end to end: WGS 84 Kyiv to СК-42 grid', () {
    final p = GaussKruger.sk42.fromWgs84(const Geodetic(50.4501, 30.5234));
    expect(p.zone, 6);
    expect(p.x, closeTo(5593957.36, 0.01));
    expect(p.y, closeTo(6324233.36, 0.01));
    final back = GaussKruger.sk42.toWgs84(p);
    expect(groundError(back.lat, back.lon, 50.4501, 30.5234), lessThan(1e-3));
  });
}
