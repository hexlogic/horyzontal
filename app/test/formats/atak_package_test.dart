import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';
import 'package:horyzontal/core/data/model.dart';
import 'package:horyzontal/features/exchange/formats/formats.dart';
import 'package:xml/xml.dart';

import 'samples.dart';

/// The fixture tree under fixtures/atak_package as a zip, optionally
/// without some entries.
Uint8List packageFixture({bool Function(String path)? keep}) {
  final dir = Directory('test/formats/fixtures/atak_package');
  final archive = Archive();
  for (final f in dir.listSync(recursive: true).whereType<File>()) {
    final path = f.path.substring(dir.path.length + 1);
    if (keep != null && !keep(path)) continue;
    archive.add(ArchiveFile.bytes(path, f.readAsBytesSync()));
  }
  return ZipEncoder().encodeBytes(archive);
}

Map<String, Uint8List> unzip(Uint8List bytes) => {
  for (final f in ZipDecoder().decodeBytes(bytes))
    if (f.isFile) f.name: f.readBytes()!,
};

void main() {
  test('ATAK-made package: manifest, markers, shapes, KML overlay', () async {
    final r = await importFile('pkg.zip', packageFixture(), now: now);
    expect(r.layers.map((l) => l.layer.name), ['Рубежі', 'Позиції 3 роти']);

    final kml = r.layers[0].features.single;
    expect(kml.name, 'Рубіж 1');
    expect(kml.kind, FeatureKind.polyline);
    expect(kml.color, 0xFFFFFF00);

    final f = {for (final x in r.layers[1].features) x.name: x};
    expect(f.keys, [
      'РСЗВ Град',
      'Лінія оборони',
      'Мінне поле',
      'Район зосередження',
      'Зона ураження',
    ]);
    final mlrs = f['РСЗВ Град']!;
    expect(mlrs.id, '9a3b7c1e-5d2f-4e8a-b6c4-0f1e2d3c4b5a');
    expect(mlrs.sidc, '10061500001116000000');
    expect(mlrs.author, 'ORLAN');
    final v = mlrs.vertices.single;
    expect(v.h, closeTo(187.2 - Geoid.egm2008Ukraine.undulation(v.lat, v.lon)!, 1e-9));
    expect(mlrs.description, '2 одиниці');

    final line = f['Лінія оборони']!;
    expect(line.kind, FeatureKind.polyline);
    expect(line.vertices, hasLength(3));
    expect(line.color, 0xFFFFFF00);
    expect(line.sidc, isNull);
    expect(line.extra, {'cotUid': 'line-1', 'cotType': 'u-d-f'});

    final area = f['Мінне поле']!;
    expect(area.kind, FeatureKind.polygon);
    expect(area.vertices, hasLength(3), reason: 'closing point dropped');
    expect(area.color, 0xFFFF0000);

    final rect = f['Район зосередження']!;
    expect(rect.kind, FeatureKind.polygon);
    expect(rect.vertices, hasLength(4));
    expect(rect.color, 0xFF0000FF);

    final circle = f['Зона ураження']!;
    expect(circle.kind, FeatureKind.point);
    expect(circle.radius, 250);
    expect(circle.vertices.single.lat, 47.8);

    expect(r.warnings.map((w) => (w.code, w.detail)), [
      (ImportWarning.entryMissing, 'missing/missing.cot'),
      (ImportWarning.entrySkipped, 'overlays/notes.txt'),
    ]);
  });

  test('a package without a manifest is scanned', () async {
    final bytes = packageFixture(keep: (p) => !p.startsWith('MANIFEST'));
    final r = await importFile('Без маніфесту.zip', bytes, now: now);
    expect(r.layers.map((l) => l.layer.name), ['Рубежі', 'Без маніфесту']);
    // The ignored entry is read too now, and both text files are reported.
    expect(r.layers[1].features, hasLength(6));
    expect(r.warnings.map((w) => w.code).toSet(), {ImportWarning.entrySkipped});
    expect(r.warnings, hasLength(2));
  });

  test('export layout and manifest', () {
    final layers = sampleLayers();
    final files = unzip(exportLayers(layers, ExportFormat.atakPackage, now: now));
    const marker = '11111111-1111-4111-8111-111111111111';
    expect(files.keys.toSet(), {
      'MANIFEST/manifest.xml',
      '$marker/$marker.cot',
      '22222222-2222-4222-8222-222222222222/22222222-2222-4222-8222-222222222222.cot',
      '55555555-5555-4555-8555-555555555555/55555555-5555-4555-8555-555555555555.cot',
      '$layerA/Опорний пункт «Сокіл».kml',
    });
    final manifest = XmlDocument.parse(utf8.decode(files['MANIFEST/manifest.xml']!)).rootElement;
    expect(manifest.name.local, 'MissionPackageManifest');
    expect(manifest.getAttribute('version'), '2');
    final params = {
      for (final p in manifest.getElement('Configuration')!.findElements('Parameter'))
        p.getAttribute('name'): p.getAttribute('value'),
    };
    expect(params['name'], 'Опорний пункт «Сокіл» +1');
    expect(params['uid'], hasLength(36));
    final contents = manifest.getElement('Contents')!.findElements('Content').toList();
    expect(
      contents.map((c) => c.getAttribute('zipEntry')).toSet(),
      files.keys.toSet()..remove('MANIFEST/manifest.xml'),
    );
    expect(contents.every((c) => c.getAttribute('ignore') == 'false'), isTrue);
    final cot = contents.firstWhere((c) => c.getAttribute('zipEntry')!.startsWith(marker));
    expect(cot.getElement('Parameter')!.getAttribute('value'), marker);

    // Lines and polygons only in the KML.
    final kml = utf8.decode(files['$layerA/Опорний пункт «Сокіл».kml']!);
    expect('<Placemark>'.allMatches(kml), hasLength(2));
    // Same layers, same package uid: ATAK replaces instead of duplicating.
    final again = unzip(
      exportLayers(layers, ExportFormat.atakPackage, now: now.add(const Duration(days: 1))),
    );
    final uid2 = XmlDocument.parse(utf8.decode(again['MANIFEST/manifest.xml']!))
        .findAllElements('Parameter')
        .firstWhere((p) => p.getAttribute('name') == 'uid')
        .getAttribute('value');
    expect(uid2, params['uid']);
  });

  test('round trip regroups points with their layer', () async {
    final layers = sampleLayers();
    final r = await roundTrip(layers, ExportFormat.atakPackage);
    expect(r.warnings, isEmpty);
    expect(r.layers.map((l) => l.layer.name), [for (final l in layers) l.layer.name]);
    for (var i = 0; i < layers.length; i++) {
      expect(r.layers[i].layer.color, layers[i].layer.color);
      expectSameFeatures(r.layers[i].features, layers[i].features);
    }
    expect(suggestedFileName(layers, ExportFormat.atakPackage), 'Опорний пункт «Сокіл» +1.zip');
  });

  test('shapes from ATAK go back as ATAK shapes, not as KML', () async {
    final first = await importFile('pkg.zip', packageFixture(), now: now);
    final bytes = exportLayers(first.layers, ExportFormat.atakPackage, now: now);
    final files = unzip(bytes);
    for (final uid in ['line-1', 'area-1', 'rect-1', 'circle-1']) {
      expect(files.containsKey('$uid/$uid.cot'), isTrue, reason: uid);
    }
    final area = utf8.decode(files['area-1/area-1.cot']!);
    expect(area, contains('type="u-d-f"'));
    expect('<link point="47.94,37.44"/>'.allMatches(area), hasLength(2), reason: 'closed');
    expect(area, contains('<strokeColor value="-65536"/>'));
    final circle = utf8.decode(files['circle-1/circle-1.cot']!);
    expect(circle, contains('<ellipse major="250" minor="250" angle="360"/>'));
    // Only the KML-born line is in a KML file.
    final kmls = files.keys.where((k) => k.endsWith('.kml')).toList();
    expect(kmls, hasLength(1));
    expect(utf8.decode(files[kmls.single]!), contains('Рубіж 1'));

    final second = await importFile('again.zip', bytes, now: now);
    expect(second.warnings, isEmpty);
    for (var i = 0; i < first.layers.length; i++) {
      expect(second.layers[i].layer.name, first.layers[i].layer.name);
      expectSameFeatures(second.layers[i].features, first.layers[i].features);
    }
  });

  test('empty layers are a caveat', () {
    final layers = [...sampleLayers(), LayerBundle(layer(newUuid, 'Порожній'), const [])];
    expect(exportCaveats(layers, ExportFormat.atakPackage), {'atakPackage.emptyLayers'});
  });
}

const newUuid = '99999999-9999-4999-8999-999999999999';
