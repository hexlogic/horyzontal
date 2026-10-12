import 'package:horyzontal_geo/horyzontal_geo.dart';

import '../geojson.dart';
import 'tool_state.dart';

const toolSource = 'hrz-tool';

/// Geodesic edge from [a] to [b] as a lon/lat list, curved like the real
/// line on long edges.
List<List<double>> _edge(Geodetic a, Geodetic b) {
  final s = Geodesic.wgs84.inverse(a.lat, a.lon, b.lat, b.lon).s12;
  final n = (s / 2000).clamp(2, 64).round();
  return [
    for (final p in n <= 2 ? [a, b] : densify([a, b], n)) lonLat(p),
  ];
}

List<List<double>> _path(List<Geodetic> pts) => [
  for (var i = 1; i < pts.length; i++)
    ...(i == 1 ? _edge(pts[0], pts[1]) : _edge(pts[i - 1], pts[i]).skip(1)),
];

Map<String, Object?> _feature(
  String kind,
  Map<String, Object?> geometry, [
  Map<String, Object?> props = const {},
]) => {
  'type': 'Feature',
  'properties': {'kind': kind, ...props},
  'geometry': geometry,
};

/// The tool overlay: committed edges, a dashed rubber band to the
/// crosshair, numbered vertices and, for the ruler, the perpendicular from the
/// crosshair to A→B.
Map<String, Object?> toolGeoJson(ToolState s, Geodetic? cursor) {
  final tool = s.tool;
  final v = s.vertices;
  if (tool == null) return collection(const []);
  final out = <Map<String, Object?>>[];
  final ring = tool.closed && v.length >= 3 ? [...v, v.first] : v;
  if (tool.closed && v.length >= 3) {
    out.add(
      _feature('fill', {
        'type': 'Polygon',
        'coordinates': [_path(ring)],
      }),
    );
  }
  if (ring.length >= 2) {
    out.add(_feature('line', {'type': 'LineString', 'coordinates': _path(ring)}));
  }
  if (cursor != null && v.isNotEmpty && !(tool.twoPoints && v.length == 2)) {
    final rubber = [v.last, cursor, if (tool.closed && v.length >= 2) v.first];
    out.add(_feature('rubber', {'type': 'LineString', 'coordinates': _path(rubber)}));
  }
  if (tool == MapTool.ruler && v.length == 2 && cursor != null) {
    final d = trackDeviation(v[0], v[1], cursor);
    if (d.baseLength > 0 && d.distance > 0) {
      final ab = Geodesic.wgs84.inverse(v[0].lat, v[0].lon, v[1].lat, v[1].lon);
      final foot = Geodesic.wgs84.direct(v[0].lat, v[0].lon, ab.azi1, d.along);
      final footPt = Geodetic(foot.lat2, foot.lon2);
      out.add(
        _feature('rubber', {
          'type': 'LineString',
          'coordinates': _path([cursor, footPt]),
        }),
      );
      // Extension of A→B past B up to the foot, when the crosshair is beyond.
      if (d.range > 0) {
        out.add(
          _feature('rubber', {
            'type': 'LineString',
            'coordinates': _path([v[1], footPt]),
          }),
        );
      }
    }
  }
  for (final (i, p) in v.indexed) {
    final label = tool.twoPoints ? (i == 0 ? 'A' : 'B') : '${i + 1}';
    out.add(_feature('vertex', {'type': 'Point', 'coordinates': lonLat(p)}, {'label': label}));
  }
  return collection(out);
}
