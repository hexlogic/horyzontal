import 'package:horyzontal_geo/horyzontal_geo.dart';

import '../../tasks/problems.dart';

/// What the ruler shows: the segment A→B (or A→crosshair until B is set),
/// grid increments, and where the crosshair lies relative to A→B.
class RulerReadout {
  const RulerReadout({
    required this.distance,
    required this.forward,
    required this.back,
    required this.frame,
    required this.dx,
    required this.dy,
    this.deviation,
  });

  final double distance;
  final AngleSet forward, back;
  final PlaneFrame frame;

  /// Grid increments B - A: northing and easting, metres.
  final double dx, dy;

  /// The crosshair relative to A→B, once B is set.
  final TrackDeviation? deviation;
}

RulerReadout rulerReadout(
  Geodetic a,
  Geodetic b,
  Geodetic? cursor,
  PlaneFrame frame, {
  bool fixed = true,
  DateTime? at,
}) {
  final r = Geodesic.wgs84.inverse(a.lat, a.lon, b.lat, b.lon);
  final pa = frame.project(a), pb = frame.project(b);
  return RulerReadout(
    distance: r.s12,
    forward: angleContextAt(a, frame, at: at).fromTrue(r.azi1),
    back: angleContextAt(b, frame, at: at).fromTrue(r.azi2 + 180),
    frame: frame,
    dx: pb.x - pa.x,
    dy: pb.y - pa.y,
    deviation: fixed && cursor != null && r.s12 > 0 ? trackDeviation(a, b, cursor) : null,
  );
}

/// Polyline and polygon figures, with the crosshair as a tentative next
/// vertex.
class PathReadout {
  const PathReadout({
    required this.metrics,
    this.polygon,
    this.next,
    this.nextAngle,
    this.withNext,
  });

  final PathMetrics metrics;

  /// Polygons with 3 or more vertices.
  final PolygonResult? polygon;

  /// From the last vertex to the crosshair.
  final PathSegment? next;

  /// Angle at the last vertex between its edge and the edge to the crosshair.
  final double? nextAngle;

  /// Length or area as if the crosshair were added.
  final double? withNext;
}

PathReadout pathReadout(List<Geodetic> vertices, Geodetic? cursor, {required bool closed}) {
  final metrics = pathMetrics(vertices, closed: closed);
  final polygon = closed && vertices.length >= 3 ? Geodesic.wgs84.polygon(vertices) : null;
  PathSegment? next;
  double? nextAngle;
  if (cursor != null && vertices.isNotEmpty) {
    final last = vertices.last;
    final r = Geodesic.wgs84.inverse(last.lat, last.lon, cursor.lat, cursor.lon);
    if (r.s12 > 0) {
      next = PathSegment(r.s12, normalizeDegrees(r.azi1), normalizeDegrees(r.azi2));
      if (vertices.length >= 2) {
        final m = pathMetrics([vertices[vertices.length - 2], last, cursor]);
        nextAngle = m.vertexAngles[1];
      }
    }
  }
  double? withNext;
  if (next != null) {
    final all = [...vertices, cursor!];
    withNext = closed
        ? (all.length >= 3 ? Geodesic.wgs84.polygon(all).area.abs() : null)
        : metrics.length + next.length;
  }
  return PathReadout(
    metrics: metrics,
    polygon: polygon,
    next: next,
    nextAngle: nextAngle,
    withNext: withNext,
  );
}
