import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal/core/data/ids.dart';
import 'package:horyzontal/core/data/model.dart';
import 'package:horyzontal/core/data/repository.dart';
import 'package:horyzontal/core/db/database.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';
import 'package:sqlite3/sqlite3.dart';

import 'helpers.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late Repository repo;
  var t = DateTime(2026, 10, 12, 12);

  setUp(() {
    db = AppDatabase.memory(testKey);
    repo = Repository(db, clock: () => t = t.add(const Duration(seconds: 1)));
  });
  tearDown(() => db.close());

  MapFeature point(String layerId, String name) => MapFeature(
        id: newId(),
        layerId: layerId,
        kind: FeatureKind.point,
        vertices: const [Geodetic(50.45, 30.52, 170)],
        name: name,
        sidc: '10031000001211000000',
        extra: const {'cotUid': 'abc'},
        createdAt: t,
        updatedAt: t,
      );

  test('ids are v4 UUIDs and unique', () {
    final ids = {for (var i = 0; i < 1000; i++) newId()};
    expect(ids, hasLength(1000));
    expect(ids.first, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
  });

  test('layers, features, visibility, archive, cascade delete', () async {
    final a = await repo.defaultLayer('Мої');
    expect((await repo.defaultLayer('other')).id, a.id);
    final b = await repo.createLayer('Розвідка');
    final p1 = point(a.id, 'КСП');
    final p2 = point(b.id, 'Міномет');
    await repo.saveFeature(p1);
    await repo.saveFeature(p2);

    final back = (await repo.feature(p1.id))!;
    expect(back.name, 'КСП');
    expect(back.position.h, 170);
    expect(back.sidc, p1.sidc);
    expect(back.extra['cotUid'], 'abc');

    // Touching a feature moves its layer to the top.
    expect((await repo.layers()).first.id, b.id);
    await repo.saveFeature(back.copyWith(name: 'КСП-2'));
    expect((await repo.layers()).first.id, a.id);

    await repo.setLayerVisible(b.id, false);
    expect((await repo.watchFeatures(visibleOnly: true).first).map((f) => f.name), ['КСП-2']);
    expect(await repo.watchFeatures().first, hasLength(2));

    await repo.setLayerArchived(b.id, true);
    expect(await repo.watchFeatures().first, hasLength(1));
    expect((await repo.watchLayers(archived: true).first).single.id, b.id);

    await repo.deleteLayer(a.id);
    expect(await repo.feature(p1.id), isNull);
  });

  test('upgrade from the stage 1 schema keeps settings', () async {
    final dir = await Directory.systemTemp.createTemp('hrz');
    final file = File('${dir.path}/app.db');
    final raw = sqlite3.open(file.path);
    AppDatabase.applyKey(raw, testKey);
    raw.execute('CREATE TABLE settings_entries (key TEXT NOT NULL PRIMARY KEY, value TEXT NOT NULL)');
    raw.execute("INSERT INTO settings_entries VALUES ('callsign', 'Сокіл')");
    raw.execute('PRAGMA user_version = 1');
    raw.close();

    final upgraded = AppDatabase.open(file, testKey);
    expect((await upgraded.readSettings())['callsign'], 'Сокіл');
    final r = Repository(upgraded);
    final l = await r.createLayer('x');
    await r.saveFeature(point(l.id, 'p'));
    expect(await r.watchFeatures().first, hasLength(1));
    await upgraded.close();
    await dir.delete(recursive: true);
  });
}
