import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/db/database.dart';
import 'core/secure_store.dart';
import 'core/settings.dart';
import 'features/security/lock.dart';
import 'features/security/pin_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const store = PlatformSecureStore();
  final db = await openAppDatabase(store);
  final settings = AppSettings.fromMap(await db.readSettings());
  final pinEnabled = await PinStore(store).hasPin();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        initialSettingsProvider.overrideWithValue(settings),
        initialPinEnabledProvider.overrideWithValue(pinEnabled),
      ],
      child: const HoryzontalApp(),
    ),
  );
}

/// Opens the encrypted database in the app support directory (not visible
/// in Files / not backed up as a document). A database whose key is gone
/// (e.g. the Keychain was reset) cannot be read and is started afresh.
Future<AppDatabase> openAppDatabase(SecureStore store) async {
  final dir = await getApplicationSupportDirectory();
  await dir.create(recursive: true);
  final file = File(p.join(dir.path, 'horyzontal.db'));
  final key = await loadOrCreateDatabaseKey(store);
  if (key.created && await file.exists()) await file.delete();
  final db = AppDatabase.open(file, key.key);
  try {
    await db.readSettings();
    return db;
  } catch (_) {
    await db.close();
    await file.delete();
    return AppDatabase.open(file, key.key);
  }
}
