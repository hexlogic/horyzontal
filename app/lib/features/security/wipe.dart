import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/db/database.dart';
import '../../core/secure_store.dart';

/// Emergency wipe: the database and its key, PIN, settings, map sources and
/// their files and downloaded areas (Documents/sources), map tile cache,
/// exports and received files; offline map packs only when [packs]. The app
/// quits afterwards and starts empty next time.
Future<void> emergencyWipe(AppDatabase db, {required bool packs}) async {
  // The key first: without it the database file is unreadable even if
  // deleting it below fails or the phone dies halfway.
  await const PlatformSecureStore()
      .deleteAll()
      .timeout(const Duration(seconds: 5))
      .catchError((Object e) => debugPrint('wipe: secure storage: $e'));
  // Open stream queries can keep drift from closing; don't wait for it.
  await db.close().timeout(const Duration(seconds: 2)).catchError((Object e) => debugPrint('wipe: db: $e'));
  final docs = await getApplicationDocumentsDirectory();
  final dirs = <Directory>[
    await getApplicationSupportDirectory(), // database, online style, MapLibre cache (iOS)
    await getTemporaryDirectory(), // exports
    Directory.systemTemp, // NSTemporaryDirectory on iOS: files shared to the app
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
