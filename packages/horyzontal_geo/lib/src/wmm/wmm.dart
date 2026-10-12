import 'dart:math' as math;

import '../ellipsoid.dart';
import 'wmm2025_coefficients.dart';

/// Geomagnetic field at a point, nanotesla, in the local geodetic frame:
/// [x] north, [y] east, [z] down.
class MagneticField {
  const MagneticField(this.x, this.y, this.z);
  final double x, y, z;

  /// Horizontal intensity.
  double get h => math.sqrt(x * x + y * y);

  /// Total intensity.
  double get f => math.sqrt(x * x + y * y + z * z);

  /// Inclination (dip), degrees, positive down.
  double get inclination => math.atan2(z, h) * 180 / math.pi;

  /// Declination, degrees, positive east of true north.
  double get declination => math.atan2(y, x) * 180 / math.pi;
}

/// World Magnetic Model (NOAA NCEI / BGS), spherical harmonics to degree 12,
/// as described in the WMM2025 technical report.
class Wmm {
  Wmm._(this.epoch, List<List<num>> rows) : _n = 12 {
    _g = List.generate(_n + 1, (_) => List.filled(_n + 1, 0.0));
    _h = List.generate(_n + 1, (_) => List.filled(_n + 1, 0.0));
    _gd = List.generate(_n + 1, (_) => List.filled(_n + 1, 0.0));
    _hd = List.generate(_n + 1, (_) => List.filled(_n + 1, 0.0));
    for (final r in rows) {
      final n = r[0].toInt(), m = r[1].toInt();
      _g[n][m] = r[2].toDouble();
      _h[n][m] = r[3].toDouble();
      _gd[n][m] = r[4].toDouble();
      _hd[n][m] = r[5].toDouble();
    }
    _schmidt = List.generate(_n + 1, (_) => List.filled(_n + 1, 0.0));
    _schmidt[0][0] = 1;
    for (var n = 1; n <= _n; n++) {
      _schmidt[n][0] = _schmidt[n - 1][0] * (2 * n - 1) / n;
      for (var m = 1; m <= n; m++) {
        _schmidt[n][m] = _schmidt[n][m - 1] * math.sqrt((n - m + 1) * (m == 1 ? 2 : 1) / (n + m));
      }
    }
  }

  static final wmm2025 = Wmm._(wmm2025Epoch, wmm2025Coefficients);

  /// Model epoch, decimal year. The model is valid for five years after it.
  final double epoch;
  final int _n;
  late final List<List<double>> _g, _h, _gd, _hd, _schmidt;

  static const _a = 6371200.0; // geomagnetic reference radius, m

  bool isValidAt(double year) => year >= epoch && year <= epoch + 5;

  /// Field at geodetic [lat], [lon] (degrees, WGS 84), [height] metres above
  /// the ellipsoid, at [year] (decimal year, see [decimalYear]).
  MagneticField at(double lat, double lon, double height, double year) {
    const e = Ellipsoid.wgs84;
    final phi = lat * math.pi / 180, lam = lon * math.pi / 180;
    final sinPhi = math.sin(phi), cosPhi = math.cos(phi);
    final rc = e.a / math.sqrt(1 - e.e2 * sinPhi * sinPhi);
    final p = (rc + height) * cosPhi;
    final zc = (rc * (1 - e.e2) + height) * sinPhi;
    final r = math.sqrt(p * p + zc * zc);
    final phiC = math.asin(zc / r); // geocentric latitude

    // Legendre functions of colatitude, Gauss-normalised, and d/dθ.
    final ct = math.sin(phiC), st = math.cos(phiC);
    final pn = List.generate(_n + 1, (_) => List.filled(_n + 1, 0.0));
    final dp = List.generate(_n + 1, (_) => List.filled(_n + 1, 0.0));
    pn[0][0] = 1;
    for (var n = 1; n <= _n; n++) {
      for (var m = 0; m <= n; m++) {
        if (n == m) {
          pn[n][m] = st * pn[n - 1][m - 1];
          dp[n][m] = ct * pn[n - 1][m - 1] + st * dp[n - 1][m - 1];
        } else if (n == 1) {
          pn[n][m] = ct * pn[n - 1][m];
          dp[n][m] = ct * dp[n - 1][m] - st * pn[n - 1][m];
        } else {
          final k = m > n - 2 ? 0.0 : ((n - 1) * (n - 1) - m * m) / ((2 * n - 1) * (2 * n - 3));
          final p2 = m > n - 2 ? 0.0 : pn[n - 2][m];
          final d2 = m > n - 2 ? 0.0 : dp[n - 2][m];
          pn[n][m] = ct * pn[n - 1][m] - k * p2;
          dp[n][m] = ct * dp[n - 1][m] - st * pn[n - 1][m] - k * d2;
        }
      }
    }

    final dt = year - epoch;
    var xs = 0.0, ys = 0.0, zs = 0.0;
    var ar = math.pow(_a / r, 2).toDouble();
    for (var n = 1; n <= _n; n++) {
      ar *= _a / r; // (a/r)^(n+2)
      for (var m = 0; m <= n; m++) {
        final g = _g[n][m] + dt * _gd[n][m];
        final h = _h[n][m] + dt * _hd[n][m];
        final s = _schmidt[n][m];
        final cm = math.cos(m * lam), sm = math.sin(m * lam);
        final gh = g * cm + h * sm;
        xs += ar * gh * s * dp[n][m];
        ys += ar * m * (g * sm - h * cm) * s * pn[n][m];
        zs -= ar * (n + 1) * gh * s * pn[n][m];
      }
    }
    // At the geographic poles Y' is 0/0; the field there is finite and the
    // tiny offset below keeps the formula usable.
    ys /= st.abs() < 1e-10 ? 1e-10 : st;

    // Rotate from geocentric to geodetic frame.
    final psi = phiC - phi;
    return MagneticField(
      xs * math.cos(psi) - zs * math.sin(psi),
      ys,
      xs * math.sin(psi) + zs * math.cos(psi),
    );
  }
}

/// Decimal year of [t] (UTC), e.g. 2025.5 for the start of 2 July 2025.
double decimalYear(DateTime t) {
  final u = t.toUtc();
  final start = DateTime.utc(u.year);
  final end = DateTime.utc(u.year + 1);
  return u.year + u.difference(start).inMicroseconds / end.difference(start).inMicroseconds;
}
