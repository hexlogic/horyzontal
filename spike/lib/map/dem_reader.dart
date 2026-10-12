import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pmtiles/pmtiles.dart';

/// Reads heights from a terrain-RGB (Mapbox encoding) PMTiles archive.
///
/// This is the path the real app will use for the elevation profile and
/// line-of-sight: MapLibre only draws the hillshade, the numbers come from here.
class DemReader {
  DemReader._(this._archive, this.maxZoom);

  final PmTilesArchive _archive;
  final int maxZoom;
  final _cache = <int, img.Image?>{}; // insertion-ordered: LRU
  static const _cacheSize = 64;

  static Future<DemReader> open(String path) async {
    final archive = await PmTilesArchive.from(path);
    return DemReader._(archive, archive.header.maxZoom);
  }

  Future<void> close() => _archive.close();

  /// Height in metres at [lat], [lon], bilinear between pixel centres.
  /// Null when the point is outside the pack.
  Future<double?> elevation(double lat, double lon) async {
    final n = 1 << maxZoom;
    final latRad = lat * math.pi / 180;
    final fx = (lon + 180) / 360 * n;
    final fy = (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) / 2 * n;
    final tx = fx.floor(), ty = fy.floor();
    final tile = await _tile(tx, ty);
    if (tile == null) return null;

    final size = tile.width;
    final px = ((fx - tx) * size - 0.5).clamp(0.0, size - 1.0);
    final py = ((fy - ty) * size - 0.5).clamp(0.0, size - 1.0);
    final x0 = px.floor(), y0 = py.floor();
    final x1 = math.min(x0 + 1, size - 1), y1 = math.min(y0 + 1, size - 1);
    final dx = px - x0, dy = py - y0;
    final top = _h(tile, x0, y0) * (1 - dx) + _h(tile, x1, y0) * dx;
    final bottom = _h(tile, x0, y1) * (1 - dx) + _h(tile, x1, y1) * dx;
    return top * (1 - dy) + bottom * dy;
  }

  /// [samples] heights evenly spaced on the straight line between two points.
  Future<List<double?>> profile(
    double lat0,
    double lon0,
    double lat1,
    double lon1, {
    int samples = 256,
  }) async {
    final out = <double?>[];
    for (var i = 0; i < samples; i++) {
      final t = i / (samples - 1);
      out.add(await elevation(lat0 + (lat1 - lat0) * t, lon0 + (lon1 - lon0) * t));
    }
    return out;
  }

  static double _h(img.Image tile, int x, int y) {
    final p = tile.getPixel(x, y);
    return -10000 + (p.r.toInt() * 65536 + p.g.toInt() * 256 + p.b.toInt()) * 0.1;
  }

  Future<img.Image?> _tile(int x, int y) async {
    final id = ZXY(maxZoom, x, y).toTileId();
    if (_cache.containsKey(id)) {
      final hit = _cache.remove(id);
      _cache[id] = hit;
      return hit;
    }
    img.Image? decoded;
    try {
      final tile = await _archive.tile(id);
      final bytes = tile.bytes();
      decoded = img.decodeImage(bytes is Uint8List ? bytes : Uint8List.fromList(bytes));
    } on TileNotFoundException {
      decoded = null;
    }
    _cache[id] = decoded;
    if (_cache.length > _cacheSize) _cache.remove(_cache.keys.first);
    return decoded;
  }
}
