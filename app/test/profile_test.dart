import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal/core/dem/dem_reader.dart';
import 'package:horyzontal/features/map/elevation.dart';
import 'package:horyzontal/features/map/tools/profile_page.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

import 'fake_tiles.dart';
import 'helpers.dart';

const _bounds = (west: 29.0, south: 49.0, east: 32.0, north: 52.0);

/// A ridge 300 m high running north-south through 30.5°E on a 100 m plain.
Dem ridgeDem() {
  final (rx, _) = pixelAt(50.4, 30.5);
  double h(double gx, double gy) => 100 + 200 * (1 - ((gx - rx).abs() / 40).clamp(0.0, 1.0));
  return Dem(const [], DemReader([FakeTiles(h, null, _bounds)], cacheTiles: 256));
}

void main() {
  const a = Geodetic(50.4, 30.45), b = Geodetic(50.4, 30.55);

  test('profile over a ridge', () async {
    final p = await buildProfile(ridgeDem(), [a, b]);
    expect(p.points.length, profileSamples(7100));
    expect(p.complete, isTrue);
    expect(p.min, closeTo(100, 0.1));
    expect(p.max, closeTo(300, 2));
    final (up, down) = p.ascentDescent;
    expect(up, closeTo(200, 2));
    expect(down, closeTo(200, 2));
    expect(p.distances.last, closeTo(Geodesic.wgs84.inverse(a.lat, a.lon, b.lat, b.lon).s12, 1e-6));
  });

  test('outside the packs the profile is empty', () async {
    final p = await buildProfile(ridgeDem(), const [Geodetic(46, 35), Geodetic(46.01, 35)]);
    expect(p.empty, isTrue);
  });

  testWidgets('profile page shows heights and the ends', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final dem = ridgeDem();
    await tester.pumpWidget(
      testApp(const ProfilePage(path: [a, b]), overrides: [demProvider.overrideWith((ref) async => dem)]),
    );
    for (var i = 0; i < 10 && find.byType(CircularProgressIndicator).evaluate().isNotEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump();
    }
    expect(find.textContaining('100 м / 29'), findsOneWidget); // min / max
    expect(find.textContaining('+19'), findsOneWidget); // ascent
    expect(find.textContaining('Початкова точка'), findsOneWidget);
    expect(find.text('Висоти Copernicus DEM — модель поверхні: вони включають ліс і будівлі'), findsOneWidget);
  });
}
