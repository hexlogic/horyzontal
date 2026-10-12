import 'dart:math' as math;

import 'ellipsoid.dart';

/// Transverse Mercator projection with Krüger series to sixth order in the
/// third flattening, following C. F. F. Karney, "Transverse Mercator with an
/// accuracy of a few nanometers", J. Geodesy 85 (2011). Accurate to well under
/// a millimetre within several thousand kilometres of the central meridian.
class TransverseMercator {
  TransverseMercator(this.ellipsoid, {this.k0 = 1})
    : _alpha = _alphaFor(ellipsoid.n),
      _beta = _betaFor(ellipsoid.n),
      _a1 = _rectifyingRadius(ellipsoid);

  final Ellipsoid ellipsoid;
  final double k0;
  final List<double> _alpha, _beta;
  final double _a1;

  /// Projects geodetic [lat], [lon] (degrees) relative to central meridian
  /// [lon0]. Returns easting and northing without false offsets.
  TmPoint forward(double lat, double lon, double lon0) {
    final e = ellipsoid.e;
    final lam = _angleDiff(lon0, lon) * math.pi / 180;
    final phi = lat * math.pi / 180;

    final tau = math.tan(phi);
    final taup = _taupf(tau, e);
    final cosLam = math.cos(lam), sinLam = math.sin(lam);

    final xip = math.atan2(taup, cosLam);
    final etap = _asinh(sinLam / math.sqrt(taup * taup + cosLam * cosLam));

    var xi = xip, eta = etap;
    var p = 1.0, q = 0.0;
    for (var j = 1; j <= 6; j++) {
      final s = math.sin(2 * j * xip), c = math.cos(2 * j * xip);
      final sh = _sinh(2 * j * etap), ch = _cosh(2 * j * etap);
      xi += _alpha[j] * s * ch;
      eta += _alpha[j] * c * sh;
      p += 2 * j * _alpha[j] * c * ch;
      q += 2 * j * _alpha[j] * s * sh;
    }

    // Meridian convergence and point scale (Karney 2011, eqs. 12-13, 15).
    final gammaP = math.atan2(taup * sinLam, math.sqrt(1 + taup * taup) * cosLam);
    final gamma = gammaP + math.atan2(q, p);
    final kP =
        math.sqrt(1 - ellipsoid.e2 * math.pow(math.sin(phi), 2)) *
        math.sqrt(1 + tau * tau) /
        math.sqrt(taup * taup + cosLam * cosLam);
    final k = k0 * _a1 / ellipsoid.a * math.sqrt(p * p + q * q) * kP;

    return TmPoint(k0 * _a1 * eta, k0 * _a1 * xi, convergence: gamma * 180 / math.pi, scale: k);
  }

  /// Inverse of [forward]: easting [x], northing [y] (without false offsets)
  /// to geodetic latitude and longitude in degrees.
  (double lat, double lon) inverse(double x, double y, double lon0) {
    final xi = y / (k0 * _a1), eta = x / (k0 * _a1);
    var xip = xi, etap = eta;
    for (var j = 1; j <= 6; j++) {
      xip -= _beta[j] * math.sin(2 * j * xi) * _cosh(2 * j * eta);
      etap -= _beta[j] * math.cos(2 * j * xi) * _sinh(2 * j * eta);
    }
    final sinhEtap = _sinh(etap), cosXip = math.cos(xip);
    final taup = math.sin(xip) / math.sqrt(sinhEtap * sinhEtap + cosXip * cosXip);
    final lam = math.atan2(sinhEtap, cosXip);
    final tau = _tauf(taup, ellipsoid.e);
    final lat = math.atan(tau) * 180 / math.pi;
    var lon = lon0 + lam * 180 / math.pi;
    if (lon > 180) lon -= 360;
    if (lon <= -180) lon += 360;
    return (lat, lon);
  }

  static double _rectifyingRadius(Ellipsoid e) {
    final n = e.n, n2 = n * n;
    return e.a / (1 + n) * (1 + n2 * (1 / 4 + n2 * (1 / 64 + n2 / 256)));
  }

  static List<double> _alphaFor(double n) {
    final n2 = n * n, n3 = n2 * n, n4 = n3 * n, n5 = n4 * n, n6 = n5 * n;
    return [
      0,
      n / 2 - 2 * n2 / 3 + 5 * n3 / 16 + 41 * n4 / 180 - 127 * n5 / 288 + 7891 * n6 / 37800,
      13 * n2 / 48 - 3 * n3 / 5 + 557 * n4 / 1440 + 281 * n5 / 630 - 1983433 * n6 / 1935360,
      61 * n3 / 240 - 103 * n4 / 140 + 15061 * n5 / 26880 + 167603 * n6 / 181440,
      49561 * n4 / 161280 - 179 * n5 / 168 + 6601661 * n6 / 7257600,
      34729 * n5 / 80640 - 3418889 * n6 / 1995840,
      212378941 * n6 / 319334400,
    ];
  }

  static List<double> _betaFor(double n) {
    final n2 = n * n, n3 = n2 * n, n4 = n3 * n, n5 = n4 * n, n6 = n5 * n;
    return [
      0,
      n / 2 - 2 * n2 / 3 + 37 * n3 / 96 - n4 / 360 - 81 * n5 / 512 + 96199 * n6 / 604800,
      n2 / 48 + n3 / 15 - 437 * n4 / 1440 + 46 * n5 / 105 - 1118711 * n6 / 3870720,
      17 * n3 / 480 - 37 * n4 / 840 - 209 * n5 / 4480 + 5569 * n6 / 90720,
      4397 * n4 / 161280 - 11 * n5 / 504 - 830251 * n6 / 7257600,
      4583 * n5 / 161280 - 108847 * n6 / 3991680,
      20648693 * n6 / 638668800,
    ];
  }
}

/// Projected point: easting [x], northing [y] in metres, plus meridian
/// convergence (degrees, bearing of grid north clockwise from true north) and
/// point scale factor.
class TmPoint {
  const TmPoint(this.x, this.y, {this.convergence = 0, this.scale = 1});
  final double x, y, convergence, scale;
}

/// [b] - [a] in degrees, reduced to (-180, 180].
double _angleDiff(double a, double b) {
  var d = (b - a) % 360;
  if (d > 180) d -= 360;
  return d;
}

double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;
double _cosh(double x) => (math.exp(x) + math.exp(-x)) / 2;
double _asinh(double x) {
  final y = x.abs();
  final r = math.log(y + math.sqrt(y * y + 1));
  return x < 0 ? -r : r;
}

double _atanh(double x) => 0.5 * math.log((1 + x) / (1 - x));

/// Conformal latitude tangent from geodetic latitude tangent.
double _taupf(double tau, double e) {
  final tau1 = math.sqrt(1 + tau * tau);
  final sig = _sinh(e * _atanh(e * tau / tau1));
  return math.sqrt(1 + sig * sig) * tau - sig * tau1;
}

/// Inverse of [_taupf] by Newton's method.
double _tauf(double taup, double e) {
  final e2m = 1 - e * e;
  var tau = taup / e2m;
  for (var i = 0; i < 6; i++) {
    final taupa = _taupf(tau, e);
    final dtau =
        (taup - taupa) *
        (1 + e2m * tau * tau) /
        (e2m * math.sqrt(1 + tau * tau) * math.sqrt(1 + taupa * taupa));
    tau += dtau;
    if (dtau.abs() < 1e-15 * math.max(1, tau.abs())) break;
  }
  return tau;
}
