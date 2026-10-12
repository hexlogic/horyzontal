import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pmtiles/pmtiles.dart';

/// A PMTiles file found in the packs folder.
class PackFile {
  PackFile(this.path, this.isVector, this.bytes, this.minZoom, this.maxZoom);

  final String path;
  final bool isVector;
  final int bytes;
  final int minZoom;
  final int maxZoom;

  String get name => path.split('/').last;
  String get sizeLabel => '${(bytes / 1e6).toStringAsFixed(1)} МБ';
}

/// Offline packs live in Documents/packs (visible in the iOS Files app);
/// fonts and sprites are unpacked from assets into Application Support.
class MapPacks {
  static const _assetsPrefix = 'assets/map/';
  static const _assetsVersion = '1';

  static Future<Directory> packsDir() async {
    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/packs');
    await dir.create(recursive: true);
    return dir;
  }

  /// Packs in Documents/packs plus Documents itself, where Finder file
  /// sharing on iOS drops files, plus Android's app-specific external folder
  /// (`Android/data/<id>/files`), which adb and USB file transfer can write to.
  static Future<List<PackFile>> list() async {
    final dir = await packsDir();
    final out = <PackFile>[];
    final external = Platform.isAndroid ? await getExternalStorageDirectory() : null;
    final files = [
      ...await dir.list().toList(),
      ...await dir.parent.list().toList(),
      if (external != null && await external.exists()) ...await external.list().toList(),
    ];
    for (final f in files) {
      if (f is! File || !f.path.endsWith('.pmtiles')) continue;
      try {
        final a = await PmTilesArchive.from(f.path);
        out.add(PackFile(
          f.path,
          a.tileType == TileType.mvt,
          await f.length(),
          a.header.minZoom,
          a.header.maxZoom,
        ));
        await a.close();
      } catch (_) {
        // Not a PMTiles archive or a partial copy; skip.
      }
    }
    out.sort((a, b) => a.name.compareTo(b.name));
    return out;
  }

  static Future<PackFile?> import(String sourcePath) async {
    final dir = await packsDir();
    final dest = '${dir.path}/${sourcePath.split('/').last}';
    await File(sourcePath).copy(dest);
    final packs = await list();
    return packs.where((p) => p.path == dest).firstOrNull;
  }

  /// Copies glyphs and sprites out of the bundle once; MapLibre reads them
  /// through file:// URLs, which works the same on iOS and Android.
  static Future<String> installAssets() async {
    final support = await getApplicationSupportDirectory();
    final root = Directory('${support.path}/map-assets');
    final marker = File('${root.path}/.version');
    if (await marker.exists() && await marker.readAsString() == _assetsVersion) {
      return root.path;
    }
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    for (final key in manifest.listAssets()) {
      if (!key.startsWith(_assetsPrefix) || key.endsWith('.json') && key.contains('style-')) {
        continue;
      }
      final rel = Uri.decodeFull(key.substring(_assetsPrefix.length));
      final file = File('${root.path}/$rel');
      await file.parent.create(recursive: true);
      final data = await rootBundle.load(key);
      await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    }
    await marker.writeAsString(_assetsVersion);
    return root.path;
  }

  /// Style JSON for a basemap pack with an optional DEM pack for hillshade.
  static Future<String> offlineStyle(PackFile basemap, PackFile? dem) async {
    final assets = await installAssets();
    final raw = await rootBundle.loadString('${_assetsPrefix}style-offline.json');
    final filled = raw
        .replaceAll('{BASEMAP_URL}', 'pmtiles://file://${basemap.path}')
        .replaceAll('{DEM_URL}', dem == null ? '' : 'pmtiles://file://${dem.path}')
        .replaceAll('{ASSETS_URL}', 'file://$assets');
    if (dem != null) return filled;
    final style = jsonDecode(filled) as Map<String, dynamic>;
    (style['sources'] as Map).remove('dem');
    (style['layers'] as List).removeWhere((l) => l['source'] == 'dem');
    return jsonEncode(style);
  }
}
