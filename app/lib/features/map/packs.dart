import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pmtiles/pmtiles.dart';

import '../../core/net/network.dart';
import '../../core/settings.dart';

/// A region from the bundled catalogue (tools/map-pipeline/regions).
class Region {
  const Region(this.id, this.name, this.bbox);
  final String id, name;

  /// west, south, east, north
  final List<double> bbox;

  bool contains(double lat, double lon) =>
      lon >= bbox[0] && lon <= bbox[2] && lat >= bbox[1] && lat <= bbox[3];
}

enum PackKind { basemap, dem }

/// A PMTiles file on the device.
class PackFile {
  const PackFile(this.path, this.kind, this.bytes, this.minZoom, this.maxZoom);
  final String path;
  final PackKind kind;
  final int bytes;
  final int minZoom, maxZoom;

  String get name => path.split('/').last;

  /// Region id for packs named like the release assets (`kyiv.pmtiles`,
  /// `kyiv-dem.pmtiles`); other imported files keep their file name.
  String get regionId => name.replaceAll('.pmtiles', '').replaceAll(RegExp(r'-dem$'), '');
}

/// A file of a region in the release manifest.
class RemoteFile {
  const RemoteFile(this.kind, this.name, this.bytes, this.sha256);
  final PackKind kind;
  final String name, sha256;
  final int bytes;
}

class RemoteRegion {
  const RemoteRegion(this.id, this.build, this.files);
  final String id, build;
  final List<RemoteFile> files;
  int get bytes => files.fold(0, (s, f) => s + f.bytes);
}

/// `packs.json` written by tools/map-pipeline/manifest.py next to the files.
List<RemoteRegion> parseManifest(String json) {
  final m = jsonDecode(json) as Map<String, Object?>;
  if (m['version'] != 1) throw const FormatException('Unsupported manifest version');
  final build = m['build'] as String;
  return [
    for (final r in (m['regions'] as List<Object?>).cast<Map<String, Object?>>())
      RemoteRegion(r['id'] as String, build, [
        for (final f in (r['files'] as List<Object?>).cast<Map<String, Object?>>())
          RemoteFile(
            PackKind.values.byName(f['kind'] as String),
            f['name'] as String,
            f['bytes'] as int,
            f['sha256'] as String,
          ),
      ]),
  ];
}

/// Offline packs live in Documents/packs (visible in the iOS Files app and
/// writable over USB); fonts and sprites are copied out of the bundle into
/// Application Support for MapLibre to read through file:// URLs.
class PackStore {
  PackStore({this.root});

  /// Base directory, the app's Documents by default (tests pass a temp dir).
  final Directory? root;

  static const _assetsPrefix = 'assets/map/';
  static const _assetsVersion = '2';

  Future<Directory> dir() async {
    final d = Directory('${(root ?? await getApplicationDocumentsDirectory()).path}/packs');
    await d.create(recursive: true);
    return d;
  }

  Future<List<PackFile>> list() async {
    final out = <PackFile>[];
    await for (final f in (await dir()).list()) {
      if (f is! File || !f.path.endsWith('.pmtiles')) continue;
      final p = await inspect(f.path);
      if (p != null) out.add(p);
    }
    out.sort((a, b) => a.name.compareTo(b.name));
    return out;
  }

  /// Reads the PMTiles header; null if the file is not a usable archive.
  static Future<PackFile?> inspect(String path) async {
    try {
      final a = await PmTilesArchive.from(path);
      try {
        final kind = a.tileType == TileType.mvt ? PackKind.basemap : PackKind.dem;
        return PackFile(path, kind, await File(path).length(), a.header.minZoom, a.header.maxZoom);
      } finally {
        await a.close();
      }
    } catch (_) {
      return null;
    }
  }

  /// Copies a user-picked .pmtiles into the packs folder.
  Future<PackFile?> import(String source) async {
    final p = await inspect(source);
    if (p == null) return null;
    final dest = '${(await dir()).path}/${source.split('/').last}';
    if (dest != source) await File(source).copy(dest);
    return inspect(dest);
  }

