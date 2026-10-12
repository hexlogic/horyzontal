import 'package:horyzontal_geo/horyzontal_geo.dart';
import 'package:test/test.dart';

void main() {
  final g = Geodesic.wgs84;
  Geodetic dir(Geodetic p, double azi, double s) {
    final r = g.direct(p.lat, p.lon, azi, s);
    return Geodetic(r.lat2, r.lon2);
  }

  test('square of geodesics has right angles inside', () {
    const a = Geodetic(50.45, 30.52);
    final b = dir(a, 90, 1000);
    final c = dir(b, 0, 1000);
    final d = dir(a, 0, 1000);
    for (final ring in [
      [a, b, c, d],
      [d, c, b, a],
    ]) {
      final m = pathMetrics(ring, closed: true);
      expect(m.segments, hasLength(4));
      // Meridians converge, so the corners are 90° only to about 0.01°.
      expect(m.length, closeTo(4000, 0.5));
      for (final angle in m.interiorAngles!) {
        expect(angle, closeTo(90, 0.02));
      }
      expect(m.interiorAngles!.reduce((x, y) => x + y), closeTo(360, 1e-4));
    }
  });

  test('interior angles of a concave polygon sum to (n-2)·180', () {
    const o = Geodetic(48.5, 35.0);
    final ring = [o, dir(o, 90, 3000), dir(o, 60, 1500), dir(o, 30, 3000), dir(o, 0, 3000)];
    for (final r in [ring, ring.reversed.toList()]) {
      final m = pathMetrics(r, closed: true);
      final sum = m.interiorAngles!.reduce((x, y) => x + y);
      expect(sum, closeTo(540, 1e-3));
      expect(m.interiorAngles!.any((x) => x > 180), isTrue); // the dent
    }
  });

  test('turns of an open path', () {
    // Each edge leaves at the arrival azimuth of the previous one plus a turn.
    const a = Geodetic(50, 30);
    final ab = g.direct(a.lat, a.lon, 10, 1000);
    final bc = g.direct(ab.lat2, ab.lon2, ab.azi2 + 45, 1000); // right turn
    final cd = g.direct(bc.lat2, bc.lon2, bc.azi2 - 45, 1000); // left turn
    final b = Geodetic(ab.lat2, ab.lon2), c = Geodetic(bc.lat2, bc.lon2), d = Geodetic(cd.lat2, cd.lon2);
    final m = pathMetrics([a, b, c, d]);
    expect(m.segments, hasLength(3));
    expect(m.turns.first, isNull);
    expect(m.turns.last, isNull);
    expect(m.turns[1], closeTo(45, 1e-6));
    expect(m.turns[2], closeTo(-45, 1e-6));
    expect(m.vertexAngles[1], closeTo(135, 1e-6));
    expect(m.interiorAngles, isNull);
  });

  test('densify spreads points evenly by distance', () {
    const a = Geodetic(50, 30);
    final b = dir(a, 80, 3000);
    final c = dir(b, 170, 1000);
    final pts = densify([a, b, c], 9);
    expect(pts, hasLength(9));
    expect(pts.first.lat, a.lat);
    expect(pts.last.lat, c.lat);
    final d = cumulativeDistances(pts);
    for (var i = 1; i < d.length; i++) {
      expect(d[i] - d[i - 1], closeTo(500, 1e-6));
    }
    expect(cumulativeDistances([a, b, c]).last, closeTo(4000, 1e-6));
  });
}
