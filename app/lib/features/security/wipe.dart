import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/db/database.dart';
import '../../core/secure_store.dart';

/// Emergency wipe: the database and its key, PIN, settings, map tile cache,
/// exports and received files; offline map packs only when [packs]. The app
/// quits afterwards and starts empty next time.
Future<void> emergencyWipe(AppDatabase db, {required bool packs}) async {
  await db.close().catchError((_) {});
  await const PlatformSecureStore().deleteAll().catchError((_) {});
  final docs = await getApplicationDocumentsDirectory();
  final dirs = <Directory>[
    await getApplicationSupportDirectory(), // database, online style, MapLibre cache (iOS)
    await getTemporaryDirectory(), // exports, incoming files
    await getApplicationCacheDirectory(),
    if (Platform.isAndroid) Directory('${docs.parent.path}/files'), // MapLibre cache (Android)
  ];
  for (final d in dirs) {
    await _clear(d);
  }
  await for (final e in docs.list()) {
    if (!packs && e.path.endsWith('/packs')) continue;
    await e.delete(recursive: true).catchError((_) => e);
  }
  await SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');
  exit(0);
}

Future<void> _clear(Directory d) async {
  if (!await d.exists()) return;
  await for (final e in d.list()) {
    await e.delete(recursive: true).catchError((_) => e);
  }
}