  Future<void> delete(PackFile p) async {
    final f = File(p.path);
    if (await f.exists()) await f.delete();
  }

  Future<void> deleteAll() async {
    final d = await dir();
    if (await d.exists()) await d.delete(recursive: true);
  }

  static Future<List<Region>> regions() async {
    final raw = await rootBundle.loadString('${_assetsPrefix}regions.json');
    return [
      for (final r in (jsonDecode(raw) as List<Object?>).cast<Map<String, Object?>>())
        Region(
          r['id'] as String,
          r['name'] as String,
          [for (final v in r['bbox'] as List<Object?>) (v as num).toDouble()],
        ),
    ];
  }

  /// Copies glyphs and sprites out of the bundle once per assets version.
  static Future<String> installAssets() async {
    final support = await getApplicationSupportDirectory();
    final root = Directory('${support.path}/map-assets');
    final marker = File('${root.path}/.version');
    if (await marker.exists() && await marker.readAsString() == _assetsVersion) return root.path;
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    for (final key in manifest.listAssets()) {
      if (!key.startsWith('${_assetsPrefix}fonts/') && !key.startsWith('${_assetsPrefix}sprites/')) {
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
}

/// Progress of one file download.
class DownloadProgress {
  const DownloadProgress(this.received, this.total);
  final int received, total;
  double get fraction => total == 0 ? 0 : received / total;
}

class ChecksumMismatch implements Exception {
  const ChecksumMismatch(this.file);
  final String file;
}

/// Downloads a release asset into [destDir] through a `.part` file that a
/// later call resumes with an HTTP Range request; the finished file must
/// match the manifest's SHA-256 before it replaces the old pack.
Stream<DownloadProgress> downloadFile(Net net, RemoteFile f, Directory destDir,
    {Uri? base}) async* {
  final part = File('${destDir.path}/${f.name}.part');
  final dest = File('${destDir.path}/${f.name}');
  var have = await part.exists() ? await part.length() : 0;
  if (have > f.bytes) {
    await part.delete();
    have = 0;
  }
  if (have < f.bytes) {
    final url = (base ?? Uri.parse(packsBaseUrl)).resolve(f.name);
    final res = await net.get(url, headers: {if (have > 0) 'Range': 'bytes=$have-'});
    if (res.statusCode == 200 && have > 0) {
      have = 0; // server ignored Range: start over
    } else if (res.statusCode != 206 && res.statusCode != 200) {
      await res.drain<void>();
      throw HttpException('HTTP ${res.statusCode}', uri: url);
    }
    final sink = part.openWrite(mode: have > 0 ? FileMode.append : FileMode.write);
    try {
      var last = DateTime.now();
      await for (final chunk in res) {
        sink.add(chunk);
        have += chunk.length;
        final now = DateTime.now();
        if (now.difference(last).inMilliseconds > 200) {
          last = now;
          yield DownloadProgress(have, f.bytes);
        }
      }
    } finally {
      await sink.close();
    }
  }
  if (have < f.bytes) {
    // Connection dropped: keep the .part, the next attempt resumes it.
    throw HttpException('incomplete: $have of ${f.bytes}');
  }
  yield DownloadProgress(have, f.bytes);
  final digest = await sha256.bind(part.openRead()).first;
  if (digest.toString() != f.sha256) {
    await part.delete();
    throw ChecksumMismatch(f.name);
  }
  await part.rename(dest.path);
}

final packStoreProvider = Provider<PackStore>((ref) => PackStore());

final netProvider = Provider<Net>(
  (ref) => Net(offlineOnly: () => ref.read(settingsProvider).offlineOnly),
);

/// Installed packs; invalidate after installing or deleting.
final packsProvider = FutureProvider<List<PackFile>>((ref) => ref.watch(packStoreProvider).list());

final regionsProvider = FutureProvider<List<Region>>((ref) => PackStore.regions());

/// Release manifest, fetched on demand from the packs screen.
final manifestProvider = FutureProvider.autoDispose<List<RemoteRegion>>((ref) async {
  final net = ref.watch(netProvider);
  return parseManifest(await net.getString(Uri.parse(packsBaseUrl).resolve('packs.json')));
});
