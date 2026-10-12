import 'coordinates.dart';
import 'datum.dart';
import 'gauss_kruger.dart';
import 'geodesic.dart';
import 'plane.dart';
import 'transverse_mercator.dart';
import 'utm.dart';

extension PlaneSystem on CoordinateSystem {
  /// Rectangular grid that plane problems can be solved in.
  bool get canBePlane => isGrid || this == CoordinateSystem.utm;
}

/// Rectangular grid and zone of plane problems (ПГЗ/ОГЗ на площині, ruler
/// increments): Gauss-Krüger on СК-42 or УСК-2000, УСК-2000 3° zones, or UTM.
/// [PlanePoint.x] is northing and [PlanePoint.y] easting.
class PlaneFrame {
  const PlaneFrame(this.system, this.zone, {this.south = false})
    : assert(system == CoordinateSystem.utm || system == CoordinateSystem.sk42Gk ||
          system == CoordinateSystem.usk2000Gk || system == CoordinateSystem.usk2000Tm3);

  /// Frame for a point typed in [system]: that grid (MGRS goes to UTM), else
  /// СК-42 Gauss-Krüger. [zone] defaults to the zone of [wgs].
  factory PlaneFrame.auto(Geodetic wgs, CoordinateSystem system, {int? zone}) {
    final s = system == CoordinateSystem.mgrs
        ? CoordinateSystem.utm
        : system.canBePlane
        ? system
        : CoordinateSystem.sk42Gk;
    if (s == CoordinateSystem.utm) {
      return PlaneFrame(s, zone ?? utmZone(wgs.lat, wgs.lon), south: wgs.lat < 0);
    }
    return PlaneFrame(s, zone ?? s.grid!.zoneFor(s.datum.fromWgs84Geodetic(wgs).lon));
  }

  final CoordinateSystem system;
  final int zone;

  /// UTM only: southern hemisphere false northing.
  final bool south;

  bool get isUtm => system == CoordinateSystem.utm;

  PlanePoint project(Geodetic wgs) {
    if (isUtm) {
      final p = utmFromWgs84(wgs, zone: zone);
      // utmFromWgs84 picks the false northing by the point's own hemisphere.
      final n = south == wgs.lat < 0 ? p.northing : (south ? p.northing + 1e7 : p.northing - 1e7);
      return PlanePoint(n, p.easting);
    }
    final p = system.grid!.fromWgs84(wgs, zone: zone);
    return PlanePoint(p.x, p.y);
  }

  Geodetic unproject(PlanePoint p) {
    if (isUtm) return utmToWgs84(UtmPoint(zone, south ? 'M' : 'N', p.y, p.x));
    return system.grid!.toWgs84(GkPoint(zone, p.x, p.y));
  }

  TmPoint _factors(Geodetic wgs) => isUtm
      ? utmFactors(wgs, zone)
      : system.grid!.factors(system.datum.fromWgs84Geodetic(wgs), zone: zone);

  /// Meridian convergence at [wgs], degrees: the bearing of grid north from
  /// true north, so a true azimuth is the grid bearing plus this.
  double convergence(Geodetic wgs) => _factors(wgs).convergence;

  /// Point scale factor at [wgs].
  double scale(Geodetic wgs) => _factors(wgs).scale;

  /// Mean scale factor along the line [a]-[b] (Simpson's rule): grid
  /// distance ≈ ellipsoid distance × this.
  double meanScale(Geodetic a, Geodetic b) {
    final g = Geodesic.wgs84;
    final inv = g.inverse(a.lat, a.lon, b.lat, b.lon);
    final m = g.direct(a.lat, a.lon, inv.azi1, inv.s12 / 2);
    return (scale(a) + 4 * scale(Geodetic(m.lat2, m.lon2)) + scale(b)) / 6;
  }

  @override
  bool operator ==(Object other) =>
      other is PlaneFrame && other.system == system && other.zone == zone && other.south == south;

  @override
  int get hashCode => Object.hash(system, zone, south);

  @override
  String toString() => 'PlaneFrame($system, $zone${south ? ', south' : ''})';
}
