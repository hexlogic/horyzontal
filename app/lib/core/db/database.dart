import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';

part 'database.g.dart';

/// Application settings as key/value pairs.
class SettingsEntries extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// A named group of map objects; hidden layers stay in the journal but not
/// on the map, archived ones are tucked away from both.
@DataClassName('LayerRow')
class Layers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get color => integer().withDefault(const Constant(0xFF1565C0))();
  BoolColumn get visible => boolean().withDefault(const Constant(true))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Points, polylines and polygons. [geometry] is JSON `[[lat, lon, alt?], ...]`
/// in WGS 84; a point has one vertex.
@DataClassName('FeatureRow')
class Features extends Table {
  TextColumn get id => text()();
  TextColumn get layerId => text().references(Layers, #id, onDelete: KeyAction.cascade)();
  TextColumn get kind => text()();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();

  /// Callsign of whoever created the object.
  TextColumn get author => text().withDefault(const Constant(''))();

  /// APP-6 symbol code (number SIDC) of a point.
  TextColumn get sidc => text().nullable()();
  IntColumn get color => integer().nullable()();

  /// Radius shown around a point, metres.
  RealColumn get radius => real().nullable()();
  TextColumn get geometry => text()();

  /// JSON with fields kept from imports (CoT uid, KML style...).
  TextColumn get extra => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The app database, encrypted with SQLCipher (AES-256).
@DriftDatabase(tables: [SettingsEntries, Layers, Features])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(layers);
            await m.createTable(features);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Opens [file] with the 256-bit [key] given as 64 hex characters.
  static AppDatabase open(File file, String key) =>
      AppDatabase(NativeDatabase.createInBackground(file, setup: (db) => applyKey(db, key)));

  /// In-memory database for tests, still going through SQLCipher.
  static AppDatabase memory(String key) =>
      AppDatabase(NativeDatabase.memory(setup: (db) => applyKey(db, key)));

  /// Sets the raw SQLCipher key and checks that SQLCipher is actually linked:
  /// with plain SQLite `PRAGMA key` is silently ignored and data would be
  /// written in the clear.
  static void applyKey(Database db, String key) {
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(key)) {
      throw ArgumentError('Database key must be 64 lowercase hex characters');
    }
    final cipher = db.select('PRAGMA cipher_version');
    if (cipher.isEmpty) throw StateError('SQLite is built without SQLCipher');
    db.execute("PRAGMA key = \"x'$key'\"");
    // Fails with SQLITE_NOTADB if the key does not match the file.
    db.select('SELECT count(*) FROM sqlite_master');
  }

  Future<Map<String, String>> readSettings() async {
    final rows = await select(settingsEntries).get();
    return {for (final r in rows) r.key: r.value};
  }

  Future<void> writeSetting(String key, String? value) async {
    if (value == null) {
      await (delete(settingsEntries)..where((t) => t.key.equals(key))).go();
    } else {
      await into(settingsEntries)
          .insertOnConflictUpdate(SettingsEntriesCompanion.insert(key: key, value: value));
    }
  }
}
