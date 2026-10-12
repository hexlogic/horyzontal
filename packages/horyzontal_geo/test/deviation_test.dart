import 'package:horyzontal_geo/horyzontal_geo.dart';
import 'package:test/test.dart';

void main() {
  final g = Geodesic.wgs84;
  const a = Geodetic(48.6, 37.9);
  Geodetic dir(double azi, double s) {
    final r = g.direct(a.lat, a.lon, azi, s);
    return Geodetic(r.lat2, r.lon2);
  }

  final b = dir(70, 8000);

  test('point to the right and beyond', () {
    final c = dir(70 + 2, 8300);
    final d = trackDeviation(a, b, c);
    expect(d.angle, closeTo(2, 1e-9));
    expect(d.distance, closeTo(8300, 1e-6));
    expect(d.cross, closeTo(8300 * 0.0348995, 1e-3));
    expect(d.range, closeTo(8300 * 0.9993908 - 8000, 1e-3));
  });

  test('point to the left and short', () {
    final d = trackDeviation(a, b, dir(70 - 3, 7500));
    expect(d.angle, closeTo(-3, 1e-9));
    expect(d.cross, lessThan(0));
    expect(d.range, lessThan(0));
  });

  test('point on the line', () {
    final d = trackDeviation(a, b, dir(70, 9000));
    expect(d.cross.abs(), lessThan(1e-6));
    expect(d.range, closeTo(1000, 1e-6));
    expect(trackDeviation(a, b, a).distance, 0);
  });

  test('close to the geodesic cross-track distance at 20 km', () {
    // Foot of the perpendicular on A→B, then 300 m off it at a right angle.
    final foot = g.direct(a.lat, a.lon, 70, 20000);
    final c = g.direct(foot.lat2, foot.lon2, foot.azi2 + 90, 300);
    final d = trackDeviation(a, dir(70, 20000), Geodetic(c.lat2, c.lon2));
    expect(d.cross, closeTo(300, 0.2));
    expect(d.range, closeTo(0, 3)); // second-order: 300²/(2·20000) ≈ 2.2 m
  });
}
