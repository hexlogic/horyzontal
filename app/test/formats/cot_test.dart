import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal/core/data/model.dart';
import 'package:horyzontal/features/exchange/formats/formats.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';
import 'package:xml/xml.dart';

import 'samples.dart';

void main() {
  group('SIDC ↔ CoT table', () {
    test('has the common entities and is one-to-one both ways', () {
      expect(cotTable.length, greaterThanOrEqualTo(80));
      expect(cotTable.map((e) => e.$1).toSet(), hasLength(cotTable.length));
      expect(cotTable.map((e) => e.$2).toSet(), hasLength(cotTable.length));
      for (final (path, code) in cotTable) {
        expect(code, matches(RegExp(r'^\d{12}$')));
        final sidc = cotTypeToSidc('a-f-$path')!;
        expect(sidc, hasLength(20));
        expect(sidc.substring(4, 6), code.substring(0, 2));
        expect(sidcToCotType(sidc), 'a-f-$path', reason: path);
      }
    });

    test('the QR example and common symbols', () {
      expect(sidcToCotType('10031000001211000000'), 'a-f-G-U-C-I');
      expect(cotTypeToSidc('a-f-G-U-C-I'), '10031000001211000000');
      const pairs = {
        'a-h-G-U-C-A': '10061000001205000000', // armour
        'a-h-G-U-C-I-Z': '10061000001211020000', // mechanised infantry
        'a-h-G-U-C-I-M': '10061000001211040000', // motorised infantry
        'a-f-G-U-C-F': '10031000001303000000', // field artillery
        'a-f-G-U-C-F-R-M': '10031000001303004100', // MLRS unit
        'a-f-G-U-C-F-M': '10031000001308000000', // mortar
        'a-f-G-U-C-D': '10031000001301000000', // air defence
        'a-f-G-U-C-R': '10031000001213000000', // recon
        'a-f-G-U-C-E': '10031000001407000000', // engineers
        'a-f-G-U-S-M': '10031000001613000000', // medical
        'a-f-G-U-S-S': '10031000001634000000', // supply
        'a-f-G-U-U-S': '10031000001110000000', // signal
        'a-f-G-U-C-V-U': '10031000001219000000', // UAS unit
        'a-h-G-E-V-A-T': '10061500001202000000', // tank
        'a-h-G-E-V-A-A': '10061500001201030000', // APC
        'a-h-G-E-V-A-I': '10061500001201010000', // IFV / AFV
        'a-h-G-E-W-H': '10061500001109000000', // howitzer
        'a-h-G-E-W-X': '10061500001116000000', // MLRS
        'a-h-A-M-F-Q': '10060100001103000000', // UAV
        'a-f-F': '10031000001218000000', // SOF
      };
      for (final MapEntry(:key, :value) in pairs.entries) {
        expect(cotTypeToSidc(key), value, reason: key);
        expect(sidcToCotType(value), key, reason: value);
      }
    });

    test('affiliations', () {
      const si = {'0': 'p', '1': 'u', '2': 'a', '3': 'f', '4': 'n', '5': 's', '6': 'h'};
      for (final MapEntry(:key, :value) in si.entries) {
        expect(sidcToCotType('100${key}1000001211000000'), 'a-$value-G-U-C-I');
        expect(cotTypeToSidc('a-$value-G-U-C-I')![3], key);
      }
      // Exercise context draws like reality in ATAK.
      expect(sidcToCotType('10131000001211000000'), 'a-f-G-U-C-I');
      expect(sidcToCotType('10161000001211000000'), 'a-h-G-U-C-I');
      // Joker and faker are exercise suspect and hostile.
      expect(cotTypeToSidc('a-j-G-U-C-I'), '10151000001211000000');
      expect(cotTypeToSidc('a-k-G-U-C-I'), '10161000001211000000');
      expect(cotTypeToSidc('a-o-G')![3], '1');
      expect(cotTypeToSidc('a-x-G')![3], '1');
    });

    test('fallbacks: entity type, dimension, HQ, junk', () {
      // Amphibious infantry (121101) is not in the table: infantry.
      expect(sidcToCotType('10061000001211010000'), 'a-h-G-U-C-I');
      // Infantry with a modifier not in the table: infantry.
      expect(sidcToCotType('10061000001211000500'), 'a-h-G-U-C-I');
      expect(sidcToCotType('10060100001109000000'), 'a-h-A-M', reason: 'air: military');
      expect(sidcToCotType('10062000001105000000'), 'a-h-G-I');
      expect(sidcToCotType('10063000001500000000'), 'a-h-S');
      expect(sidcToCotType('10063500001500000000'), 'a-h-U');
      expect(sidcToCotType('10060500001100000000'), 'a-h-P');
      expect(sidcToCotType('10061000001900000000'), 'a-h-G-U');
      expect(sidcToCotType('10061500009900000000'), 'a-h-G-E');
      expect(sidcToCotType('10062500001234560000'), 'a-h-G');
      expect(sidcToCotType('10031002000000000000'), 'a-f-G-U-H');
      expect(cotTypeToSidc('a-f-G-U-H'), '10031002000000000000');
      expect(sidcToCotType('SFGPUCI----D'), 'a-u-G');
      expect(sidcToCotType(null), 'a-u-G');

      expect(cotTypeToSidc('a-h-G-U-C-I-Q-Q-Q'), '10061000001211000000', reason: 'longest prefix');
      expect(cotTypeToSidc('a-h-G-Z'), '10061000000000000000');
      expect(cotTypeToSidc('a-h-G-E-Z'), '10061500000000000000');
      expect(cotTypeToSidc('a-h-A'), '10060100000000000000');
      expect(cotTypeToSidc('a-h-S-Q'), '10063000000000000000');
      expect(cotTypeToSidc('b-m-p-s-m'), isNull);
      expect(cotTypeToSidc('a-f'), isNull);
      expect(cotTypeToSidc(''), isNull);
    });
  });

  test('ATAK marker with BOM', () async {
    final r = await importFile('Ціль.cot', fixture('atak_marker.cot'), now: now);
    expect(r.warnings, isEmpty);
    expect(r.layers.single.layer.name, 'Ціль');
    final f = r.layers.single.features.single;
    expect(f.id, 'ec5b3bd1-0c27-4a5c-9b7c-2f8a0e0c5a11');
    expect(f.kind, FeatureKind.point);
    expect(f.name, 'Ворожа піхота');
    expect(f.author, 'VOVK');
    expect(f.description, 'До взводу, окопуються');
    expect(f.sidc, '10061000001211000000');
    expect(f.color, 0xFFFF0000);
    expectVertices(f.vertices, [const Geodetic(48.0234567, 37.8123456)]);
    expect(f.extra, {'cotUid': 'ec5b3bd1-0c27-4a5c-9b7c-2f8a0e0c5a11', 'cotType': 'a-h-G-U-C-I'});
    expect(f.createdAt, DateTime.utc(2026, 10, 11, 7, 21, 34, 512));
  });

  test('concatenated events, skipped kinds, deterministic ids', () async {
    final r = await importFile('feed.cot', fixture('concatenated.cot'), now: now);
    final f = r.layers.single.features;
    expect(f.map((x) => x.name), ['Т-64 №1', 'Цивільний літак', 'Мітка']);
    expect(f[0].sidc, '10031500001202000000');
    // hae in the file, above sea level in the app
    final v0 = f[0].vertices.single;
    expect(v0.h, closeTo(152.5 - Geoid.egm2008Ukraine.undulation(v0.lat, v0.lon)!, 1e-9));
    expect(f[1].sidc, '10040100001201000000');
    expect(f[2].sidc, isNull);
    expect(f[2].color, 0xFF00FF00);
    expect(f[2].vertices.single.h, 0);
    expect(r.warnings.map((w) => w.code), [
      ImportWarning.cotUnsupported,
      ImportWarning.badCoordinate,
    ]);

    final again = await importFile('feed.cot', fixture('concatenated.cot'), now: now);
    expect(again.layers.single.features.map((x) => x.id), f.map((x) => x.id));
    expect(f[0].id, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-')));
    expect(f[0].extra['cotUid'], 'S-1');
  });

  test('export: one ATAK-style event per point', () {
    final layers = sampleLayers();
    final xml = utf8.decode(exportLayers([layers.first], ExportFormat.cot, now: now));
    final events = XmlDocument.parse('<r>${xml.replaceAll(RegExp(r'<\?xml[^>]*\?>'), '')}</r>')
        .rootElement
        .childElements
        .toList();
    expect(events, hasLength(2), reason: 'points only');
    final e = events.first;
    expect(e.getAttribute('version'), '2.0');
    expect(e.getAttribute('uid'), '11111111-1111-4111-8111-111111111111');
    expect(e.getAttribute('type'), 'a-f-G-U-C-I');
    expect(e.getAttribute('how'), 'h-g-i-g-o');
    expect(e.getAttribute('time'), '2026-10-12T12:00:00.000Z');
    expect(e.getAttribute('stale'), '2027-10-12T12:00:00.000Z');
    final p = e.getElement('point')!;
    expect(p.getAttribute('lat'), '50.4501');
    final hae = double.parse(p.getAttribute('hae')!);
    final lat = double.parse(p.getAttribute('lat')!), lon = double.parse(p.getAttribute('lon')!);
    expect(hae, closeTo(170.5 + Geoid.egm2008Ukraine.undulation(lat, lon)!, 0.01));
    expect(p.getAttribute('ce'), '9999999.0');
    final d = e.getElement('detail')!;
    expect(d.getElement('contact')!.getAttribute('callsign'), 'КСП 1/72');
    expect(d.getElement('link')!.getAttribute('parent_callsign'), 'SOKIL');
    expect(d.getElement('remarks')!.innerText, startsWith('Командно-спостережний'));
    expect(d.getElement('color')!.getAttribute('argb'), '${0xFF2E7D32 - 0x100000000}');
    expect(d.getElement('precisionlocation')!.getAttribute('altsrc'), 'USER');
    expect(d.getElement('archive'), isNotNull);

    final tank = events[1];
    expect(tank.getAttribute('type'), 'a-h-G-E-V-A-T');
    expect(tank.getElement('point')!.getAttribute('hae'), '9999999.0');
    expect(
      tank.getElement('detail')!.getElement('precisionlocation')!.getAttribute('altsrc'),
      '???',
    );
  });

  test('round trip keeps exact SIDC, radius, times and layer', () async {
    final layers = sampleLayers();
    final r = await roundTrip(layers, ExportFormat.cot);
    expect(r.warnings, isEmpty);
    expect(r.layers.map((l) => l.layer.name), [for (final l in layers) l.layer.name]);
    expect(r.layers.first.layer.color, layers.first.layer.color);
    for (var i = 0; i < layers.length; i++) {
      expectSameFeatures(
        r.layers[i].features,
        layers[i].features.where((f) => f.kind == FeatureKind.point).toList(),
      );
    }
  });

  test('a marker from ATAK goes back with its uid and type', () async {
    final r = await importFile('m.cot', fixture('atak_marker.cot'), now: now);
    final out = utf8.decode(exportLayers(r.layers, ExportFormat.cot, now: now));
    expect(out, contains('uid="ec5b3bd1-0c27-4a5c-9b7c-2f8a0e0c5a11" type="a-h-G-U-C-I"'));
    // A more specific imported type of the same branch is kept.
    final f = r.layers.single.features.single.copyWith(
      extra: {'cotUid': 'X-1', 'cotType': 'a-h-G-U-C-I-Q'},
    );
    final out2 = utf8.decode(
      exportLayers(
        [
          LayerBundle(r.layers.single.layer, [f]),
        ],
        ExportFormat.cot,
        now: now,
      ),
    );
    expect(out2, contains('uid="X-1" type="a-h-G-U-C-I-Q"'));
  });

  test('a copy with our detail but a new uid is a new object', () async {
    final original = exportLayers([sampleLayers().last], ExportFormat.cot, now: now);
    final copy = utf8.encode(
      utf8
          .decode(original)
          .replaceFirst(
            'uid="55555555-5555-4555-8555-555555555555"',
            'uid="0f0f0f0f-0000-4000-8000-000000000001"',
          ),
    );
    final a = await importFile('a.cot', original), b = await importFile('b.cot', copy);
    expect(a.layers.single.features.single.id, '55555555-5555-4555-8555-555555555555');
    expect(b.layers.single.features.single.id, '0f0f0f0f-0000-4000-8000-000000000001');
  });

  test('a marker whose symbol was cleared becomes a spot marker', () async {
    final r = await importFile('m.cot', fixture('atak_marker.cot'), now: now);
    final f = r.layers.single.features.single.copyWith(sidc: () => null);
    final out = utf8.decode(
      exportLayers(
        [
          LayerBundle(r.layers.single.layer, [f]),
        ],
        ExportFormat.cot,
        now: now,
      ),
    );
    expect(out, contains('type="b-m-p-s-m"'));
  });

  test('suggested names and caveats', () {
    final layers = sampleLayers();
    expect(suggestedFileName([layers.last], ExportFormat.cot), 'Sydney.cot');
    expect(exportCaveats(layers, ExportFormat.cot), {'cot.pointsOnly', 'cot.severalEvents'});
    expect(exportCaveats([layers.last], ExportFormat.cot), isEmpty);
    expect(exportCaveats(layers, ExportFormat.hrz), isEmpty);
  });
}
