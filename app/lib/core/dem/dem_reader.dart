import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:horyzontal_geo/horyzontal_geo.dart';
import 'package:image/image.dart' as img;

import 'tile_source.dart';

/// Heights of a terrain-RGB tile (Mapbox encoding), row by row.
class HeightTile {
  HeightTile(this.size, this.heights);
  final int size;
  final Float32List heights;

  double at(int x, int y) => heights[y * size + x];
}

HeightTile? decodeTerrainRgb(Uint8List bytes) {
  final im = img.decodeImage(bytes);
  if (im == null || im.width != im.height) return null;
  final rgb = im.getBytes(order: img.ChannelOrder.rgb);
  final out = Float32List(im.width * im.height);
  for (var i = 0, j = 0; i < out.length; i++, j += 3) {
    out[i] = -10000 + (rgb[j] * 65536 + rgb[j + 1] * 256 + rgb[j + 2]) * 0.1;
  }
  return HeightTile(im.width, out);
}

/// Reads ground heights (metres above sea level, EGM2008) from terrain-RGB
/// archives at their highest zoom. Several archives may overlap: the first
/// one that has data for a point wins.
class DemReader {
  DemReader(this.sources, {this.cacheTiles = 64});

  final List<TileSource> sources;
  final int cacheTiles;
  final _cache = <(int, int, int), HeightTile?>{}; // insertion-ordered: LRU

  /// Height at [g], bilinear between pixel centres; null outside the data.
  Future<double?> elevation(Geodetic g) async {
    for (var i = 0; i < sources.length; i++) {
      final b = sources[i].bounds;
      if (g.lon < b.west || g.lon > b.east || g.lat < b.south || g.lat > b.north) continue;
      final h = await _elevationIn(i, g.lat, g.lon);
      if (h != null) return h;
    }
    return null;
  }

  Future<List<double?>> sample(List<Geodetic> pts) async => [for (final p in pts) await elevation(p)];

  Future<void> close() async {
    for (final s in sources) {
      await s.close();
    }
  }

  Future<double?> _elevationIn(int source, double lat, double lon) async {
    final z = sources[source].maxZoom;
    final n = 1 << z;
    final latRad = lat * math.pi / 180;
    final fx = (lon + 180) / 360 * n;
    final fy = (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) / 2 * n;
    final home = await _tile(source, fx.floor(), fy.floor());
    if (home == null) return null;
    final size = home.size;

    // Pixel centres around the point, in pixels of the whole zoom level, so
    // that neighbours across a tile edge come from the next tile.
    final px = fx * size - 0.5, py = fy * size - 0.5;
    final x0 = px.floor(), y0 = py.floor();
    final dx = px - x0, dy = py - y0;
    final hx = fx.floor() * size, hy = fy.floor() * size;
    Future<double> h(int x, int y) async {
      final t = (x >= hx && x < hx + size && y >= hy && y < hy + size)
          ? home
          : await _tile(source, _div(x, size), _div(y, size));
      // A missing neighbour (edge of the pack): clamp into the home tile.
      if (t == null || t.size != size) return home.at((x - hx).clamp(0, size - 1), (y - hy).clamp(0, size - 1));
      return t.at(x - _div(x, size) * size, y - _div(y, size) * size);
    }

    final h00 = await h(x0, y0), h10 = await h(x0 + 1, y0);
    final h01 = await h(x0, y0 + 1), h11 = await h(x0 + 1, y0 + 1);
    if (h00 <= -9999 || h10 <= -9999 || h01 <= -9999 || h11 <= -9999) return null;
    final top = h00 * (1 - dx) + h10 * dx;
    final bottom = h01 * (1 - dx) + h11 * dx;
    return top * (1 - dy) + bottom * dy;
  }

  static int _div(int a, int b) => (a / b).floor();

  Future<HeightTile?> _tile(int source, int x, int y) async {
    final key = (source, x, y);
    if (_cache.containsKey(key)) {
      final hit = _cache.remove(key);
      _cache[key] = hit;
      return hit;
    }
    final s = sources[source];
    final n = 1 << s.maxZoom;
    HeightTile? t;
    if (x >= 0 && y >= 0 && x < n && y < n) {
      final bytes = await s.tile(s.maxZoom, x, y);
      t = bytes == null ? null : decodeTerrainRgb(bytes);
    }
    _cache[key] = t;
    if (_cache.length > cacheTiles) _cache.remove(_cache.keys.first);
    return t;
  }
}

/// [DemReader.sample] on a background isolate: decoding WebP in Dart takes
/// tens of milliseconds a tile, too slow for the UI thread on long profiles.
Future<List<double?>> sampleDemInIsolate(List<String> paths, List<Geodetic> pts) => Isolate.run(() async {
  final reader = DemReader([for (final p in paths) await PmTilesSource.open(p)]);
  try {
    return await reader.sample(pts);
  } finally {
    await reader.close();
  }
});
