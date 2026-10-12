import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

import '../../l10n/app_localizations.dart';
import '../labels.dart';
import '../settings.dart';
import 'copy_tile.dart';

/// Text of [wgs] in every system, `label: value` per line, for sharing.
String pointAsText(AppLocalizations l, Geodetic wgs, GeoFormat geoFormat) => [
  for (final s in CoordinateSystem.values)
    if (_safeFormat(wgs, s, geoFormat) case final v?) '${systemName(l, s)}: $v',
].join('\n');

String? _safeFormat(Geodetic wgs, CoordinateSystem s, GeoFormat f, {int? zone}) {
  try {
    return formatPoint(wgs, s, f, zone: zone);
  } on RangeError {
    return null; // e.g. UTM beyond 84°N
  }
}

/// [wgs] in every coordinate system, with the neighbouring 6° zone when the
/// point is within a degree of a zone edge (adjacent map sheets).
class PointResults extends ConsumerWidget {
  const PointResults({super.key, required this.wgs});

  final Geodetic wgs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final geoFormat = ref.watch(settingsProvider).geoFormat;
    final tiles = <Widget>[];
    for (final s in CoordinateSystem.values) {
      final v = _safeFormat(wgs, s, geoFormat);
      if (v == null) continue;
      tiles.add(CopyTile(label: systemName(l, s), value: v));
      final neighbour = _neighbourZone(s);
      if (neighbour != null) {
        final nv = _safeFormat(wgs, s, geoFormat, zone: neighbour);
        if (nv != null) {
          tiles.add(
            CopyTile(
              label: '${systemName(l, s)}, ${l.zoneValue(neighbour)}',
              value: nv,
              dense: true,
            ),
          );
        }
      }
    }
    return Column(children: tiles);
  }

  int? _neighbourZone(CoordinateSystem s) {
    final grid = s.grid;
    if (grid == null) return null;
    final g = s.datum.fromWgs84Geodetic(wgs);
    final zone = grid.zoneFor(g.lon);
    final offset = g.lon - grid.centralMeridian(zone);
    final half = grid.zoneWidth / 2;
    if (offset.abs() < half - 1) return null;
    return offset > 0 ? zone + 1 : zone - 1;
  }
}
