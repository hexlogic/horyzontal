import 'dart:typed_data';

import 'package:pmtiles/pmtiles.dart';

/// Raster tiles of one archive at a single zoom.
abstract interface class TileSource {
  int get maxZoom;

  /// Degrees: west, south, east, north.
  ({double west, double south, double east, double north}) get bounds;

  /// Encoded image, or null where the archive has no tile.
  Future<Uint8List?> tile(int z, int x, int y);

  Future<void> close();
}

class PmTilesSource implements TileSource {
  PmTilesSource._(this._archive);

  static Future<PmTilesSource> open(String path) async => PmTilesSource._(await PmTilesArchive.from(path));

  final PmTilesArchive _archive;

  @override
  int get maxZoom => _archive.header.maxZoom;

  @override
  ({double west, double south, double east, double north}) get bounds {
    final min = _archive.header.minPosition, max = _archive.header.maxPosition;
    return (west: min.longitude, south: min.latitude, east: max.longitude, north: max.latitude);
  }

  @override
  Future<Uint8List?> tile(int z, int x, int y) async {
    try {
      final bytes = (await _archive.tile(ZXY(z, x, y).toTileId())).bytes();
      return bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    } on TileNotFoundException {
      return null;
    }
  }

  @override
  Future<void> close() => _archive.close();
}
