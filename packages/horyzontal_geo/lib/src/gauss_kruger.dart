import 'datum.dart';
import 'transverse_mercator.dart';

/// Gauss-Krüger rectangular coordinates. [x] is northing and [y] easting,
/// the geodetic convention used on Soviet and Ukrainian topographic maps.
class GkPoint {
  const GkPoint(this.zone, this.x, this.y);

  final int zone;

  /// Northing, metres.
  final double x;

  /// Easting, metres, including the false easting of the grid (for 6° zones
  /// that is `zone * 1 000 000 + 500 000`, so the first digit is the zone).
  final double y;

  @override
  String toString() => 'GkPoint($zone, $x, $y)';
}

/// Gauss-Krüger grid on a datum. Two flavours are in use in Ukraine:
/// 6° zones with the zone number in front of the easting (СК-42 and УСК-2000
/// topographic maps, EPSG:28404-28407 and 5562-5565), and the 3° cadastral
/// zones of УСК-2000 with a plain 300 km false easting (EPSG:6381-6387,
/// zones 7-13).
class GaussKruger {
  const GaussKruger._(this.datum, this.zoneWidth);

  final Datum datum;
  final int zoneWidth;

  static final sk42 = GaussKruger._(Datum.sk42, 6);
  static final usk2000 = GaussKruger._(Datum.usk2000, 6);
  static final usk2000Tm3 = GaussKruger._(Datum.usk2000, 3);

  static final _tm = <Datum, TransverseMercator>{};
  TransverseMercator get _proj => _tm.putIfAbsent(datum, () => TransverseMercator(datum.ellipsoid));

  bool get prefixedEasting => zoneWidth == 6;

  /// Central meridian of [zone].
  double centralMeridian(int zone) => zoneWidth == 6 ? zone * 6.0 - 3 : zone * 3.0;

  double falseEasting(int zone) => zoneWidth == 6 ? zone * 1e6 + 500000 : 300000;

  /// Zone containing longitude [lon] (on this datum).
  int zoneFor(double lon) {
    final l = lon < 0 ? lon + 360 : lon;
    return zoneWidth == 6 ? (l / 6).floor() + 1 : ((l + 1.5) / 3).floor();
  }

  /// Zone encoded in the easting of a 6° grid, or null for 3° grids.
  int? zoneFromEasting(double y) => prefixedEasting ? (y / 1e6).floor() : null;

  /// Projects datum geodetic coordinates. [zone] forces a zone, e.g. the
  /// neighbouring one when working across a sheet edge.
  GkPoint fromGeodetic(Geodetic g, {int? zone}) => _project(g, zone ?? zoneFor(g.lon)).$1;

  /// Meridian convergence (degrees) at [g] in its zone or a forced [zone].
  double convergence(Geodetic g, {int? zone}) => _project(g, zone ?? zoneFor(g.lon)).$2.convergence;

  (GkPoint, TmPoint) _project(Geodetic g, int zone) {
    final p = _proj.forward(g.lat, g.lon, centralMeridian(zone));
    return (GkPoint(zone, p.y, p.x + falseEasting(zone)), p);
  }

  Geodetic toGeodetic(GkPoint p) {
    final (lat, lon) = _proj.inverse(p.y - falseEasting(p.zone), p.x, centralMeridian(p.zone));
    return Geodetic(lat, lon);
  }

  /// WGS 84 to this grid.
  GkPoint fromWgs84(Geodetic wgs, {int? zone}) =>
      fromGeodetic(datum.fromWgs84Geodetic(wgs), zone: zone);

  Geodetic toWgs84(GkPoint p) => datum.toWgs84Geodetic(toGeodetic(p));
}
