import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal/core/data/model.dart';
import 'package:horyzontal/features/exchange/formats/formats.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

final t0 = DateTime.utc(2026, 10, 1, 8, 30, 15, 123);
final t1 = DateTime.utc(2026, 10, 2, 9, 45, 0, 456);
final now = DateTime.utc(2026, 10, 12, 12);

Uint8List fixture(String name) => File('test/formats/fixtures/$name').readAsBytesSync();

MapLayer layer(String id, String name, {int color = 0xFFC62828}) => MapLayer(
  id: id,
  name: name,
  color: color,
  visible: true,
  archived: false,
  createdAt: t0,
  updatedAt: t1,
);

MapFeature feature(
  String id,
  String layerId,
  FeatureKind kind,
  List<Geodetic> v, {
  String name = '',
  String description = '',
  String author = '',
  String? sidc,
  int? color,
  double? radius,
  Map<String, Object?> extra = const {},
}) => MapFeature(
  id: id,
  layerId: layerId,
  kind: kind,
  vertices: v,
  name: name,
  description: description,
  author: author,
  sidc: sidc,
  color: color,
  radius: radius,
  extra: extra,
  createdAt: t0,
  updatedAt: t1,
);

const layerA = '0c6f1a3e-2b8d-4f5a-9e7c-1d2b3c4d5e6f';
const layerB = '7a1b2c3d-4e5f-4a6b-8c7d-9e0f1a2b3c4d';

/// Two layers with every kind of object, Cyrillic text, altitudes and
/// symbols: the reference for round trips.
List<LayerBundle> sampleLayers() => [
  LayerBundle(layer(layerA, 'Опорний пункт «Сокіл»'), [
    feature(
      '11111111-1111-4111-8111-111111111111',
      layerA,
      FeatureKind.point,
      [const Geodetic(50.4501, 30.5234, 170.5)],
      name: 'КСП 1/72',
      description: 'Командно-спостережний пункт.\nДругий рядок & <теги>',
      author: 'SOKIL',
      sidc: '10031000001211000000',
      color: 0xFF2E7D32,
      radius: 150,
      extra: const {'note': 'залишок імпорту', 'n': 3},
    ),
    feature(
      '22222222-2222-4222-8222-222222222222',
      layerA,
      FeatureKind.point,
      [const Geodetic(48.5079, 32.2623)],
      name: 'Ворожий танк',
      sidc: '10061500001202000000',
    ),
    feature(
      '33333333-3333-4333-8333-333333333333',
      layerA,
      FeatureKind.polyline,
      [
        const Geodetic(50.1, 30.1, 120),
        const Geodetic(50.2, 30.25, 130),
        const Geodetic(50.3, 30.4, 125.25),
      ],
      name: 'Маршрут висування',
      color: 0xFF1565C0,
    ),
    feature(
      '44444444-4444-4444-8444-444444444444',
      layerA,
      FeatureKind.polygon,
      [
        const Geodetic(49.0, 31.0),
        const Geodetic(49.0, 31.1),
        const Geodetic(49.1, 31.1),
        const Geodetic(49.1, 31.0),
      ],
      name: 'Мінне поле',
      description: 'Протипіхотні',
    ),
  ]),
  LayerBundle(layer(layerB, 'Second layer', color: 0xFF6A1B9A), [
    feature('55555555-5555-4555-8555-555555555555', layerB, FeatureKind.point, [
      const Geodetic(-33.8688, 151.2093, -12.5),
    ], name: 'Sydney'),
  ]),
];

Future<ImportResult> roundTrip(List<LayerBundle> layers, ExportFormat f) => importFile(
  suggestedFileName(layers, f),
  exportLayers(layers, f, now: now, appVersion: '0.1.0'),
  now: now,
);

/// Compares vertices to [tol] degrees and [hTol] metres.
void expectVertices(
  List<Geodetic> actual,
  List<Geodetic> expected, {
  double tol = 1e-7,
  double hTol = 1e-3,
}) {
  expect(actual.length, expected.length, reason: 'vertex count');
  for (var i = 0; i < actual.length; i++) {
    expect(actual[i].lat, closeTo(expected[i].lat, tol));
    expect(actual[i].lon, closeTo(expected[i].lon, tol));
    expect(actual[i].h, closeTo(expected[i].h, hTol));
  }
}

/// Every field the format carries, compared feature by feature (by id).
void expectSameFeatures(
  List<MapFeature> actual,
  List<MapFeature> expected, {
  bool times = true,
  bool extra = true,
}) {
  expect(actual.map((f) => f.id).toSet(), expected.map((f) => f.id).toSet());
  for (final e in expected) {
    final a = actual.firstWhere((f) => f.id == e.id);
    expect(a.kind, e.kind, reason: e.name);
    expect(a.name, e.name);
    expect(a.description, e.description);
    expect(a.author, e.author);
    expect(a.sidc, e.sidc);
    expect(a.color, e.color, reason: 'colour of ${e.name}');
    expect(a.radius, e.radius);
    expectVertices(a.vertices, e.vertices);
    if (extra) expect(a.extra, e.extra);
    if (times) {
      expect(a.createdAt, e.createdAt);
      expect(a.updatedAt, e.updatedAt);
    }
  }
}
