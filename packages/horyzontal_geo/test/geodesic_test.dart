import 'dart:io';
import 'dart:math' as math;

import 'package:horyzontal_geo/horyzontal_geo.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// Absolute difference of two angles in degrees, modulo 360.
double angleError(double a, double b) {
  var d = (a - b) % 360;
  if (d > 180) d -= 360;
  return d.abs();
}

/// Rows of Karney's GeodTest (WGS84): lat1 lon1 azi1 lat2 lon2 azi2 s12 a12
/// m12 S12.
List<List<double>> readGeodTest() => [
  for (final l in File('test/fixtures/geodtest_subset.dat').readAsLinesSync())
    if (l.trim().isNotEmpty) l.trim().split(RegExp(r'\s+')).map(double.parse).toList(),
];

void main() {
  final g = Geodesic.wgs84;
  final rows = readGeodTest();

  test('direct reproduces GeodTest', () {
    final pos = MaxError('direct position', 'm');
    final azi = MaxError('direct azi2 * cos(lat2)', 'deg');
    final arc = MaxError('direct a12', 'deg');
    final red = MaxError('direct m12', 'm');
    final area = MaxError('direct S12', 'm²');
    final areaPolar = MaxError('direct S12 (start near pole)', 'm²');
    for (final r in rows) {
      final d = g.direct(r[0], r[1], r[2], r[6]);
      expect(pos.add(groundError(d.lat2, d.lon2, r[3], r[4])), lessThan(1e-6), reason: '$r');
      // Azimuth is ill-defined at a pole; weight its error by the distance from it.
      final cosLat2 = math.cos(r[3] * math.pi / 180);
      expect(azi.add(angleError(d.azi2, r[5]) * cosLat2), lessThan(1e-9), reason: '$r');
      expect(arc.add((d.a12 - r[7]).abs()), lessThan(1e-12), reason: '$r');
      expect(red.add((d.m12 - r[8]).abs()), lessThan(1e-6), reason: '$r');
      // Starting within ~1 km of a pole the area is ill-conditioned in the
      // input azimuth (errors up to ~2e3 m², identical in Python GeographicLib).
      final nearPole = r[0].abs() >= 89.99;
      expect(
        (nearPole ? areaPolar : area).add((d.area - r[9]).abs()),
        lessThan(nearPole ? 2e3 : 2),
        reason: '$r',
      );
    }
    for (final e in [pos, azi, arc, red, area, areaPolar]) {
      e.report();
    }
  });

  test('inverse reproduces GeodTest', () {
    final dist = MaxError('inverse s12', 'm');
    final azi = MaxError('inverse azimuths (well-conditioned)', 'deg');
    final hit = MaxError('inverse re-run direct position (ill-conditioned)', 'm');
    var illConditioned = 0;
    for (final r in rows) {
      final v = g.inverse(r[0], r[1], r[3], r[4]);
      expect(dist.add((v.s12 - r[6]).abs()), lessThan(1e-6), reason: '$r');
      final e1 = angleError(v.azi1, r[2]), e2 = angleError(v.azi2, r[5]);
      if (math.max(e1, e2) < 1e-9) {
        azi.add(math.max(e1, e2));
        continue;
      }
      // Nearly antipodal or polar: the azimuths are sensitive to the last bit
      // of the input, so check that they describe a geodesic of length s12
      // that does reach point 2 with the stated final azimuth.
      illConditioned++;
      final d = g.direct(r[0], r[1], v.azi1, v.s12);
      expect(hit.add(groundError(d.lat2, d.lon2, r[3], r[4])), lessThan(1e-6), reason: '$r');
      expect(angleError(d.azi2, v.azi2), lessThan(1e-9), reason: '$r');
    }
    dist.report();
    azi.report();
    hit.report();
    print('inverse: $illConditioned of ${rows.length} lines needed the direct re-run');
  });

  group('hand cases (Python GeographicLib 2.0)', () {
    test('Kyiv to Lviv', () {
      final r = g.inverse(50.4501, 30.5234, 49.8397, 24.0297);
      expect(r.s12, closeTo(468952.86773761286, 1e-6));
      expect(r.azi1, closeTo(-95.819389517865, 1e-10));
      expect(r.azi2, closeTo(-100.8066611896632, 1e-10));
    });

    test('Kyiv 1000 km at -100°', () {
      final r = g.direct(50.4501, 30.5234, -100, 1e6);
      expect(r.lat2, closeTo(48.102395524576586, 1e-11));
      expect(r.lon2, closeTo(17.235637348392522, 1e-11));
      expect(r.azi2, closeTo(-110.09170787781967, 1e-10));
    });

    test('Wellington to Salamanca (nearly antipodal)', () {
      final r = g.inverse(-41.32, 174.81, 40.96, -5.50);
      expect(r.s12, closeTo(19959679.26735382, 1e-6));
      expect(r.azi1, closeTo(161.0676699861599, 1e-10));
      expect(r.azi2, closeTo(18.825195123247305, 1e-10));
    });

    test('equatorial antipodes go over the pole', () {
      final r = g.inverse(0, 0, 0, 180);
      expect(r.s12, closeTo(20003931.458625447, 1e-6));
      expect(r.azi1, 0);
      expect(r.azi2, 180);
    });

    test('pole to pole and coincident points', () {
      expect(g.inverse(90, 0, -90, 0).s12, closeTo(20003931.458625447, 1e-6));
      expect(g.inverse(20.001, 0, 20.001, 0).s12, 0);
    });

    test('equator just short of antipodal', () {
      final r = g.inverse(0, 0, 0, 179.5);
      expect(r.s12, closeTo(19980861.908890963, 1e-6));
      expect(r.azi1, closeTo(55.966495140158635, 1e-10));
    });
  });
}
