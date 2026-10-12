import 'package:horyzontal_geo/horyzontal_geo.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  final g = Geodesic.wgs84;
  List<Geodetic> pts(List<List<num>> ll) => [for (final p in ll) Geodetic(p[0].toDouble(), p[1].toDouble())];

  test('polygons in Ukraine match geographiclib', () {
    final area = MaxError('polygon area', 'm²');
    final perim = MaxError('polygon perimeter', 'm');
    for (final r in readCsv('polygons.csv')) {
      final v = [
        for (final p in r['vertices']!.split('|'))
          Geodetic(double.parse(p.split(':')[0]), double.parse(p.split(':')[1])),
      ];
      final res = g.polygon(v);
      expect(res.count, v.length);
      expect(area.add((res.area - r.d('area')).abs()), lessThan(1 + r.d('area').abs() * 1e-12));
      expect(perim.add((res.perimeter - r.d('perimeter')).abs()), lessThan(1e-6));
      expect(g.pathLength(v), closeTo(r.d('line_length'), 1e-6));
    }
    area.report();
    perim.report();
  });

  // Upstream test_geodesic.py, PlanimeterTest.
  test('pole-encircling, antimeridian and large polygons', () {
    var r = g.polygon(pts([[89, 0], [89, 90], [89, 180], [89, 270]]));
    expect(r.perimeter, closeTo(631819.8745, 1e-4));
    expect(r.area, closeTo(24952305678.0, 1));
    r = g.polygon(pts([[-89, 0], [-89, 90], [-89, 180], [-89, 270]]));
    expect(r.perimeter, closeTo(631819.8745, 1e-4));
    expect(r.area, closeTo(-24952305678.0, 1));
    r = g.polygon(pts([[0, -1], [-1, 0], [0, 1], [1, 0]]));
    expect(r.perimeter, closeTo(627598.2731, 1e-4));
    expect(r.area, closeTo(24619419146.0, 1));
    r = g.polygon(pts([[90, 0], [0, 0], [0, 90]]));
    expect(r.perimeter, closeTo(30022685, 1));
    expect(r.area, closeTo(63758202715511.0, 1));
    expect(g.pathLength(pts([[90, 0], [0, 0], [0, 90]])), closeTo(20020719, 1));

    r = g.polygon(pts([[89, 0.1], [89, 90.1], [89, -179.9]]));
    expect(r.perimeter, closeTo(539297, 1));
    expect(r.area, closeTo(12476152838.5, 1));

    for (final p in [
      [[9, -0.00000000000001], [9, 180], [9, 0]],
      [[9, 0.00000000000001], [9, 0], [9, 180]],
      [[9, 0.00000000000001], [9, 180], [9, 0]],
      [[9, -0.00000000000001], [9, 0], [9, 180]],
    ]) {
      r = g.polygon(pts(p));
      expect(r.perimeter, closeTo(36026861, 1));
      expect(r.area, closeTo(0, 1));
    }

    r = g.polygon(pts([[66.562222222, 0], [66.562222222, 180], [66.562222222, 360]]));
    expect(r.perimeter, closeTo(10465729, 1));
    expect(r.area, closeTo(0, 1));
    r = g.polygon(pts([[89, -360], [89, -240], [89, -120], [89, 0], [89, 120], [89, 240]]));
    expect(r.perimeter, closeTo(1160741, 1));
    expect(r.area, closeTo(32415230256.0, 1));

    r = g.polygon(pts([[2, 1], [1, 2], [3, 3]]));
    expect(r.area, closeTo(18454562325.45119, 0.5));
    expect(g.polygon(pts([[3, 3], [1, 2], [2, 1]])).area, closeTo(-18454562325.45119, 0.5));
    expect(g.ellipsoidArea, closeTo(510065621724088.5093, 0.5));
  });

  test('degenerate polygons', () {
    expect(g.polygon(const []).area, 0);
    expect(g.polygon(const [Geodetic(1, 1)]).perimeter, 0);
    expect(g.pathLength(const [Geodetic(1, 1)]), 0);
  });
}
