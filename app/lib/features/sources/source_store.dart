import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pmtiles/pmtiles.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../core/data/ids.dart';

/// Why a file cannot be a map source.
enum ImportProblem {
  unreadable,

  /// Vector tiles: a region pack, not a picture to lay over the map.
  vector,

  /// Elevation tiles (terrain-RGB).
  elevation,
}

class SourceImportException implements Exception {
  const SourceImportException(this.problem);
  final ImportProblem problem;
  @override
  String toString() => 'SourceImportException($problem)';
}

/// What a raster tile file holds.
class RasterFileInfo {
  const RasterFileInfo({required this.format, required this.minZoom, required this.maxZoom, this.name, this.attribution});
  final String format;
  final int minZoom, maxZoom;
  final String? name, attribution;
}

/// Imported map files and downloaded areas live in Documents/sources, wiped
/// with everything else by the emergency wipe.
class SourceStore {
  SourceStore({this.root});

  /// Base directory, the app's Documents by default (tests pass a temp dir).
  final Directory? root;

  Future<Directory> dir() async {
    final d = Directory('${(root ?? await getApplicationDocumentsDirectory()).path}/sources');
    await d.create(recursive: true);
    return d;
  }

  Future<String> path(String file) async => '${(await dir()).path}/$file';

  /// Checks [path] is a raster MBTiles or PMTiles file.
  static Future<RasterFileInfo> inspect(String path) async {
    final lower = path.toLowerCase();
    if (lower.endsWith('.mbtiles')) return _inspectMbTiles(path);
    if (lower.endsWith('.pmtiles')) return _inspectPmTiles(path);
    throw const SourceImportException(ImportProblem.unreadable);
  }

  static RasterFileInfo _inspectMbTiles(String path) {
    Database? db;
    try {
      db = sqlite3.open(path, mode: OpenMode.readOnly);
      final meta = {for (final r in db.select('SELECT name, value FROM metadata')) r['name'] as String: '${r['value']}'};
      final format = (meta['format'] ?? '').toLowerCase();
      if (format == 'pbf' || format == 'mvt') throw const SourceImportException(ImportProblem.vector);
      if (meta.containsKey('encoding')) throw const SourceImportException(ImportProblem.elevation);
      final z = db.select('SELECT min(zoom_level) AS lo, max(zoom_level) AS hi FROM tiles').first;
      if (z['lo'] == null) throw const SourceImportException(ImportProblem.unreadable);
      return RasterFileInfo(
        format: format.isEmpty ? 'png' : format,
        minZoom: z['lo'] as int,
        maxZoom: z['hi'] as int,
        name: meta['name'],
        attribution: meta['attribution'],
      );
    } on SourceImportException {
      rethrow;
    } catch (_) {
      throw const SourceImportException(ImportProblem.unreadable);
    } finally {
      db?.close();
    }
  }

  static Future<RasterFileInfo> _inspectPmTiles(String path) async {
    PmTilesArchive? a;
    try {
      a = await PmTilesArchive.from(path);
      if (a.tileType == TileType.mvt) throw const SourceImportException(ImportProblem.vector);
      final meta = await a.metadata;
      final m = meta is Map ? meta : const {};
      if (m.containsKey('encoding')) throw const SourceImportException(ImportProblem.elevation);
      return RasterFileInfo(
        format: a.tileType.name,
        minZoom: a.minZoom,
        maxZoom: a.maxZoom,
        name: m['name'] as String?,
        attribution: m['attribution'] as String?,
      );
    } on SourceImportException {
      rethrow;
    } catch (_) {
      throw const SourceImportException(ImportProblem.unreadable);
    } finally {
      await a?.close();
    }
  }

  /// Copies [source] in under a new name; returns the file name and what it
  /// holds. Throws [SourceImportException].
  Future<(String, RasterFileInfo)> import(String source) async {
    final info = await inspect(source);
    final ext = source.toLowerCase().endsWith('.mbtiles') ? 'mbtiles' : 'pmtiles';
    final name = '${newId()}.$ext';
    await File(source).copy(await path(name));
    return (name, info);
  }

