import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal/features/map/tools/tool_geojson.dart';
import 'package:horyzontal/features/map/tools/tool_readouts.dart';
import 'package:horyzontal/features/map/tools/tool_state.dart';
import 'package:horyzontal/features/tasks/problems.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

void main() {
  final g = Geodesic.wgs84;
  const a = Geodetic(48.60, 37.90);
  Geodetic dir(Geodetic p, double azi, double s) {
    final r = g.direct(p.lat, p.lon, azi, s);
    return Geodetic(r.lat2, r.lon2);
  }

  final at = DateTime.utc(2026, 10, 12);

  test('ruler agrees with the inverse problem', () {
    final b = dir(a, 75, 6000);
    final frame = PlaneFrame.auto(a, CoordinateSystem.sk42Gk);
    final r = rulerReadout(a, b, null, frame, at: at);
    final inv = solveInverse(a, b, ProblemMethod.ellipsoid, frame, at: at);
    expect(r.distance, closeTo(inv.ellipsoidDistance, 1e-6));
    for (final k in AngleKind.values) {
      expect(r.forward.of(k), closeTo(inv.forward.of(k), 1e-9));
      expect(r.back.of(k), closeTo(inv.back.of(k), 1e-9));
    }
    final pa = frame.project(a), pb = frame.project(b);
    expect(r.dx, closeTo(pb.x - pa.x, 1e-6));
    expect(r.dy, closeTo(pb.y - pa.y, 1e-6));
    expect(r.deviation, isNull);
  });

  test('ruler deviation of the crosshair', () {
    final b = dir(a, 75, 6000);
    final c = dir(a, 76, 6200);
    final r = rulerReadout(a, b, c, PlaneFrame.auto(a, CoordinateSystem.wgs84), at: at);
    expect(r.deviation!.angle, closeTo(1, 1e-9));
    expect(r.deviation!.range, greaterThan(0)); // over
    expect(r.deviation!.cross, greaterThan(0)); // right
    final live = rulerReadout(a, c, c, PlaneFrame.auto(a, CoordinateSystem.wgs84), fixed: false, at: at);
    expect(live.deviation, isNull);
  });

  test('path readout: polygon area and the crosshair as the next vertex', () {
    final b = dir(a, 90, 1000), c = dir(b, 0, 1000);
    final r = pathReadout([a, b, c], dir(a, 0, 1000), closed: true);
    expect(r.polygon!.area.abs(), closeTo(500000, 500));
    expect(r.withNext, closeTo(1e6, 1000));
    final open = pathReadout([a, b], c, closed: false);
    expect(open.metrics.length, closeTo(1000, 1e-6));
    expect(open.withNext, closeTo(2000, 1e-3));
    expect(open.nextAngle, closeTo(90, 0.02));
  });

  test('tool controller: two-point tools replace the second point', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final ctl = c.read(mapToolProvider.notifier);
    ctl.start(MapTool.ruler);
    ctl.add(a);
    ctl.add(dir(a, 0, 100));
    ctl.add(dir(a, 0, 200));
    expect(c.read(mapToolProvider).vertices, hasLength(2));
    expect(c.read(mapToolProvider).ready, isTrue);
    ctl.undo();
    expect(c.read(mapToolProvider).vertices.single.lat, a.lat);
    ctl.start(MapTool.polygon);
    for (var i = 0; i < 4; i++) {
      ctl.add(dir(a, i * 90.0, 100));
    }
    expect(c.read(mapToolProvider).vertices, hasLength(4));
    ctl.close();
    expect(c.read(mapToolProvider).active, isFalse);
  });

  test('overlay GeoJSON', () {
    final b = dir(a, 90, 50000);
    List<String> kinds(Map<String, Object?> fc) => [
      for (final f in (fc['features'] as List).cast<Map<String, Object?>>())
        (f['properties'] as Map)['kind'] as String,
    ];
    final ruler = toolGeoJson(ToolState(MapTool.ruler, [a, b]), dir(a, 80, 30000));
    expect(kinds(ruler), ['line', 'rubber', 'vertex', 'vertex']);
    final line = (ruler['features'] as List).first as Map;
    // A 50 km edge is drawn as a curve of many points.
    expect(((line['geometry'] as Map)['coordinates'] as List).length, greaterThan(10));
    final poly = toolGeoJson(ToolState(MapTool.polygon, [a, b, dir(b, 0, 1000)]), dir(a, 0, 1000));
    expect(kinds(poly), ['fill', 'line', 'rubber', 'vertex', 'vertex', 'vertex']);
    expect(kinds(toolGeoJson(const ToolState(), a)), isEmpty);
  });
}
