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

/// The app database, encrypted with SQLCipher (AES-256). Layers, objects and
/// the journal join it in stage 2.
@DriftDatabase(tables: [SettingsEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

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