  Future<void> deleteFile(String file) async {
    final f = File(await path(file));
    if (await f.exists()) await f.delete();
  }

  /// Size and change time of each file, by name: the map rebuilds its style
  /// when a downloaded area grows.
  Future<Map<String, (int, DateTime)>> files() async {
    final out = <String, (int, DateTime)>{};
    await for (final f in (await dir()).list()) {
      if (f is! File) continue;
      final st = await f.stat();
      out[f.uri.pathSegments.last] = (st.size, st.modified);
    }
    return out;
  }
}

final sourceStoreProvider = Provider<SourceStore>((ref) => SourceStore());

/// Files in Documents/sources; invalidate after importing, downloading or
/// deleting.
final sourceFilesProvider = FutureProvider<Map<String, (int, DateTime)>>(
  (ref) => ref.watch(sourceStoreProvider).files(),
);

/// Writes tiles into an MBTiles file (rows flipped to TMS as the format
/// wants), keeping the bounds and zoom range in the metadata current so
/// MapLibre reads it as a plain raster source.
class MbTilesWriter {
  MbTilesWriter._(this._db);

  final Database _db;

  static MbTilesWriter open(String path, {required String name, String attribution = ''}) {
    final db = sqlite3.open(path);
    db.execute('''
      CREATE TABLE IF NOT EXISTS metadata (name TEXT PRIMARY KEY, value TEXT);
      CREATE TABLE IF NOT EXISTS tiles (zoom_level INTEGER, tile_column INTEGER, tile_row INTEGER, tile_data BLOB);
      CREATE UNIQUE INDEX IF NOT EXISTS tile_index ON tiles (zoom_level, tile_column, tile_row);
    ''');
    final w = MbTilesWriter._(db);
    w._meta('name', name);
    w._meta('type', 'overlay');
    w._meta('attribution', attribution);
    return w;
  }

  void _meta(String k, String v) => _db.execute('INSERT OR REPLACE INTO metadata VALUES (?, ?)', [k, v]);

  /// [y] counted from the north (XYZ).
  void put(int z, int x, int y, Uint8List data) {
    _db.execute('INSERT OR REPLACE INTO tiles VALUES (?, ?, ?, ?)', [z, x, (1 << z) - 1 - y, data]);
  }

  /// Updates zoom range, bounds and format from what is stored.
  void finish({String? format}) {
    if (format != null) _meta('format', format);
    final z = _db.select('SELECT min(zoom_level) AS lo, max(zoom_level) AS hi FROM tiles').first;
    if (z['lo'] == null) return;
    final lo = z['lo'] as int, hi = z['hi'] as int;
    _meta('minzoom', '$lo');
    _meta('maxzoom', '$hi');
    // Bounds from the deepest zoom's tile range.
    final r = _db.select(
      'SELECT min(tile_column) AS x0, max(tile_column) AS x1, min(tile_row) AS r0, max(tile_row) AS r1 '
      'FROM tiles WHERE zoom_level = ?',
      [hi],
    ).first;
    final n = 1 << hi;
    final yTop = n - 1 - (r['r1'] as int), yBottom = n - 1 - (r['r0'] as int);
    double lon(int x) => x / n * 360 - 180;
    double lat(int y) => math.atan(_sinh(math.pi * (1 - 2 * y / n))) * 180 / math.pi;
    _meta('bounds', '${lon(r['x0'] as int)},${lat(yBottom + 1)},${lon((r['x1'] as int) + 1)},${lat(yTop)}');
  }

  static double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;

  void close() => _db.close();
}

/// Image format by its first bytes, for the MBTiles metadata.
String? imageFormat(Uint8List b) {
  if (b.length > 4 && b[0] == 0x89 && b[1] == 0x50) return 'png';
  if (b.length > 3 && b[0] == 0xFF && b[1] == 0xD8) return 'jpg';
  if (b.length > 12 && b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50) return 'webp';
  return null;
}
