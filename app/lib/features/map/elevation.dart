import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

import '../../core/dem/dem_reader.dart';
import '../../core/dem/tile_source.dart';
import 'packs.dart';

/// Ground heights from the installed elevation packs.
class Dem {
  Dem(this.paths, this._reader);

  static Future<Dem> open(List<String> paths) async =>
      Dem(paths, DemReader([for (final p in paths) await PmTilesSource.open(p)]));

  final List<String> paths;
  final DemReader _reader;

  /// Height above sea level at one point, metres.
  Future<double?> at(Geodetic g) => _reader.elevation(g);

  /// Heights at many points; long lists are read on a background isolate.
  Future<List<double?>> sample(List<Geodetic> pts) =>
      pts.length <= 32 ? _reader.sample(pts) : sampleDemInIsolate(paths, pts);

  Future<void> close() => _reader.close();
}

/// Null when there is no elevation pack on the device.
final demProvider = FutureProvider<Dem?>((ref) async {
  final packs = await ref.watch(packsProvider.future);
  final paths = [
    for (final p in packs)
      if (p.kind == PackKind.dem) p.path,
  ];
  if (paths.isEmpty) return null;
  final dem = await Dem.open(paths);
  ref.onDispose(dem.close);
  return dem;
});
