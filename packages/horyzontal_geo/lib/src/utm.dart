import 'datum.dart';
import 'ellipsoid.dart';
import 'transverse_mercator.dart';

/// UTM coordinates on WGS 84.
class UtmPoint {
  const UtmPoint(this.zone, this.band, this.easting, this.northing);

  final int zone;

  /// Latitude band letter C..X.
  final String band;
  final double easting, northing;

  bool get north => band.compareTo('N') >= 0;

  @override
  String toString() => 'UtmPoint($zone$band, $easting, $northing)';
}

const _bands = 'CDEFGHJKLMNPQRSTUVWX';
final _tm = TransverseMercator(Ellipsoid.wgs84, k0: 0.9996);

/// UTM latitude bands, 8° each from 80°S, band X is 12° tall (72°N..84°N).
String utmBand(double lat) {
  if (lat < -80 || lat > 84) {
    throw RangeError('UTM is defined for latitudes 80°S..84°N');
  }
  final i = ((lat + 80) / 8).floor();
  return _bands[i > 19 ? 19 : i];
}

/// Southern edge of band [band], degrees.
double utmBandSouth(String band) => _bands.indexOf(band) * 8.0 - 80;

int utmZone(double lat, double lon) {
  var l = (lon + 180) % 360 - 180;
  if (l == 180) l = -180;
  var zone = ((l + 180) / 6).floor() + 1;
  if (lat >= 56 && lat < 64 && l >= 3 && l < 12) zone = 32; // Norway
  if (lat >= 72 && lat < 84 && l >= 0 && l < 42) {
    // Svalbard
    zone = l < 9
        ? 31
        : l < 21
        ? 33
        : l < 33
        ? 35
        : 37;
  }
  return zone;
}

double utmCentralMeridian(int zone) => zone * 6.0 - 183;

UtmPoint utmFromWgs84(Geodetic g, {int? zone}) {
  final z = zone ?? utmZone(g.lat, g.lon);
  final p = _tm.forward(g.lat, g.lon, utmCentralMeridian(z));
  return UtmPoint(z, utmBand(g.lat), p.x + 500000, g.lat < 0 ? p.y + 10000000 : p.y);
}

/// Hemisphere comes from [UtmPoint.north].
Geodetic utmToWgs84(UtmPoint p) {
  final (lat, lon) = _tm.inverse(
    p.easting - 500000,
    p.north ? p.northing : p.northing - 10000000,
    utmCentralMeridian(p.zone),
  );
  return Geodetic(lat, lon);
}
