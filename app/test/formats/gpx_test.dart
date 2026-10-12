import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal/core/data/model.dart';
import 'package:horyzontal/features/exchange/formats/formats.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

import 'samples.dart';

void main() {
  test('round trip: layers split again, polygons restored', () async {
    final layers = sampleLayers();
    final r = await roundTrip(layers, ExportFormat.gpx);
    expect(r.warnings, isEmpty);
    expect(r.layers.map((l) => l.layer.name), [for (final l in layers) l.layer.name]);
    for (var i = 0; i < layers.length; i++) {
      expect(r.layers[i].layer.color, layers[i].layer.color);
      expect(r.layers[i].layer.id, isNot(layers[i].layer.id));
      expectSameFeatures(r.layers[i].features, layers[i].features);
    }
  });

  test('export is GPX 1.1 with wpt before trk and OsmAnd colours', () {
    final gpx = utf8.decode(exportLayers(sampleLayers(), ExportFormat.gpx, now: now));
    expect(gpx, contains('<gpx version="1.1" creator="Horyzontal"'));
    expect(gpx.lastIndexOf('<wpt'), lessThan(gpx.indexOf('<trk>')));
    expect(gpx, contains('<wpt lat="50.4501" lon="30.5234">\n    <ele>170.5</ele>'));
    expect(gpx, contains('<hrz:kind>polygon</hrz:kind>'));
    expect(gpx, contains('<osmand:color>#FF2E7D32</osmand:color>'));
    // The polygon's track is closed.
    final polygon = gpx.substring(gpx.indexOf('Мінне поле'));
    expect(
      'lat="49" lon="31"/>'.allMatches(polygon.substring(0, polygon.indexOf('</trk>'))),
      hasLength(2),
    );
  });

  test('OsmAnd file: one layer, waypoints, route, track segments', () async {
    final r = await importFile('track.gpx', fixture('osmand.gpx'), now: now);
    final l = r.layers.single;
    expect(l.layer.name, 'Вихід 11 жовтня');
    final f = l.features;
    expect(f.map((x) => (x.name, x.kind)), [
      ('Криниця', FeatureKind.point),
      ('Без висоти', FeatureKind.point),
      ('План', FeatureKind.polyline),
      ('Запис треку', FeatureKind.polyline),
      ('Запис треку', FeatureKind.polyline),
    ]);
    expect(f[0].description, 'Питна вода');
    expect(f[0].color, 0xFF1E88E5);
    expect(f[0].createdAt, DateTime.utc(2026, 10, 11, 5, 10));
    expectVertices(f[0].vertices, [const Geodetic(49.8397, 24.0297, 296.3)]);
    expect(f[1].vertices.single.h, 0);
    expect(f[1].createdAt, now);
    expect(f[3].vertices, hasLength(3));
    expect(f[3].vertices.last.h, 298.5);
    expect(f[3].color, 0xC0E53935);
    expect(f[3].id, isNot(f[4].id));
    expect(r.warnings.map((w) => (w.code, w.detail)), [
      (ImportWarning.badCoordinate, 'Погана точка'),
      (ImportWarning.invalidFeature, 'Запис треку'),
    ]);
  });

  test('a file without a name is named after the file; GPX 1.0 name', () async {
    const body = '<trk><trkseg><trkpt lat="1" lon="2"/><trkpt lat="1.1" lon="2.1"/></trkseg></trk>';
    var r = await importFile(
      'Маршрут 3.gpx',
      utf8.encode('<gpx version="1.1" xmlns="http://www.topografix.com/GPX/1/1">$body</gpx>'),
    );
    expect(r.layers.single.layer.name, 'Маршрут 3');
    r = await importFile(
      'x.gpx',
      utf8.encode(
        '<gpx version="1.0" xmlns="http://www.topografix.com/GPX/1/0"><name>Old</name>$body</gpx>',
      ),
    );
    expect(r.layers.single.layer.name, 'Old');
    expect(r.layers.single.features.single.kind, FeatureKind.polyline);
  });

  test('a closed track without the flag stays a polyline', () async {
    const gpx =
        '<gpx version="1.1"><trk><trkseg><trkpt lat="1" lon="2"/><trkpt lat="1.1" lon="2"/>'
        '<trkpt lat="1.1" lon="2.1"/><trkpt lat="1" lon="2"/></trkseg></trk></gpx>';
    final r = await importFile('x.gpx', utf8.encode(gpx));
    expect(r.layers.single.features.single.kind, FeatureKind.polyline);
    expect(r.layers.single.features.single.vertices, hasLength(4));
  });
}
