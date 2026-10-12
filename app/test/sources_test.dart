import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal/core/db/database.dart';
import 'package:horyzontal/core/net/network.dart';
import 'package:horyzontal/features/map/packs.dart';
import 'package:horyzontal/features/sources/area_download.dart';
import 'package:horyzontal/features/sources/map_source.dart';
import 'package:horyzontal/features/sources/source_store.dart';
import 'package:horyzontal/features/sources/source_style.dart';
import 'package:horyzontal/features/sources/sources_repository.dart';
import 'package:sqlite3/sqlite3.dart';

import 'helpers.dart';

MapSource src({
  String id = 's1',
  MapSourceKind kind = MapSourceKind.url,
  String? url = 'https://tiles.example.org/{z}/{x}/{y}.png',
  bool tms = false,
  List<String> subdomains = const [],
  String? file,
  double opacity = 1,
  bool enabled = true,
}) => MapSource(
  id: id,
  name: id,
  kind: kind,
  url: url,
  tms: tms,
  subdomains: subdomains,
  file: file,
  opacity: opacity,
  enabled: enabled,
  createdAt: DateTime.utc(2026),
);

/// A 1×1 PNG.
final png = Uint8List.fromList([
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0, 0, 0, 0x0d, 0x49, 0x48, 0x44, 0x52, 0, 0, 0, 1, 0, 0, 0, 1, //
  8, 6, 0, 0, 0, 0x1f, 0x15, 0xc4, 0x89, 0, 0, 0, 0x0a, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9c, 0x63, 0, 1, 0, 0, 5, //
  0, 1, 0x0d, 0x0a, 0x2d, 0xb4, 0, 0, 0, 0, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
]);

/// Lets tests talk to a local server; offline-only still blocks.
class _LocalNet extends Net {
  _LocalNet({bool offline = false}) : super(offlineOnly: () => offline);
  @override
  void check(Uri u) {
    if (offlineOnly()) throw const NetworkBlocked('offline-only');
  }
}

