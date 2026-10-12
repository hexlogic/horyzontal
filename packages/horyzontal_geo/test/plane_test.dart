import 'package:horyzontal_geo/horyzontal_geo.dart';
import 'package:test/test.dart';

void main() {
  test('direct and inverse on the plane', () {
    const a = PlanePoint(5593957, 6324233);
    final b = planeDirect(a, 1000, 45);
    expect(b.x, closeTo(5593957 + 707.1068, 1e-4));
    expect(b.y, closeTo(6324233 + 707.1068, 1e-4));
    final inv = planeInverse(a, b);
    expect(inv.distance, closeTo(1000, 1e-9));
    expect(inv.bearing, closeTo(45, 1e-9));
    expect(inv.backBearing, closeTo(225, 1e-9));
  });

  test('bearing quadrants', () {
    const o = PlanePoint(0, 0);
    expect(planeInverse(o, const PlanePoint(1, 0)).bearing, 0);
    expect(planeInverse(o, const PlanePoint(0, 1)).bearing, closeTo(90, 1e-12));
    expect(planeInverse(o, const PlanePoint(-1, 0)).bearing, closeTo(180, 1e-12));
    expect(planeInverse(o, const PlanePoint(0, -1)).bearing, closeTo(270, 1e-12));
    expect(planeInverse(o, o).distance, 0);
  });
}
