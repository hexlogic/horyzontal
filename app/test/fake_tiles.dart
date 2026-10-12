import 'dart:math' as math;
import 'dart:typed_data';

import 'package:horyzontal/core/dem/tile_source.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';
import 'package:image/image.dart' as img;

const tileZoom = 12, tileSize = 256;

/// Global pixel coordinates (pixel centres at .5) of a point at zoom [tileZoom].
(double, double) pixelAt(double lat, double lon) {
  final n = 1 << tileZoom;
  final r = lat * math.pi / 180;
  return (
    (lon + 180) / 360 * n * tileSize,
    (1 - math.log(math.tan(r) + 1 / math.cos(r)) / math.pi) / 2 * n * tileSize,
  );
}

Geodetic geoAt(double gx, double gy) {
  final n = (1 << tileZoom) * tileSize;
  final lat = math.atan(_sinh(math.pi * (1 - 2 * gy / n))) * 180 / math.pi;
  return Geodetic(lat, gx / n * 360 - 180);
}

double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;

/// Tiles rendered from a height function of global pixel coordinates.
class FakeTiles implements TileSource {
  FakeTiles(this.height, this.tiles, this.bounds);

  final double Function(double gx, double gy) height;
  /// Null: every tile.
  final Set<(int, int)>? tiles;
  @override
  final ({double west, double south, double east, double north}) bounds;
  int reads = 0;

  @override
  int get maxZoom => tileZoom;

  @override
  Future<Uint8List?> tile(int z, int x, int y) async {
    if (tiles != null && !tiles!.contains((x, y))) return null;
    reads++;
    final im = img.Image(width: tileSize, height: tileSize);
    for (var py = 0; py < tileSize; py++) {
      for (var px = 0; px < tileSize; px++) {
        final v = ((height(x * tileSize + px + 0.5, y * tileSize + py + 0.5) + 10000) * 10).round();
        im.setPixelRgb(px, py, v >> 16, (v >> 8) & 255, v & 255);
      }
    }
    return img.encodePng(im);
  }

  @override
  Future<void> close() async {}
}
