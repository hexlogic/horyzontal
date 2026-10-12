import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal/features/exchange/formats/common.dart' show safeFileName, fileBaseName;
import 'package:horyzontal/features/exchange/formats/formats.dart';

import 'samples.dart';

Matcher throwsCode(String code) =>
    throwsA(isA<ImportException>().having((e) => e.code, 'code', code));

void main() {
  group('detection', () {
    test('content wins over the extension', () async {
      final kml = exportLayers(sampleLayers(), ExportFormat.kml, now: now);
      final r = await importFile('misnamed.gpx', kml);
      expect(r.layers, hasLength(2));
      final gpx = fixture('osmand.gpx');
      expect((await importFile('download.txt', gpx)).layers.single.features, hasLength(5));
      final hrz = exportLayers(sampleLayers(), ExportFormat.hrz, now: now);
      expect((await importFile('noext', hrz)).layers.first.layer.id, layerA);
      final kmz = exportLayers(sampleLayers(), ExportFormat.kmz, now: now);
      expect((await importFile('file.zip', kmz)).layers, hasLength(2));
      final pkg = exportLayers(sampleLayers(), ExportFormat.atakPackage, now: now);
      expect((await importFile('file.kmz', pkg)).featureCount, 5);
    });

    test('UTF-16 with BOM', () async {
      const gpx =
          '<?xml version="1.0" encoding="UTF-16"?><gpx version="1.1"><wpt lat="1" lon="2"><name>Точка</name></wpt></gpx>';
      final le = <int>[0xFF, 0xFE];
      for (final u in gpx.codeUnits) {
        le.addAll([u & 0xFF, u >> 8]);
      }
      final r = await importFile('u.gpx', Uint8List.fromList(le));
      expect(r.layers.single.features.single.name, 'Точка');
    });

    test('unknown and empty files', () async {
      await expectLater(
        importFile('a.bin', Uint8List(0)),
        throwsCode(ImportException.unknownFormat),
      );
      await expectLater(
        importFile('a.txt', utf8.encode('hello world')),
        throwsCode(ImportException.unknownFormat),
      );
      await expectLater(
        importFile('a.xml', utf8.encode('<html><body/></html>')),
        throwsCode(ImportException.unknownFormat),
      );
      // XML of another kind named .kml: the KML reader says it is broken.
      await expectLater(
        importFile('a.kml', utf8.encode('<html><body/></html>')),
        throwsCode(ImportException.malformed),
      );
      final zip = ZipEncoder().encodeBytes(Archive()..add(ArchiveFile.bytes('a.txt', [1])));
      await expectLater(importFile('a.zip', zip), throwsCode(ImportException.unknownFormat));
    });
  });

  group('malformed input', () {
    test('broken XML and JSON', () async {
      await expectLater(
        importFile('a.kml', utf8.encode('<kml><Document><Placemark><name>x</name>')),
        throwsCode(ImportException.malformed),
      );
      await expectLater(
        importFile('a.gpx', utf8.encode('<gpx><wpt lat="1" lon="2"></gpx>')),
        throwsCode(ImportException.malformed),
      );
      await expectLater(
        importFile('a.cot', utf8.encode('<event uid="x" type="a-f-G"><point lat="1"')),
        throwsCode(ImportException.malformed),
      );
      await expectLater(
        importFile(
          'a.hrz',
          utf8.encode('{"format": "horyzontal", "version": "one", "layers": []}'),
        ),
        throwsCode(ImportException.malformed),
      );
      final pk = Uint8List.fromList([0x50, 0x4B, 0x03, 0x04, ...List.filled(40, 7)]);
      await expectLater(importFile('a.zip', pk), throwsCode(ImportException.malformed));
    });

    test('entity declarations are refused, external or not', () async {
      const xxe =
          '<?xml version="1.0"?><!DOCTYPE kml [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>'
          '<kml><Placemark><name>&xxe;</name><Point><coordinates>1,2</coordinates></Point></Placemark></kml>';
      await expectLater(
        importFile('a.kml', utf8.encode(xxe)),
        throwsCode(ImportException.xmlEntities),
      );
      const laughs =
          '<?xml version="1.0"?><!DOCTYPE gpx [<!ENTITY a "aaaaaaaaaa"><!ENTITY b "&a;&a;&a;&a;">]>'
          '<gpx><wpt lat="1" lon="2"><name>&b;</name></wpt></gpx>';
      await expectLater(
        importFile('a.gpx', utf8.encode(laughs)),
        throwsCode(ImportException.xmlEntities),
      );
      const cot =
          '<?xml version="1.0"?><!DOCTYPE event [<!ENTITY x "y">]>'
          '<event uid="a" type="a-f-G"><point lat="1" lon="2"/><detail><contact callsign="&x;"/></detail></event>';
      await expectLater(
        importFile('a.cot', utf8.encode(cot)),
        throwsCode(ImportException.xmlEntities),
      );
    });

    test('coordinates out of range are skipped with a warning', () async {
      const kml =
          '<kml><Document><Placemark><name>ok</name><Point><coordinates>30,50</coordinates></Point></Placemark>'
          '<Placemark><name>lon</name><Point><coordinates>181,50</coordinates></Point></Placemark>'
          '<Placemark><name>nan</name><Point><coordinates>NaN,50</coordinates></Point></Placemark>'
          '<Placemark><name>text</name><LineString><coordinates>30,50 x,y</coordinates></LineString></Placemark>'
          '</Document></kml>';
      final r = await importFile('a.kml', utf8.encode(kml));
      expect(r.layers.single.features.map((f) => f.name), ['ok']);
      expect(r.warnings.map((w) => w.code), List.filled(3, ImportWarning.badCoordinate));
    });
  });

  group('size limits', () {
    test('more than 50 MB is refused before parsing', () async {
      final big = Uint8List(importSizeLimit + 1);
      await expectLater(importFile('a.kml', big), throwsCode(ImportException.tooLarge));
    });

    test('zip bomb: declared content over the limit', () async {
      final archive = Archive()
        ..add(ArchiveFile.bytes('doc.kml', Uint8List(importSizeLimit + 1024)));
      final bomb = ZipEncoder().encodeBytes(archive);
      expect(bomb.length, lessThan(512 * 1024), reason: 'compresses to almost nothing');
      await expectLater(importFile('a.kmz', bomb), throwsCode(ImportException.tooLarge));
    });

    test('nested archives share the budget', () async {
      final inner = ZipEncoder().encodeBytes(
        Archive()..add(ArchiveFile.bytes('doc.kml', Uint8List(30 * 1024 * 1024))),
      );
      final outer = ZipEncoder().encodeBytes(
        Archive()
          ..add(ArchiveFile.bytes('a.cot', utf8.encode('<event/>')))
          ..add(ArchiveFile.bytes('big.kml', Uint8List(25 * 1024 * 1024)))
          ..add(ArchiveFile.bytes('nested.kmz', inner)),
      );
      await expectLater(importFile('a.zip', outer), throwsCode(ImportException.tooLarge));
    });

    test('too many entries', () async {
      final archive = Archive();
      for (var i = 0; i <= archiveEntryLimit; i++) {
        archive.add(ArchiveFile.bytes('$i.cot', const [0x20]));
      }
      await expectLater(
        importFile('a.zip', ZipEncoder().encodeBytes(archive)),
        throwsCode(ImportException.tooLarge),
      );
    });
  });

  group('file names', () {
    test('safe names keep Cyrillic', () {
      expect(safeFileName('Опорний пункт «Сокіл»'), 'Опорний пункт «Сокіл»');
      expect(safeFileName('a/b\\c:d*e?f"g<h>i|j'), 'a_b_c_d_e_f_g_h_i_j');
      expect(safeFileName('  ..hidden.  '), 'hidden');
      expect(safeFileName('line\nbreak\ttab'), 'line break tab');
      expect(safeFileName(''), 'horyzontal');
      expect(safeFileName('CON'), 'horyzontal');
      expect(safeFileName('Ж' * 200).runes.length, 80);
    });

    test('suggested names by format', () {
      final layers = sampleLayers();
      expect(
        [
          for (final f in ExportFormat.values) suggestedFileName([layers.first], f),
        ],
        [
          'Опорний пункт «Сокіл».hrz',
          'Опорний пункт «Сокіл».kml',
          'Опорний пункт «Сокіл».kmz',
          'Опорний пункт «Сокіл».gpx',
          'Опорний пункт «Сокіл».cot',
          'Опорний пункт «Сокіл».zip',
        ],
      );
      expect(suggestedFileName(const [], ExportFormat.kml), 'Horyzontal.kml');
      expect(fileBaseName('dir/Шар 1.kml.hrze'), 'Шар 1');
    });
  });
}
