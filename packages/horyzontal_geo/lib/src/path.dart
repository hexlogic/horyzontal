import 'angle.dart';
import 'datum.dart';
import 'geodesic.dart';

/// One geodesic edge of a path.
class PathSegment {
  const PathSegment(this.length, this.azimuth1, this.azimuth2);

  /// Metres.
  final double length;

  /// Azimuth at the start, and the forward azimuth on arrival at the end,
  /// degrees [0, 360).
  final double azimuth1, azimuth2;
}

/// Lengths and angles of a polyline or, when [closed], a polygon.
class PathMetrics {
  const PathMetrics._(this.segments, this.length, this.turns, this.interiorAngles);

  /// n - 1 edges for an open path, n for a closed one (the last closes it).
  final List<PathSegment> segments;

  /// Total length (perimeter when closed), metres.
  final double length;

  /// Signed change of direction at each vertex, degrees (-180, 180],
  /// positive to the right. Null at the ends of an open path.
  final List<double?> turns;

  /// Closed paths only: angle inside the polygon at each vertex, [0, 360).
  final List<double>? interiorAngles;

  /// Angle between the two edges meeting at each vertex, [0, 180].
  List<double?> get vertexAngles => [for (final t in turns) t == null ? null : 180 - t.abs()];
}

PathMetrics pathMetrics(List<Geodetic> pts, {bool closed = false, Geodesic? geod}) {
  final g = geod ?? Geodesic.wgs84;
  final n = pts.length;
  final edges = closed && n > 2 ? n : n - 1;
  final segments = <PathSegment>[];
  var length = 0.0;
  for (var i = 0; i < edges; i++) {
    final a = pts[i], b = pts[(i + 1) % n];
    final r = g.inverse(a.lat, a.lon, b.lat, b.lon);
    segments.add(PathSegment(r.s12, normalizeDegrees(r.azi1), normalizeDegrees(r.azi2)));
    length += r.s12;
  }
  final turns = List<double?>.filled(n, null);
  for (var i = 0; i < n; i++) {
    final inIdx = i > 0 ? i - 1 : (edges == n ? n - 1 : -1);
    final outIdx = i < edges ? i : -1;
    if (inIdx < 0 || outIdx < 0) continue;
    turns[i] = normalizeSignedDegrees(segments[outIdx].azimuth1 - segments[inIdx].azimuth2);
  }
  List<double>? interior;
  if (closed && n > 2) {
    // Counter-clockwise polygons have the inside on the left.
    final ccw = g.polygon(pts).area > 0;
    interior = [for (final t in turns) normalizeDegrees(ccw ? 180 + t! : 180 - t!)];
  }
  return PathMetrics._(segments, length, turns, interior);
}

/// Distance from the first point to each vertex along the path, metres.
List<double> cumulativeDistances(List<Geodetic> pts, {Geodesic? geod}) {
  final g = geod ?? Geodesic.wgs84;
  final out = <double>[if (pts.isNotEmpty) 0];
  for (var i = 1; i < pts.length; i++) {
    out.add(out.last + g.inverse(pts[i - 1].lat, pts[i - 1].lon, pts[i].lat, pts[i].lon).s12);
  }
  return out;
}

/// [samples] points spread evenly by distance along the path through [pts]
/// (geodesic edges), first and last vertices included. Heights are dropped.
List<Geodetic> densify(List<Geodetic> pts, int samples, {Geodesic? geod}) {
  final g = geod ?? Geodesic.wgs84;
  if (pts.length < 2 || samples < 2) return [for (final p in pts) Geodetic(p.lat, p.lon)];
  final edges = [
    for (var i = 1; i < pts.length; i++) g.inverse(pts[i - 1].lat, pts[i - 1].lon, pts[i].lat, pts[i].lon),
  ];
  final total = edges.fold(0.0, (s, e) => s + e.s12);
  final out = <Geodetic>[];
  var e = 0, start = 0.0;
  for (var k = 0; k < samples; k++) {
    final d = total * k / (samples - 1);
    while (e < edges.length - 1 && d > start + edges[e].s12) {
      start += edges[e].s12;
      e++;
    }
    final r = g.direct(edges[e].lat1, edges[e].lon1, edges[e].azi1, d - start);
    out.add(Geodetic(r.lat2, r.lon2));
  }
  out[0] = Geodetic(pts.first.lat, pts.first.lon);
  out[out.length - 1] = Geodetic(pts.last.lat, pts.last.lon);
  return out;
}
