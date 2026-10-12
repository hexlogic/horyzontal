import 'package:horyzontal_geo/horyzontal_geo.dart';
import 'package:test/test.dart';

void main() {
  test('earth bulge and Fresnel radius', () {
    // d1·d2·(1-k)/2R: 10 km each side, k = 0.13.
    expect(earthBulge(10000, 10000), closeTo(1e8 * 0.87 / (2 * 6371008.8), 1e-9));
    expect(earthBulge(10000, 10000), closeTo(6.83, 0.01));
    expect(earthBulge(0, 20000), 0);
    // 4/3 Earth: k = 0.25.
    expect(earthBulge(10000, 10000, k: refractionRadio), closeTo(5.89, 0.01));
    // 2.4 GHz, 1 km link, midpoint: about 5.59 m.
    expect(fresnelRadius(500, 500, 2.4e9), closeTo(5.59, 0.01));
    expect(gaussianRadius(48), closeTo(6379500, 1000));
  });

  List<double> dist(int n, double total) => [for (var i = 0; i < n; i++) total * i / (n - 1)];

  test('a ridge blocks the view, a taller mast clears it', () {
    final d = dist(11, 10000);
    final terrain = <double?>[100, 100, 100, 100, 100, 130, 100, 100, 100, 100, 100];
    final low = lineOfSight(distances: d, terrain: terrain, mastA: 10, mastB: 10)!;
    expect(low.visible, isFalse);
    expect(low.worstIndex, 5);
    expect(low.firstObstruction, 5000);
    expect(low.minClearance, closeTo(110 - 130 - earthBulge(5000, 5000), 1e-9));

    final high = lineOfSight(distances: d, terrain: terrain, mastA: 40, mastB: 40)!;
    expect(high.visible, isTrue);
    expect(high.firstObstruction, isNull);
    expect(high.complete, isTrue);
  });

  test('Fresnel zone check', () {
    final d = dist(3, 2000);
    final r = lineOfSight(distances: d, terrain: [0, 0, 0], mastA: 3, mastB: 3, frequencyHz: 2.4e9)!;
    expect(r.visible, isTrue);
    final f = fresnelRadius(1000, 1000, 2.4e9);
    expect(r.minFresnelRatio, closeTo((3 - earthBulge(1000, 1000)) / f, 1e-9));
    expect(r.fresnelClear, isFalse);
    final t = lineOfSight(distances: d, terrain: [0, 0, 0], mastA: 15, mastB: 15, frequencyHz: 2.4e9)!;
    expect(t.fresnelClear, isTrue);
  });

  test('gaps and unknown ends', () {
    final d = dist(5, 4000);
    final r = lineOfSight(distances: d, terrain: [0, null, 0, 0, 0], mastA: 2, mastB: 2)!;
    expect(r.complete, isFalse);
    expect(r.visible, isTrue);
    expect(lineOfSight(distances: d, terrain: [null, 0, 0, 0, 0], mastA: 2, mastB: 2), isNull);
  });
}