void main() {
  group('URL templates', () {
    test('accepted forms', () {
      final xyz = parseTemplate('https://tiles.example.org/{z}/{x}/{y}.png');
      expect(xyz.error, isNull);
      expect(xyz.template!.host, 'tiles.example.org');
      expect(xyz.template!.tms, isFalse);

      final tms = parseTemplate('https://tiles.example.org/{z}/{x}/{-y}.jpg');
      expect(tms.template!.tms, isTrue);
      expect(tms.template!.url, 'https://tiles.example.org/{z}/{x}/{y}.jpg');

      final sub = parseTemplate('https://{s}.tiles.example.org/{z}/{x}/{y}.png', subdomains: ['a', 'b']);
      expect(sub.template!.host, 'a.tiles.example.org');

      final wms = parseTemplate('https://wms.example.org/wms?bbox={bbox-epsg-3857}&format=image/png');
      expect(wms.error, isNull);
    });

    test('refused forms', () {
      expect(parseTemplate('').error, TemplateError.empty);
      expect(parseTemplate('http://tiles.example.org/{z}/{x}/{y}.png').error, TemplateError.notHttps);
      expect(parseTemplate('https://tiles.example.org/tile.png').error, TemplateError.noTileCoordinates);
      expect(parseTemplate('https://tiles.example.org/{q}.png').error, TemplateError.quadkey);
      expect(parseTemplate('https://{s}.tiles.example.org/{z}/{x}/{y}.png').error, TemplateError.subdomainsMissing);
    });

    test('tile URLs: rows, subdomains, WMS box', () {
      expect(tileUrl(src(), 10, 598, 345), 'https://tiles.example.org/10/598/345.png');
      expect(tileUrl(src(tms: true), 10, 598, 345), 'https://tiles.example.org/10/598/678.png');
      final s = src(url: 'https://{s}.t.example.org/{z}/{x}/{y}.png', subdomains: ['a', 'b', 'c']);
      expect(tileUrls(s), ['https://a.t.example.org/{z}/{x}/{y}.png', 'https://b.t.example.org/{z}/{x}/{y}.png',
          'https://c.t.example.org/{z}/{x}/{y}.png']);
      expect(sourceHosts(s), {'a.t.example.org', 'b.t.example.org', 'c.t.example.org'});
      final wms = src(url: 'https://w.example.org/wms?bbox={bbox-epsg-3857}');
      expect(tileUrl(wms, 0, 0, 0),
          'https://w.example.org/wms?bbox=-20037508.342789,-20037508.342789,20037508.342789,20037508.342789');
    });

    test('tiles over an area', () {
      expect(tileOf(50.45, 30.52, 10), (598, 345));
      const b = (south: 50.40, west: 30.40, north: 50.50, east: 30.60);
      expect(tileCount(b, 10, 10), tilesIn(b, 10, 10).length);
      expect(tileCount(b, 0, 0), 1);
    });
  });

  group('map style', () {
    Map<String, Object?> base() => {
      'version': 8,
      'sources': <String, Object?>{},
      'layers': <Object?>[{'id': 'bg', 'type': 'background'}],
    };

    test('online, downloaded and file sources in order, the downloaded copy under the online one', () {
      final style = base();
      addUserSources(
        style,
        [
          src(id: 'a', opacity: 0.5),
          src(id: 'off', enabled: false),
          src(id: 'f', kind: MapSourceKind.file, url: null, file: 'f.mbtiles'),
        ],
        network: true,
        dir: '/d',
        downloaded: {'a.mbtiles'},
      );
      expect((style['layers']! as List).map((l) => (l as Map)['id']), ['bg', 'usersrc-a-dl', 'usersrc-a', 'usersrc-f']);
      final sources = style['sources']! as Map;
      expect((sources['usersrc-a-dl'] as Map)['url'], 'mbtiles:///d/a.mbtiles');
      expect((sources['usersrc-a'] as Map)['tiles'], ['https://tiles.example.org/{z}/{x}/{y}.png']);
      expect((sources['usersrc-f'] as Map)['url'], 'mbtiles:///d/f.mbtiles');
      expect(((style['layers']! as List)[2] as Map)['paint'], containsPair('raster-opacity', 0.5));
    });

    test('without the network only local tiles', () {
      final style = base();
      addUserSources(style, [src(id: 'a'), src(id: 'b')], network: false, dir: '/d', downloaded: {'b.mbtiles'});
      expect((style['layers']! as List).map((l) => (l as Map)['id']), ['bg', 'usersrc-b-dl']);
    });

    test('opacity does not rebuild the map, the URL does', () {
      final k = userSourcesKey([src()], const {}, network: true);
      expect(userSourcesKey([src(opacity: 0.3)], const {}, network: true), k);
      expect(userSourcesKey([src(url: 'https://x.example.org/{z}/{x}/{y}.png')], const {}, network: true), isNot(k));
      expect(userSourcesKey([src()], const {}, network: false), isNot(k));
    });
  });

  group('files', () {
    late Directory dir;
    setUp(() async => dir = await Directory.systemTemp.createTemp('hrz-src'));
    tearDown(() => dir.delete(recursive: true));

    test('MBTiles writer: TMS rows, zooms and bounds that MapLibre reads', () async {
      final path = '${dir.path}/a.mbtiles';
      final w = MbTilesWriter.open(path, name: 'A', attribution: '© A');
      final (x10, y10) = tileOf(50.45, 30.52, 10);
      final (x11, y11) = tileOf(50.45, 30.52, 11);
      w.put(10, x10, y10, png);
      w.put(11, x11, y11, png);
      w.finish(format: imageFormat(png));
      w.close();
      final db = sqlite3.open(path);
      final meta = {for (final r in db.select('SELECT * FROM metadata')) r['name']: r['value']};
      expect(meta['format'], 'png');
      expect(meta['minzoom'], '10');
      expect(meta['maxzoom'], '11');
      final bounds = (meta['bounds'] as String).split(',').map(double.parse).toList();
      expect(bounds[0], lessThan(30.52));
      expect(bounds[2], greaterThan(30.52));
      expect(bounds[1], lessThan(50.45));
      expect(bounds[3], greaterThan(50.45));
      expect(db.select('SELECT tile_row FROM tiles WHERE zoom_level = 10').single['tile_row'], 1023 - 345);
      db.close();
      final info = await SourceStore.inspect(path);
      expect((info.format, info.minZoom, info.maxZoom, info.name), ('png', 10, 11, 'A'));
    });

    test('vector and elevation files are refused', () async {
      Future<ImportProblem?> problem(Map<String, String> meta) async {
        final path = '${dir.path}/${meta.hashCode}.mbtiles';
        final db = sqlite3.open(path);
        db.execute('CREATE TABLE metadata (name TEXT, value TEXT); CREATE TABLE tiles (zoom_level, tile_column, tile_row, tile_data)');
        meta.forEach((k, v) => db.execute('INSERT INTO metadata VALUES (?, ?)', [k, v]));
        db.execute('INSERT INTO tiles VALUES (5, 1, 1, x\'00\')');
        db.close();
        try {
          await SourceStore.inspect(path);
          return null;
        } on SourceImportException catch (e) {
          return e.problem;
        }
      }

      expect(await problem({'format': 'pbf'}), ImportProblem.vector);
      expect(await problem({'format': 'webp', 'encoding': 'mapbox'}), ImportProblem.elevation);
      expect(await problem({'format': 'jpg'}), isNull);
      final junk = File('${dir.path}/junk.mbtiles')..writeAsStringSync('nope');
      expect(() => SourceStore.inspect(junk.path), throwsA(isA<SourceImportException>()));
    });

    test('a raster PMTiles is a map source, never a pack of heights', () async {
      final info = await SourceStore.inspect('test/fixtures/raster.pmtiles');
      expect((info.format, info.minZoom, info.maxZoom), ('png', 8, 13));
      expect(await PackStore.inspect('test/fixtures/raster.pmtiles'), isNull);
    });

    test('area download writes what the server has and stops in offline-only mode', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final seen = <String>[];
      server.listen((req) async {
        seen.add(req.uri.path);
        // One tile missing on the server.
        final (x, y) = tileOf(50.45, 30.52, 11);
        if (req.uri.path == '/11/$x/$y.png') {
          req.response.statusCode = 404;
        } else {
          req.response.add(png);
        }
        await req.response.close();
      });
      final s = src(url: 'http://127.0.0.1:${server.port}/{z}/{x}/{y}.png');
      const b = (south: 50.449, west: 30.519, north: 50.451, east: 30.521);
      final path = '${dir.path}/s1.mbtiles';
      final job = AreaDownload(net: _LocalNet(), source: s, bounds: b, minZoom: 10, maxZoom: 11, path: path);
      expect(job.total, 2);
      final last = await job.run().last;
      expect((last.done, last.failed), (2, 0));
      final db = sqlite3.open(path);
      expect(db.select('SELECT count(*) AS n FROM tiles').single['n'], 1);
      db.close();

      final blocked = AreaDownload(net: _LocalNet(offline: true), source: s, bounds: b, minZoom: 10, maxZoom: 11, path: path);
      await expectLater(blocked.run().drain<void>(), throwsA(isA<NetworkBlocked>()));
      expect(seen, hasLength(2));
      await server.close(force: true);
    });

    test('too big an area is refused before any request', () async {
      final job = AreaDownload(
        net: _LocalNet(),
        source: src(),
        bounds: (south: 44, west: 22, north: 52.5, east: 40.3),
        minZoom: 0,
        maxZoom: 14,
        path: '${dir.path}/big.mbtiles',
      );
      expect(job.total, greaterThan(maxDownloadTiles));
      await expectLater(job.run().drain<void>(), throwsA(isA<StateError>()));
    });
  });

  test('sources survive in the encrypted database', () async {
    final db = AppDatabase.memory(testKey);
    final repo = SourcesRepository(db);
    final s = repo.create(
      name: 'Topo',
      kind: MapSourceKind.url,
      url: 'https://{s}.t.example.org/{z}/{x}/{y}.png',
      subdomains: ['a', 'b'],
      tms: true,
      maxZoom: 17,
    );
    await repo.save(s);
    await repo.setOpacity(s.id, 0.4);
    final back = (await repo.all()).single;
    expect((back.name, back.tms, back.maxZoom, back.opacity), ('Topo', true, 17, 0.4));
    expect(back.subdomains, ['a', 'b']);
    await repo.delete(s.id);
    expect(await repo.all(), isEmpty);
    await db.close();
  });

  test('a version 2 database gains the sources table', () async {
    final dir = await Directory.systemTemp.createTemp('hrz-db');
    final file = File('${dir.path}/app.db');
    var db = AppDatabase.open(file, testKey);
    await db.writeSetting('callsign', 'A');
    await db.customStatement('DROP TABLE tile_sources');
    await db.customStatement('PRAGMA user_version = 2');
    await db.close();
    db = AppDatabase.open(file, testKey);
    expect((await db.readSettings())['callsign'], 'A');
    expect(await SourcesRepository(db).all(), isEmpty);
    await db.close();
    await dir.delete(recursive: true);
  });
}
