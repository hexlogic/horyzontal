import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal/core/data/model.dart';
import 'package:horyzontal/features/exchange/formats/formats.dart';
import 'package:horyzontal/features/exchange/formats/kml_format.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

import 'samples.dart';

void main() {
  group('round trip', () {
    for (final format in [ExportFormat.kml, ExportFormat.kmz]) {
      test(format.name, () async {
        final layers = sampleLayers();
        final r = await roundTrip(layers, format);
        expect(r.warnings, isEmpty);
        expect(r.layers.map((l) => l.layer.name), [for (final l in layers) l.layer.name]);
        for (var i = 0; i < layers.length; i++) {
          final got = r.layers[i];
          expect(got.layer.id, isNot(layers[i].layer.id), reason: 'new layer id');
          expect(got.layer.color, layers[i].layer.color);
          expect(got.layer.createdAt, layers[i].layer.createdAt);
          expect(got.features.every((f) => f.layerId == got.layer.id), isTrue);
          expectSameFeatures(got.features, layers[i].features);
        }
      });
    }
  });

  test('export: folders, colours, altitude, ExtendedData', () {
    final kml = utf8.decode(exportLayers(sampleLayers(), ExportFormat.kml, now: now));
    expect(kml, contains('<name>Опорний пункт «Сокіл» +1</name>'));
    expect('<Folder>'.allMatches(kml), hasLength(2));
    // ARGB 0xFF2E7D32 → aabbggrr ff327d2e.
    expect(kml, contains('<IconStyle><color>ff327d2e</color></IconStyle>'));
    expect(
      kml,
      contains('<altitudeMode>absolute</altitudeMode><coordinates>30.5234,50.4501,170.5'),
    );
    // 2D point: no altitude, no mode.
    expect(kml, contains('<Point><coordinates>32.2623,48.5079</coordinates></Point>'));
    // Polygon ring is closed.
    expect(kml, contains('31,49 31.1,49 31.1,49.1 31,49.1 31,49'));
    expect(kml, contains('<Data name="hrz:sidc"><value>10031000001211000000</value></Data>'));
    expect(kml, contains('Другий рядок &amp; &lt;теги&gt;'));
  });

  test('colour conversion', () {
    expect(kmlColor(0xFF112233), 'ff332211');
    expect(parseKmlColor('ff332211'), 0xFF112233);
    expect(parseKmlColor('#7f0000ff'), 0x7FFF0000);
    expect(parseKmlColor('332211'), 0xFF112233);
    expect(parseKmlColor('nope'), isNull);
  });

  test('Google Earth file: styles, nested folders, MultiGeometry, skipped parts', () async {
    final r = await importFile('Розвідка.kml', fixture('google_earth.kml'), now: now);
    expect(r.layers.map((l) => l.layer.name), [
      'Спостереження',
      'Спостереження / Маршрути',
      'Зони',
    ]);

    final obs = r.layers[0].features;
    expect(obs, hasLength(2));
    final mortar = obs[0];
    expect(mortar.name, 'Позиція міномету');
    expect(mortar.description, '<b>Миномёт</b> 120 мм, 2 шт.');
    expect(mortar.color, 0xFFFF0000, reason: 'StyleMap normal → IconStyle ff0000ff');
    expectVertices(mortar.vertices, [const Geodetic(48.0123456, 37.8012345)]);
    expect(mortar.createdAt, DateTime.utc(2026, 10, 11, 6, 15));
    expect(mortar.sidc, isNull);
    expect(obs[1].vertices.single.h, 212.4, reason: 'absolute altitude kept');

    final routes = r.layers[1].features;
    expect(routes.single.kind, FeatureKind.polyline);
    expect(routes.single.vertices, hasLength(3));
    expect(routes.single.color, 0xFFFFAA00);
    expect(routes.single.vertices.every((v) => v.h == 0), isTrue, reason: 'clampToGround');

    final zones = r.layers[2].features;
    expect(zones.map((f) => (f.name, f.kind)), [
      ('Лісосмуга', FeatureKind.polygon),
      ('Поле', FeatureKind.polygon),
      ('Перехрестя і під\'їзд', FeatureKind.point),
      ('Перехрестя і під\'їзд', FeatureKind.polyline),
    ]);
    expect(zones[0].vertices, hasLength(4), reason: 'closing vertex dropped');
    expect(zones[0].color, 0xFFFF0000, reason: 'outline colour');
    expect(zones[1].color, 0xFF00FF00, reason: 'fill colour made opaque');
    expect(zones[2].id, isNot(zones[3].id));

    expect(r.warnings.map((w) => (w.code, w.detail)), [
      (ImportWarning.overlayIgnored, 'Онлайн-шар'),
      (ImportWarning.trackIgnored, 'Трек'),
      (ImportWarning.innerBoundaryDropped, 'Лісосмуга'),
      (ImportWarning.badCoordinate, 'Помилка'),
      (ImportWarning.invalidFeature, 'Без геометрії'),
    ]);
  });

  test('a file without folders is one layer named after the Document', () async {
    final r = await importFile('evac.kml', fixture('plain_document.kml'), now: now);
    expect(r.layers.single.layer.name, 'Точки евакуації');
    expect(r.layers.single.layer.color, 0xFF1565C0);
    expect(r.layers.single.features.map((f) => f.name), ['ТЕ-1', 'ТЕ-2 &  резерв']);
    expect(r.layers.single.features[1].description, 'Біля школи');
  });

  test('bare placemarks with an undeclared gx: prefix, named after the file', () async {
    final r = await importFile('Львів точки.kml', fixture('undeclared_prefix.kml'), now: now);
    expect(r.layers.single.layer.name, 'Львів точки');
    expect(r.layers.single.features.single.name, 'Waypoint');
    expect(r.warnings.single.code, ImportWarning.trackIgnored);
  });

  test('KMZ: doc.kml, or the first .kml', () async {
    final kml = fixture('plain_document.kml');
    for (final name in ['doc.kml', 'files/other.kml']) {
      final archive = Archive()
        ..add(ArchiveFile.bytes('images/icon.png', [1, 2, 3]))
        ..add(ArchiveFile.bytes(name, kml));
      final r = await importFile('x.kmz', ZipEncoder().encodeBytes(archive), now: now);
      expect(r.layers.single.features, hasLength(2), reason: name);
    }
  });

  test('an empty layer survives the round trip', () async {
    final layers = [LayerBundle(layer(layerA, 'Порожній'), const [])];
    final r = await roundTrip(layers, ExportFormat.kml);
    expect(r.layers.single.layer.name, 'Порожній');
    expect(r.layers.single.features, isEmpty);
  });

  test('re-importing the same export keeps feature ids', () async {
    final bytes = exportLayers(sampleLayers(), ExportFormat.kml, now: now);
    final a = await importFile('a.kml', bytes), b = await importFile('a.kml', bytes);
    expect(
      a.layers.expand((l) => l.features).map((f) => f.id).toList(),
      b.layers.expand((l) => l.features).map((f) => f.id).toList(),
    );
  });
}
