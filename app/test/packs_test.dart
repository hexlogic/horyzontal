import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal/core/net/network.dart';
import 'package:horyzontal/features/map/map_style.dart';
import 'package:horyzontal/features/map/packs.dart';

/// Lets tests talk to a local server.
class _LocalNet extends Net {
  _LocalNet() : super(offlineOnly: () => false);
  @override
  void check(Uri u) {}
}

void main() {
  test('offline style repeats sources and layers per pack, keeping draw order', () {
    final template = File('assets/map/style-offline.json').readAsStringSync();
    const packs = [
      PackFile('/p/kyiv.pmtiles', PackKind.basemap, 1, 0, 15),
      PackFile('/p/zhytomyr.pmtiles', PackKind.basemap, 1, 0, 15),
      PackFile('/p/kyiv-dem.pmtiles', PackKind.dem, 1, 0, 12),
    ];
    final style = jsonDecode(buildOfflineStyle(template, packs, '/assets')) as Map<String, Object?>;
    final sources = style['sources']! as Map<String, Object?>;
    expect(sources.keys, unorderedEquals(['protomaps_0', 'protomaps_1', 'dem_0']));
    expect((sources['protomaps_1']! as Map)['url'], 'pmtiles://file:///p/zhytomyr.pmtiles');
    final layers = (style['layers']! as List).cast<Map<String, Object?>>();
    final ids = layers.map((l) => l['id']).toList();
    expect(ids.toSet(), hasLength(ids.length));
    // water of both packs comes before any road of either pack
    final lastWater = ids.indexOf('water_1');
    expect(ids.indexOf('water_0'), lastWater - 1);
    final firstRoad = ids.indexOf('roads_tunnels_other_casing_0');
    expect(lastWater, lessThan(firstRoad));
    expect(style['glyphs'], 'file:///assets/fonts/{fontstack}/{range}.pbf');
  });

  test('elevation tint: one hidden layer per elevation pack, below the water', () {
    final template = File('assets/map/style-offline.json').readAsStringSync();
    const packs = [
      PackFile('/p/kyiv.pmtiles', PackKind.basemap, 1, 0, 15),
      PackFile('/p/kyiv-dem.pmtiles', PackKind.dem, 1, 0, 12),
      PackFile('/p/lviv-dem.pmtiles', PackKind.dem, 1, 0, 12),
    ];
    final style = jsonDecode(buildOfflineStyle(template, packs, '/assets')) as Map<String, Object?>;
    final layers = (style['layers']! as List).cast<Map<String, Object?>>();
    final ids = layers.map((l) => l['id']).toList();
    final tint = layers.where((l) => l['type'] == 'color-relief').toList();
    expect(tint.map((l) => l['source']), ['dem_0', 'dem_1']);
    expect(tint.map((l) => (l['layout']! as Map)['visibility']), everyElement('none'));
    expect(ids.indexOf('hillshade_1'), lessThan(ids.indexOf('color_relief_0')));
    expect(ids.indexOf('color_relief_1'), lessThan(ids.indexOf('water_0')));

    final shown = jsonDecode(buildOfflineStyle(template, packs, '/assets', relief: true)) as Map;
    expect(
      (shown['layers'] as List).where((l) => l['type'] == 'color-relief').map((l) => l['layout']['visibility']),
      everyElement('visible'),
    );
  });

  test('elevation tint over the online style uses the local packs only', () {
    final online = jsonEncode({
      'sources': {'openmaptiles': {'type': 'vector', 'url': 'https://tiles.openfreemap.org/planet'}},
      'layers': [
        {'id': 'background', 'type': 'background'},
        {'id': 'park', 'type': 'fill', 'source': 'openmaptiles'},
        {'id': 'waterway_river', 'type': 'line', 'source': 'openmaptiles'},
        {'id': 'label', 'type': 'symbol', 'source': 'openmaptiles'},
      ],
    });
    expect(withElevationTint(online, const [PackFile('/p/k.pmtiles', PackKind.basemap, 1, 0, 15)], visible: true), online);
    final style = jsonDecode(withElevationTint(
      online,
      const [PackFile('/p/kyiv-dem.pmtiles', PackKind.dem, 1, 0, 12)],
      visible: true,
    )) as Map;
    expect((style['sources'] as Map)['hrz-dem-0']['url'], 'pmtiles://file:///p/kyiv-dem.pmtiles');
    expect((style['layers'] as List).map((l) => l['id']), ['background', 'park', 'color_relief_0', 'waterway_river', 'label']);
  });

  test('online labels prefer Ukrainian names', () {
    final patched = jsonDecode(ukrainianLabels(jsonEncode({
      'layers': [
        {'id': 'place', 'layout': {'text-field': '{name:latin}'}},
        {'id': 'road_shield', 'layout': {'text-field': '{ref}'}},
      ],
    }))) as Map<String, Object?>;
    final layers = (patched['layers']! as List).cast<Map<String, Object?>>();
    expect((layers[0]['layout']! as Map)['text-field'], ['coalesce', ['get', 'name:uk'], ['get', 'name']]);
    expect((layers[1]['layout']! as Map)['text-field'], '{ref}');
  });

  test('online style keeps only allowed hosts', () {
    final style = jsonDecode(ukrainianLabels(jsonEncode({
      'glyphs': 'https://tiles.openfreemap.org/fonts/{fontstack}/{range}.pbf',
      'sprite': 'https://evil.example/sprite',
      'sources': {
        'openmaptiles': {'type': 'vector', 'url': 'https://tiles.openfreemap.org/planet'},
        'ads': {'type': 'raster', 'tiles': ['https://tracker.example/{z}/{x}/{y}.png']},
      },
      'layers': [
        {'id': 'water', 'source': 'openmaptiles'},
        {'id': 'ads', 'source': 'ads'},
        {'id': 'bg', 'type': 'background'},
      ],
    }))) as Map<String, Object?>;
    expect((style['sources']! as Map).keys, ['openmaptiles']);
    expect((style['layers']! as List).map((l) => (l as Map)['id']), ['water', 'bg']);
    expect(style['glyphs'], isNotNull);
    expect(style.containsKey('sprite'), isFalse);
  });

  test('manifest', () {
    final r = parseManifest(jsonEncode({
      'version': 1,
      'build': '20261012',
      'regions': [
        {
          'id': 'kyiv',
          'files': [
            {'kind': 'basemap', 'name': 'kyiv.pmtiles', 'bytes': 10, 'sha256': 'a'},
            {'kind': 'dem', 'name': 'kyiv-dem.pmtiles', 'bytes': 5, 'sha256': 'b'},
          ],
        },
      ],
    }));
    expect(r.single.bytes, 15);
    expect(() => parseManifest('{"version":2}'), throwsFormatException);
  });

  test('download resumes with Range and checks SHA-256', () async {
    final data = Uint8List.fromList(List.generate(300000, (i) => i % 256));
    final digest = sha256.convert(data).toString();
    var failFirst = true;
    final ranges = <String?>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      final range = req.headers.value('range');
      ranges.add(range);
      final from = range == null ? 0 : int.parse(range.split('=')[1].split('-')[0]);
      req.response.statusCode = from > 0 ? 206 : 200;
      // First response breaks off halfway, like a lost connection.
      final end = failFirst ? 150000 : data.length;
      failFirst = false;
      req.response.add(data.sublist(from, end));
      await req.response.close();
    });
    final dir = await Directory.systemTemp.createTemp('packs');
    final base = Uri.parse('http://127.0.0.1:${server.port}/');
    final f = RemoteFile(PackKind.basemap, 'kyiv.pmtiles', data.length, digest);

    // The connection breaks halfway: the part stays for resuming.
    await expectLater(downloadFile(_LocalNet(), f, dir, base: base).drain<void>(), throwsA(isA<HttpException>()));
    expect(File('${dir.path}/kyiv.pmtiles.part').lengthSync(), 150000);

    await downloadFile(_LocalNet(), f, dir, base: base).drain<void>();
    expect(ranges.last, 'bytes=150000-');
    expect(await File('${dir.path}/kyiv.pmtiles').readAsBytes(), data);
    expect(File('${dir.path}/kyiv.pmtiles.part').existsSync(), isFalse);

    // A corrupted part fails the checksum and is thrown away.
    await File('${dir.path}/kyiv.pmtiles.part').writeAsBytes(Uint8List(data.length));
    await expectLater(downloadFile(_LocalNet(), f, dir, base: base).drain<void>(), throwsA(isA<ChecksumMismatch>()));
    expect(File('${dir.path}/kyiv.pmtiles.part').existsSync(), isFalse);
    await server.close(force: true);
    await dir.delete(recursive: true);
  });

  test('network policy', () {
    final net = Net(offlineOnly: () => false);
    expect(() => net.check(Uri.parse('https://tiles.openfreemap.org/styles/liberty')), returnsNormally);
    expect(() => net.check(Uri.parse('https://evil.example/x')), throwsA(isA<NetworkBlocked>()));
    expect(() => net.check(Uri.parse('http://github.com/x')), throwsA(isA<NetworkBlocked>()));
    final offline = Net(offlineOnly: () => true);
    expect(() => offline.check(Uri.parse('https://github.com/x')), throwsA(isA<NetworkBlocked>()));
  });
}
