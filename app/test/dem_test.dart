import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal/core/dem/dem_reader.dart';
import 'package:horyzontal/core/dem/tile_source.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';
import 'package:image/image.dart' as img;

const _z = 12, _size = 256;

/// Global pixel coordinates (pixel centres at .5) of a point at zoom [_z].
(double, double) _pixel(double lat, double lon) {
  final n = 1 << _z;
  final r = lat * math.pi / 180;
  return (
    (lon + 180) / 360 * n * _size,
    (1 - math.log(math.tan(r) + 1 / math.cos(r)) / math.pi) / 2 * n * _size,
  );
}

Geodetic _geo(double gx, double gy) {
  final n = (1 << _z) * _size;
  final lat = math.atan(_sinh(math.pi * (1 - 2 * gy / n))) * 180 / math.pi;
  return Geodetic(lat, gx / n * 360 - 180);
}

double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;

/// Tiles rendered from a height function of global pixel coordinates.
class FakeTiles implements TileSource {
  FakeTiles(this.height, this.tiles, this.bounds);

  final double Function(double gx, double gy) height;
  final Set<(int, int)> tiles;
  @override
  final ({double west, double south, double east, double north}) bounds;
  int reads = 0;

  @override
  int get maxZoom => _z;

  @override
  Future<Uint8List?> tile(int z, int x, int y) async {
    if (!tiles.contains((x, y))) return null;
    reads++;
    final im = img.Image(width: _size, height: _size);
    for (var py = 0; py < _size; py++) {
      for (var px = 0; px < _size; px++) {
        final v = ((height(x * _size + px + 0.5, y * _size + py + 0.5) + 10000) * 10).round();
        im.setPixelRgb(px, py, v >> 16, (v >> 8) & 255, v & 255);
      }
    }
    return img.encodePng(im);
  }

  @override
  Future<void> close() async {}
}

void main() {
  const kyiv = Geodetic(50.45, 30.52);
  final (kx, ky) = _pixel(kyiv.lat, kyiv.lon);
  final tx = kx ~/ _size, ty = ky ~/ _size;
  final all = {for (var dx = -2; dx <= 2; dx++) for (var dy = -2; dy <= 2; dy++) (tx + dx, ty + dy)};
  const wide = (west: 29.0, south: 49.0, east: 32.0, north: 52.0);
  double plane(double gx, double gy) => 150 + 0.3 * (gx - kx) - 0.2 * (gy - ky);

  test('terrain-RGB decoding', () async {
    final im = img.Image(width: 2, height: 2);
    im.setPixelRgb(0, 0, 1, 134, 160); // 100000 → 0 m
    im.setPixelRgb(1, 0, 1, 138, 136); // 101000 → 100 m
    final t = decodeTerrainRgb(img.encodePng(im))!;
    expect(t.size, 2);
    expect(t.at(0, 0), closeTo(0, 1e-6));
    expect(t.at(1, 0), closeTo(100, 1e-3));
  });

  test('bilinear on a tilted plane is exact, also across tile edges', () async {
    final dem = DemReader([FakeTiles(plane, all, wide)]);
    final rnd = math.Random(1);
    for (var i = 0; i < 200; i++) {
      // Within ±1.5 tiles of Kyiv; some samples fall right at tile edges.
      final gx = kx + (rnd.nextDouble() - 0.5) * 3 * _size, gy = ky + (rnd.nextDouble() - 0.5) * 3 * _size;
      final p = _geo(gx, gy);
      expect(await dem.elevation(p), closeTo(plane(gx, gy), 0.06));
    }
    for (final off in [0.0, 0.3, 0.5, 0.7, 1.0]) {
      final gx = (tx + 1) * _size - 1 + off, gy = (ty + 1) * _size - 1 + off; // corner of four tiles
      expect(await dem.elevation(_geo(gx, gy)), closeTo(plane(gx, gy), 0.06));
    }
    // Exactly on a tile edge and either side of it.
    final edgeLon = (tx * _size) / ((1 << _z) * _size) * 360 - 180;
    for (final dl in [-1e-6, 0.0, 1e-6]) {
      final (gx, gy) = _pixel(kyiv.lat, edgeLon + dl);
      expect(await dem.elevation(Geodetic(kyiv.lat, edgeLon + dl)), closeTo(plane(gx, gy), 0.06));
    }
  });

  test('a missing tile falls through to the next pack', () async {
    final first = FakeTiles((_, _) => 10, {(tx, ty)}, wide);
    final second = FakeTiles((_, _) => 20, all, wide);
    final dem = DemReader([first, second]);
    expect(await dem.elevation(kyiv), closeTo(10, 0.06));
    // One tile north is only in the second pack.
    expect(await dem.elevation(_geo(kx, ky - _size)), closeTo(20, 0.06));
  });

  test('outside every pack is null; tiles are cached', () async {
    final src = FakeTiles(plane, all, (west: 30.4, south: 50.3, east: 30.7, north: 50.6));
    final dem = DemReader([src]);
    expect(await dem.elevation(const Geodetic(48.0, 24.0)), isNull);
    await dem.sample(List.filled(20, kyiv));
    expect(src.reads, lessThanOrEqualTo(4));
  });

  // The real pack is not committed: build it with tools/map-pipeline/build_dem.py.
  final out = Directory('../tools/map-pipeline/out');
  final packs = out.existsSync()
      ? out.listSync().whereType<File>().where((f) => f.path.contains('kyiv-dem') && f.path.endsWith('.pmtiles')).toList()
      : <File>[];
  test('heights from a Kyiv pack match Copernicus', () async {
    final ref = File('test/fixtures/kyiv-dem-reference.csv')
        .readAsLinesSync()
        .skip(1)
        .map((l) => l.split(',').map(double.parse).toList());
    final pts = [for (final r in ref) Geodetic(r[0], r[1])];
    final heights = await sampleDemInIsolate([packs.first.path], pts);
    final dem = DemReader([await PmTilesSource.open(packs.first.path)]);
    expect(await dem.sample(pts.take(10).toList()), heights.take(10).toList());
    await dem.close();
    final errors = [for (final (i, r) in ref.indexed) (heights[i]! - r[2]).abs()];
    errors.sort();
    expect(errors.reduce((a, b) => a + b) / errors.length, lessThan(1.5));
    expect(errors[(errors.length * 0.95).floor()], lessThan(5));
  }, skip: packs.isEmpty ? 'no Kyiv elevation pack in tools/map-pipeline/out' : false);
}
