// Area and perimeter of geodesic polygons.
//
// A port of the Python GeographicLib (polygonarea.py, accumulator.py),
// copyright (c) Charles F. F. Karney (2011-2022), licensed under the MIT/X11
// License (geographiclib.sourceforge.io)

part of 'geodesic.dart';

class PolygonResult {
  const PolygonResult(this.count, this.perimeter, this.area);

  final int count;

  /// Metres, including the closing edge.
  final double perimeter;

  /// Square metres, positive for counter-clockwise traversal, negative for
  /// clockwise; in (-A/2, A/2] where A is the area of the ellipsoid.
  final double area;
}

extension GeodesicPolygon on Geodesic {
  /// Total area of the ellipsoid, square metres.
  double get ellipsoidArea => 4 * math.pi * _c2;

  /// Perimeter and signed area of the polygon through [pts] (latitude and
  /// longitude, degrees), closed back to the first point. Edges are geodesics;
  /// self-intersecting polygons are summed algebraically.
  PolygonResult polygon(List<Geodetic> pts) {
    if (pts.length < 2) return PolygonResult(pts.length, 0, 0);
    final perimeter = _Accumulator(), area = _Accumulator();
    var crossings = 0;
    for (var i = 0; i < pts.length; i++) {
      final a = pts[i], b = pts[(i + 1) % pts.length];
      final r = inverse(a.lat, a.lon, b.lat, b.lon);
      perimeter.add(r.s12);
      area.add(r.area);
      crossings += _transit(a.lon, b.lon);
    }
    return PolygonResult(pts.length, perimeter.sum, _reduceArea(area, ellipsoidArea, crossings));
  }

  /// Length of the open path through [pts], metres.
  double pathLength(List<Geodetic> pts) {
    final s = _Accumulator();
    for (var i = 1; i < pts.length; i++) {
      s.add(inverse(pts[i - 1].lat, pts[i - 1].lon, pts[i].lat, pts[i].lon).s12);
    }
    return s.sum;
  }
}

/// Crossings of the prime meridian by the edge lon1 -> lon2.
int _transit(double lon1, double lon2) {
  final (lon12, _) = _angDiff(lon1, lon2);
  lon1 = _angNormalize(lon1);
  lon2 = _angNormalize(lon2);
  if (lon12 > 0 && ((lon1 < 0 && 0 <= lon2) || (lon1 > 0 && lon2 == 0))) return 1;
  if (lon12 < 0 && lon2 < 0 && 0 <= lon1) return -1;
  return 0;
}

/// Signed area with counter-clockwise positive (areareduceA, reverse=false,
/// sign=true).
double _reduceArea(_Accumulator area, double area0, int crossings) {
  area.remainder(area0);
  if (crossings.isOdd) area.add((area.sum < 0 ? 1 : -1) * area0 / 2);
  area.negate();
  if (area.sum > area0 / 2) {
    area.add(-area0);
  } else if (area.sum <= -area0 / 2) {
    area.add(area0);
  }
  return 0.0 + area.sum;
}

/// Sum of doubles carried to twice the precision.
class _Accumulator {
  double _s = 0, _t = 0;

  double get sum => _s;

  void add(double y) {
    final (yy, u) = _sum(y, _t);
    final (s, t) = _sum(yy, _s);
    _s = s;
    _t = t;
    if (_s == 0) {
      _s = u;
    } else {
      _t += u;
    }
  }

  void negate() {
    _s = -_s;
    _t = -_t;
  }

  void remainder(double y) {
    _s = _remainder(_s, y);
    add(0);
  }
}
