import 'dart:math' as math;

const _rad = math.pi / 180;

/// Julian day of a moment, UT (the [DateTime] is taken as UTC).
double julianDay(DateTime t) => 2440587.5 + t.toUtc().millisecondsSinceEpoch / 86400000;

/// The moment of Julian day [jd], UT.
DateTime fromJulianDay(double jd) =>
    DateTime.fromMillisecondsSinceEpoch(((jd - 2440587.5) * 86400000).round(), isUtc: true);

/// ΔT = TT − UT in seconds for a decimal [year]: the polynomials of Espenak
/// and Meeus (NASA, Five Millennium Canon of Solar Eclipses), valid from
/// −1999 to 3000, and the Morrison–Stephenson parabola outside them. The
/// uncertainty grows from about a second today to hours in antiquity, and
/// ΔT of the future is a forecast.
double deltaT(double year) {
  final y = year;
  double u;
  if (y < -500 || y >= 2150) {
    u = (y - 1820) / 100;
    return -20 + 32 * u * u;
  }
  if (y < 500) {
    u = y / 100;
    return _poly(u, const [10583.6, -1014.41, 33.78311, -5.952053, -0.1798452, 0.022174192, 0.0090316521]);
  }
  if (y < 1600) {
    u = (y - 1000) / 100;
    return _poly(u, const [1574.2, -556.01, 71.23472, 0.319781, -0.8503463, -0.005050998, 0.0083572073]);
  }
  if (y < 1700) return _poly(y - 1600, const [120, -0.9808, -0.01532, 1 / 7129]);
  if (y < 1800) return _poly(y - 1700, const [8.83, 0.1603, -0.0059285, 0.00013336, -1 / 1174000]);
  if (y < 1860) {
    return _poly(y - 1800, const [
      13.72, -0.332447, 0.0068612, 0.0041116, -0.00037436, 0.0000121272, -0.0000001699, 0.000000000875, //
    ]);
  }
  if (y < 1900) return _poly(y - 1860, const [7.62, 0.5737, -0.251754, 0.01680668, -0.0004473624, 1 / 233174]);
  if (y < 1920) return _poly(y - 1900, const [-2.79, 1.494119, -0.0598939, 0.0061966, -0.000197]);
  if (y < 1941) return _poly(y - 1920, const [21.20, 0.84493, -0.076100, 0.0020936]);
  if (y < 1961) return _poly(y - 1950, const [29.07, 0.407, -1 / 233, 1 / 2547]);
  if (y < 1986) return _poly(y - 1975, const [45.45, 1.067, -1 / 260, -1 / 718]);
  if (y < 2005) {
    return _poly(y - 2000, const [63.86, 0.3345, -0.060374, 0.0017275, 0.000651814, 0.00002373599]);
  }
  if (y < 2050) return _poly(y - 2000, const [62.92, 0.32217, 0.005589]);
  u = (y - 1820) / 100;
  return -20 + 32 * u * u - 0.5628 * (2150 - y);
}

double _poly(double x, List<double> c) {
  var r = 0.0;
  for (var i = c.length - 1; i >= 0; i--) {
    r = r * x + c[i];
  }
  return r;
}

/// Decimal year of Julian day [jd], close enough for ΔT.
double _yearOf(double jd) => 2000 + (jd - 2451545) / 365.25;

/// Julian ephemeris day (TT) for Julian day [jd] (UT).
double ephemerisDay(double jd) => jd + deltaT(_yearOf(jd)) / 86400;

/// Julian centuries of TT since J2000.0.
double centuries(double jde) => (jde - 2451545) / 36525;

/// Nutation in longitude and obliquity, degrees (Meeus ch. 22, the short
/// series, 0.5″ and 0.1″).
({double dPsi, double dEps}) nutation(double t) {
  final om = (125.04452 - 1934.136261 * t) * _rad;
  final l = (280.4665 + 36000.7698 * t) * _rad;
  final lm = (218.3165 + 481267.8813 * t) * _rad;
  final dPsi = -17.20 * math.sin(om) - 1.32 * math.sin(2 * l) - 0.23 * math.sin(2 * lm) + 0.21 * math.sin(2 * om);
  final dEps = 9.20 * math.cos(om) + 0.57 * math.cos(2 * l) + 0.10 * math.cos(2 * lm) - 0.09 * math.cos(2 * om);
  return (dPsi: dPsi / 3600, dEps: dEps / 3600);
}

/// Mean obliquity of the ecliptic, degrees (Meeus 22.2).
double meanObliquity(double t) =>
    23.4392911111 - (46.8150 * t + 0.00059 * t * t - 0.001813 * t * t * t) / 3600;

/// Apparent Greenwich sidereal time, degrees, for Julian day [jd] (UT)
/// (Meeus 12.4 plus the equation of the equinoxes).
double siderealTime(double jd, {required double dPsi, required double eps}) {
  final t = (jd - 2451545) / 36525;
  final mean = 280.46061837 + 360.98564736629 * (jd - 2451545) + 0.000387933 * t * t - t * t * t / 38710000;
  return _norm(mean + dPsi * math.cos(eps * _rad));
}

double _norm(double a) {
  final r = a % 360;
  return r < 0 ? r + 360 : r;
}
