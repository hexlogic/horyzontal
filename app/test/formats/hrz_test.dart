import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal/core/data/model.dart';
import 'package:horyzontal/features/exchange/formats/formats.dart';

import 'samples.dart';

void main() {
  test('round trip is lossless, layer ids kept', () async {
    final layers = sampleLayers();
    final r = await roundTrip(layers, ExportFormat.hrz);
    expect(r.warnings, isEmpty);
    expect(r.layers, hasLength(2));
    for (var i = 0; i < 2; i++) {
      final a = r.layers[i].layer, e = layers[i].layer;
      expect(a.id, e.id);
      expect(a.name, e.name);
      expect(a.color, e.color);
      expect(a.createdAt, e.createdAt);
      expect(a.updatedAt, e.updatedAt);
      expect(r.layers[i].features.every((f) => f.layerId == e.id), isTrue);
      expectSameFeatures(r.layers[i].features, layers[i].features);
    }
    // Full double precision, not rounded.
    expect(r.layers[0].features.first.vertices.first.lat, 50.4501);
    expect(r.layers[0].features.first.vertices.first.h, 170.5);
  });

  test('document header', () {
    final bytes = exportLayers(sampleLayers(), ExportFormat.hrz, now: now, appVersion: '0.1.0');
    final doc = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
    expect(doc['format'], 'horyzontal');
    expect(doc['version'], 1);
    expect(doc['exported'], '2026-10-12T12:00:00.000Z');
    expect(doc['app'], '0.1.0');
    final f = ((doc['layers']! as List).first as Map)['features'] as List;
    expect((f.first as Map)['vertices'], [
      [50.4501, 30.5234, 170.5],
    ]);
    // h == 0 is omitted.
    expect((f[1] as Map)['vertices'], [
      [48.5079, 32.2623],
    ]);
  });

  test('unknown fields are ignored, newer versions refused', () async {
    final doc = {
      'format': 'horyzontal',
      'version': 1,
      'future': {'x': 1},
      'layers': [
        {
          'id': layerA,
          'name': 'Шар',
          'color': 4280600000,
          'unknown': true,
          'features': [
            {
              'id': '11111111-1111-4111-8111-111111111111',
              'kind': 'point',
              'vertices': [
                [50, 30],
              ],
              'newField': 'x',
            },
            {'id': 'x', 'kind': 'circle', 'vertices': []},
          ],
        },
      ],
    };
    final r = await importFile('a.hrz', utf8.encode(jsonEncode(doc)), now: now);
    expect(r.layers.single.features.single.kind, FeatureKind.point);
    expect(r.layers.single.layer.color, 4280600000);
    expect(r.layers.single.features.single.createdAt, now);
    expect(r.warnings.map((w) => w.code), [ImportWarning.hrzUnknownKind]);

    doc['version'] = 2;
    await expectLater(
      importFile('a.hrz', utf8.encode(jsonEncode(doc))),
      throwsA(
        isA<ImportException>().having((e) => e.code, 'code', ImportException.unsupportedVersion),
      ),
    );
  });

  test('bad coordinates and broken JSON', () async {
    final doc = {
      'format': 'horyzontal',
      'version': 1,
      'layers': [
        {
          'id': layerA,
          'name': 'L',
          'features': [
            {
              'id': '1',
              'kind': 'point',
              'vertices': [
                [95, 30],
              ],
            },
            {
              'id': '2',
              'kind': 'polyline',
              'vertices': [
                [50, 30],
              ],
            },
            {
              'id': '3',
              'kind': 'point',
              'vertices': [
                [50, 'x'],
              ],
            },
          ],
        },
      ],
    };
    final r = await importFile('a.hrz', utf8.encode(jsonEncode(doc)));
    expect(r.layers.single.features, isEmpty);
    expect(r.warnings.map((w) => w.code), [
      ImportWarning.badCoordinate,
      ImportWarning.invalidFeature,
      ImportWarning.badCoordinate,
    ]);
    await expectLater(
      importFile('a.hrz', utf8.encode('{"format":"horyzontal", "version": 1, "layers": [')),
      throwsA(isA<ImportException>().having((e) => e.code, 'code', ImportException.malformed)),
    );
  });
}
