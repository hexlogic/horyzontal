// Geodesics on an ellipsoid of revolution.
//
// A port of the Python GeographicLib (geodesic.py, geodesicline.py,
// geomath.py), copyright (c) Charles F. F. Karney (2011-2022), licensed under
// the MIT/X11 License (geographiclib.sourceforge.io)
//
// The algorithms are described in C. F. F. Karney, "Algorithms for geodesics",
// J. Geodesy 87, 43-55 (2013), doi:10.1007/s00190-012-0578-z

import 'dart:math' as math;

import 'datum.dart';
import 'ellipsoid.dart';

part 'polygon_area.dart';

/// Solution of the direct or inverse geodesic problem. Angles in degrees,
/// lengths in metres.
class GeodesicResult {
  const GeodesicResult({
    required this.lat1,
    required this.lon1,
    required this.azi1,
    required this.lat2,
    required this.lon2,
    required this.azi2,
    required this.s12,
    required this.a12,
    required this.m12,
    required this.area,
  });

  /// First point and the azimuth there (clockwise from north).
  final double lat1, lon1, azi1;

  /// Second point and the forward azimuth there. Longitudes are reduced to
  /// [-180, 180].
  final double lat2, lon2, azi2;

  /// Distance between the points, metres.
  final double s12;

  /// Arc length on the auxiliary sphere, degrees.
  final double a12;

  /// Reduced length, metres.
  final double m12;

  /// Area between the geodesic and the equator (S12), square metres.
  final double area;
}

/// Geodesic calculations on an ellipsoid, accurate to about 15 nm for the
/// Earth (Karney 2013). Series are carried to sixth order in the third
/// flattening, so |f| should stay below about 1/50.
class Geodesic {
  Geodesic(this.ellipsoid)
    : _a = ellipsoid.a,
      _f = ellipsoid.f,
      _f1 = 1 - ellipsoid.f,
      _e2 = ellipsoid.e2,
      _ep2 = ellipsoid.e2 / _sq(1 - ellipsoid.f),
      _n = ellipsoid.n,
      _b = ellipsoid.b,
      _c2 = _authalicRadius2(ellipsoid),
      _etol2 =
          0.1 *
          _tol2 /
          math.sqrt(math.max(0.001, ellipsoid.f.abs()) * math.min(1.0, 1 - ellipsoid.f / 2) / 2),
      _a3x = _a3coeff(ellipsoid.n),
      _c3x = _c3coeff(ellipsoid.n),
      _c4x = _c4coeff(ellipsoid.n);

  static final wgs84 = Geodesic(Ellipsoid.wgs84);

  final Ellipsoid ellipsoid;
  final double _a, _f, _f1, _e2, _ep2, _n, _b, _c2, _etol2;
  final List<double> _a3x, _c3x, _c4x;

  /// Solves the inverse problem: the shortest geodesic from (lat1, lon1) to
  /// (lat2, lon2), all in degrees.
  GeodesicResult inverse(double lat1, double lon1, double lat2, double lon2) {
    final lat1In = lat1, lat2In = lat2;
    // Longitude difference, positive, with its rounding error.
    var (lon12, lon12s) = _angDiff(lon1, lon2);
    var lonsign = _copysign(1, lon12);
    lon12 *= lonsign;
    lon12s *= lonsign;
    final lam12 = lon12 * _deg;
    final (slam12, clam12) = _sincosde(lon12, lon12s);
    lon12s = (180 - lon12) - lon12s; // supplementary longitude difference

    lat1 = _angRound(_latFix(lat1));
    lat2 = _angRound(_latFix(lat2));
    // Canonical form: 0 <= lon12 <= 180, -90 <= lat1 <= 0, lat1 <= lat2 <= -lat1.
    final swapp = lat1.abs() < lat2.abs() || lat2.isNaN ? -1.0 : 1.0;
    if (swapp < 0) {
      lonsign *= -1;
      (lat1, lat2) = (lat2, lat1);
    }
    final latsign = _copysign(1, -lat1);
    lat1 *= latsign;
    lat2 *= latsign;

    var (sbet1, cbet1) = _sincosd(lat1);
    (sbet1, cbet1) = _norm(sbet1 * _f1, cbet1);
    cbet1 = math.max(_tiny, cbet1);
    var (sbet2, cbet2) = _sincosd(lat2);
    (sbet2, cbet2) = _norm(sbet2 * _f1, cbet2);
    cbet2 = math.max(_tiny, cbet2);

    // Force bet2 = +/- bet1 exactly when the sensitive measure vanishes.
    if (cbet1 < -sbet1) {
      if (cbet2 == cbet1) sbet2 = _copysign(sbet1, sbet2);
    } else if (sbet2.abs() == -sbet1) {
      cbet2 = cbet1;
    }

    final dn1 = math.sqrt(1 + _ep2 * _sq(sbet1));
    final dn2 = math.sqrt(1 + _ep2 * _sq(sbet2));

    final c1a = List<double>.filled(_order + 1, 0);
    final c2a = List<double>.filled(_order + 1, 0);
    final c3a = List<double>.filled(_order, 0);

    var a12 = double.nan, s12x = double.nan, m12x = double.nan;
    var sig12 = 0.0, salp1 = 0.0, calp1 = 0.0, salp2 = 0.0, calp2 = 0.0;
    var meridian = lat1 == -90 || slam12 == 0;

    if (meridian) {
      // Endpoints on a single full meridian; the geodesic may follow it.
      calp1 = clam12;
      salp1 = slam12;
      calp2 = 1;
      salp2 = 0;
      final ssig1 = sbet1, csig1 = calp1 * cbet1;
      final ssig2 = sbet2, csig2 = calp2 * cbet2;
      sig12 = math.atan2(
        math.max(0.0, csig1 * ssig2 - ssig1 * csig2) + 0.0,
        csig1 * csig2 + ssig1 * ssig2,
      );
      (s12x, m12x, _) = _lengths(_n, sig12, ssig1, csig1, dn1, ssig2, csig2, dn2, c1a, c2a);
      // sig12 > pi/2 on a meridian is not a shortest path unless m12 >= 0.
      if (sig12 < _tol2 || m12x >= 0) {
        if (sig12 < 3 * _tiny || (sig12 < _tol0 && (s12x < 0 || m12x < 0))) {
          sig12 = m12x = s12x = 0.0;
        }
        m12x *= _b;
        s12x *= _b;
        a12 = sig12 * _rad;
      } else {
        meridian = false; // prolate and too close to antipodal
      }
    }

    // somg12 == 2 marks that it still needs to be computed.
    var somg12 = 2.0, comg12 = 0.0, omg12 = 0.0;
    if (!meridian && sbet1 == 0 && (_f <= 0 || lon12s >= _f * 180)) {
      // Geodesic runs along the equator.
      calp1 = calp2 = 0.0;
      salp1 = salp2 = 1.0;
      s12x = _a * lam12;
      sig12 = omg12 = lam12 / _f1;
      m12x = _b * math.sin(sig12);
      a12 = lon12 / _f1;
    } else if (!meridian) {
      // Neither meridional nor equatorial.
      final double dnm;
      (sig12, salp1, calp1, salp2, calp2, dnm) = _inverseStart(
        sbet1,
        cbet1,
        dn1,
        sbet2,
        cbet2,
        dn2,
        lam12,
        slam12,
        clam12,
        c1a,
        c2a,
      );

      if (sig12 >= 0) {
        // Short line; the start already gave the solution.
        s12x = sig12 * _b * dnm;
        m12x = _sq(dnm) * _b * math.sin(sig12 / dnm);
        a12 = sig12 * _rad;
        omg12 = lam12 / (_f1 * dnm);
      } else {
        // Newton's method on lambda12(alp1) - lam12 = 0, with a bracketing
        // fallback to bisection when a step would leave (0, pi).
        var ssig1 = 0.0, csig1 = 0.0, ssig2 = 0.0, csig2 = 0.0, eps = 0.0, domg12 = 0.0;
        var numit = 0;
        var tripn = false, tripb = false;
        var salp1a = _tiny, calp1a = 1.0, salp1b = _tiny, calp1b = -1.0;
        while (true) {
          final double v, dv;
          (v, salp2, calp2, sig12, ssig1, csig1, ssig2, csig2, eps, domg12, dv) = _lambda12(
            sbet1,
            cbet1,
            dn1,
            sbet2,
            cbet2,
            dn2,
            salp1,
            calp1,
            slam12,
            clam12,
            numit < _maxit1,
            c1a,
            c2a,
            c3a,
          );
          // Reversed test to allow escape with NaNs.
          if (tripb || !(v.abs() >= (tripn ? 8 : 1) * _tol0) || numit == _maxit2) {
            break;
          }
          if (v > 0 && (numit > _maxit1 || calp1 / salp1 > calp1b / salp1b)) {
            salp1b = salp1;
            calp1b = calp1;
          } else if (v < 0 && (numit > _maxit1 || calp1 / salp1 < calp1a / salp1a)) {
            salp1a = salp1;
            calp1a = calp1;
          }
          numit++;
          if (numit < _maxit1 && dv > 0) {
            final dalp1 = -v / dv;
            if (dalp1.abs() < math.pi) {
              final sdalp1 = math.sin(dalp1), cdalp1 = math.cos(dalp1);
              final nsalp1 = salp1 * cdalp1 + calp1 * sdalp1;
              if (nsalp1 > 0) {
                calp1 = calp1 * cdalp1 - salp1 * sdalp1;
                (salp1, calp1) = _norm(nsalp1, calp1);
                // Slope may vanish; then converge on epsilon, not sqrt(epsilon).
                tripn = v.abs() <= 16 * _tol0;
                continue;
              }
            }
          }
          // Bisect the bracket.
          (salp1, calp1) = _norm((salp1a + salp1b) / 2, (calp1a + calp1b) / 2);
          tripn = false;
          tripb =
              (salp1a - salp1).abs() + (calp1a - calp1) < _tolb ||
              (salp1 - salp1b).abs() + (calp1 - calp1b) < _tolb;
        }
        (s12x, m12x, _) = _lengths(eps, sig12, ssig1, csig1, dn1, ssig2, csig2, dn2, c1a, c2a);
        m12x *= _b;
        s12x *= _b;
        a12 = sig12 * _rad;
        // omg12 = lam12 - domg12
        final sdomg12 = math.sin(domg12), cdomg12 = math.cos(domg12);
        somg12 = slam12 * cdomg12 - clam12 * sdomg12;
        comg12 = clam12 * cdomg12 + slam12 * sdomg12;
      }
    }

    final s12 = 0.0 + s12x, m12 = 0.0 + m12x; // -0 to 0

    // Area.
    final salp0 = salp1 * cbet1, calp0 = _hypot(calp1, salp1 * sbet1);
    var area = 0.0;
    if (calp0 != 0 && salp0 != 0) {
      final (ssig1, csig1) = _norm(sbet1, calp1 * cbet1);
      final (ssig2, csig2) = _norm(sbet2, calp2 * cbet2);
      final k2 = _sq(calp0) * _ep2;
      final eps = k2 / (2 * (1 + math.sqrt(1 + k2)) + k2);
      final a4 = _sq(_a) * calp0 * salp0 * _e2;
      final c4a = List<double>.filled(_order, 0);
      _c4f(eps, c4a);
      area =
          a4 * (_sinCosSeries(false, ssig2, csig2, c4a) - _sinCosSeries(false, ssig1, csig1, c4a));
    }
    if (!meridian && somg12 == 2) {
      somg12 = math.sin(omg12);
      comg12 = math.cos(omg12);
    }
    final double alp12;
    if (!meridian && comg12 > -0.7071 && sbet2 - sbet1 < 1.75) {
      // tan(Gamma/2) = tan(omg12/2) * (tan(bet1/2) + tan(bet2/2)) /
      //   (1 + tan(bet1/2) * tan(bet2/2))
      final domg12 = 1 + comg12, dbet1 = 1 + cbet1, dbet2 = 1 + cbet2;
      alp12 =
          2 *
          math.atan2(
            somg12 * (sbet1 * dbet2 + sbet2 * dbet1),
            domg12 * (sbet1 * sbet2 + dbet1 * dbet2),
          );
    } else {
      var salp12 = salp2 * calp1 - calp2 * salp1;
      var calp12 = calp2 * calp1 + salp2 * salp1;
      if (salp12 == 0 && calp12 < 0) {
        salp12 = _tiny * calp1;
        calp12 = -1.0;
      }
      alp12 = math.atan2(salp12, calp12);
    }
    area = (area + _c2 * alp12) * swapp * lonsign * latsign + 0.0;

    // Undo the canonical transformation.
    if (swapp < 0) {
      (salp1, salp2) = (salp2, salp1);
      (calp1, calp2) = (calp2, calp1);
    }
    salp1 *= swapp * lonsign;
    calp1 *= swapp * latsign;
    salp2 *= swapp * lonsign;
    calp2 *= swapp * latsign;

    return GeodesicResult(
      lat1: _latFix(lat1In),
      lon1: _angNormalize(lon1),
      azi1: _atan2d(salp1, calp1),
      lat2: _latFix(lat2In),
      lon2: _angNormalize(lon2),
      azi2: _atan2d(salp2, calp2),
      s12: s12,
      a12: a12,
      m12: m12,
      area: area,
    );
  }

  /// Solves the direct problem: the point reached from (lat1, lon1) by
  /// travelling [s12] metres with initial azimuth [azi1] (degrees).
  GeodesicResult direct(double lat1, double lon1, double azi1, double s12) {
    // Line setup (GeodesicLine constructor).
    lat1 = _latFix(lat1);
    final (salp1, calp1) = _sincosd(_angRound(azi1));
    var (sbet1, cbet1) = _sincosd(_angRound(lat1));
    (sbet1, cbet1) = _norm(sbet1 * _f1, cbet1);
    cbet1 = math.max(_tiny, cbet1);
    final dn1 = math.sqrt(1 + _ep2 * _sq(sbet1));
    final salp0 = salp1 * cbet1; // alp0 in [0, pi/2 - |bet1|]
    final calp0 = _hypot(calp1, salp1 * sbet1);
    final somg1 = salp0 * sbet1;
    final comg1 = sbet1 != 0 || calp1 != 0 ? cbet1 * calp1 : 1.0;
    final (ssig1, csig1) = _norm(sbet1, comg1);
    final k2 = _sq(calp0) * _ep2;
    final eps = k2 / (2 * (1 + math.sqrt(1 + k2)) + k2);

    final a1m1 = _a1m1f(eps);
    final c1a = List<double>.filled(_order + 1, 0);
    _c1f(eps, c1a);
    final b11 = _sinCosSeries(true, ssig1, csig1, c1a);
    final stau1 = ssig1 * math.cos(b11) + csig1 * math.sin(b11);
    final ctau1 = csig1 * math.cos(b11) - ssig1 * math.sin(b11);
    final c1pa = List<double>.filled(_order + 1, 0);
    _c1pf(eps, c1pa);
    final a2m1 = _a2m1f(eps);
    final c2a = List<double>.filled(_order + 1, 0);
    _c2f(eps, c2a);
    final b21 = _sinCosSeries(true, ssig1, csig1, c2a);
    final c3a = List<double>.filled(_order, 0);
    _c3f(eps, c3a);
    final a3c = -_f * salp0 * _a3f(eps);
    final b31 = _sinCosSeries(true, ssig1, csig1, c3a);
    final c4a = List<double>.filled(_order, 0);
    _c4f(eps, c4a);
    final a4 = _sq(_a) * calp0 * salp0 * _e2;
    final b41 = _sinCosSeries(false, ssig1, csig1, c4a);

    // Position at distance s12 (GeodesicLine._GenPosition).
    var tau12 = s12 / (_b * (1 + a1m1));
    if (!tau12.isFinite) tau12 = double.nan;
    final s = math.sin(tau12), c = math.cos(tau12);
    var b12 = -_sinCosSeries(true, stau1 * c + ctau1 * s, ctau1 * c - stau1 * s, c1pa);
    var sig12 = tau12 - (b12 - b11);
    var ssig12 = math.sin(sig12), csig12 = math.cos(sig12);
    if (_f.abs() > 0.01) {
      // Reverted distance series is inaccurate; take one Newton step.
      final ssig2 = ssig1 * csig12 + csig1 * ssig12;
      final csig2 = csig1 * csig12 - ssig1 * ssig12;
      b12 = _sinCosSeries(true, ssig2, csig2, c1a);
      final serr = (1 + a1m1) * (sig12 + (b12 - b11)) - s12 / _b;
      sig12 = sig12 - serr / math.sqrt(1 + k2 * _sq(ssig2));
      ssig12 = math.sin(sig12);
      csig12 = math.cos(sig12);
    }
    final ssig2 = ssig1 * csig12 + csig1 * ssig12;
    var csig2 = csig1 * csig12 - ssig1 * ssig12;
    final dn2 = math.sqrt(1 + k2 * _sq(ssig2));
    if (_f.abs() > 0.01) b12 = _sinCosSeries(true, ssig2, csig2, c1a);
    final ab1 = (1 + a1m1) * (b12 - b11);
    final sbet2 = calp0 * ssig2;
    var cbet2 = _hypot(salp0, calp0 * csig2);
    if (cbet2 == 0) cbet2 = csig2 = _tiny; // point 2 is a pole
    final salp2 = salp0, calp2 = calp0 * csig2; // no need to normalize

    final somg2 = salp0 * ssig2, comg2 = csig2;
    final omg12 = math.atan2(somg2 * comg1 - comg2 * somg1, comg2 * comg1 + somg2 * somg1);
    final lam12 = omg12 + a3c * (sig12 + (_sinCosSeries(true, ssig2, csig2, c3a) - b31));
    final lon12 = lam12 * _rad;

    final ab2 = (1 + a2m1) * (_sinCosSeries(true, ssig2, csig2, c2a) - b21);
    final j12 = (a1m1 - a2m1) * sig12 + (ab1 - ab2);
    final m12 = _b * ((dn2 * (csig1 * ssig2) - dn1 * (ssig1 * csig2)) - csig1 * csig2 * j12);

    final b42 = _sinCosSeries(false, ssig2, csig2, c4a);
    final double salp12, calp12;
    if (calp0 == 0 || salp0 == 0) {
      salp12 = salp2 * calp1 - calp2 * salp1;
      calp12 = calp2 * calp1 + salp2 * salp1;
    } else {
      salp12 =
          calp0 *
          salp0 *
          (csig12 <= 0
              ? csig1 * (1 - csig12) + ssig12 * ssig1
              : ssig12 * (csig1 * ssig12 / (1 + csig12) + ssig1));
      calp12 = _sq(salp0) + _sq(calp0) * csig1 * csig2;
    }

    return GeodesicResult(
      lat1: lat1,
      lon1: _angNormalize(lon1),
      azi1: _angNormalize(azi1),
      lat2: _atan2d(sbet2, _f1 * cbet2),
      lon2: _angNormalize(_angNormalize(lon1) + _angNormalize(lon12)),
      azi2: _atan2d(salp2, calp2),
      s12: s12,
      a12: sig12 * _rad,
      m12: m12,
      area: _c2 * math.atan2(salp12, calp12) + a4 * (b42 - b41),
    );
  }

  /// Returns (s12/b, m12/b, m0) where m0 is the coefficient of the secular
  /// term of the reduced length. With [distance] false only m12b and m0 are
  /// valid. Overwrites [c1a] and [c2a].
  (double, double, double) _lengths(
    double eps,
    double sig12,
    double ssig1,
    double csig1,
    double dn1,
    double ssig2,
    double csig2,
    double dn2,
    List<double> c1a,
    List<double> c2a, {
    bool distance = true,
  }) {
    var a1 = _a1m1f(eps);
    _c1f(eps, c1a);
    var a2 = _a2m1f(eps);
    _c2f(eps, c2a);
    final m0x = a1 - a2;
    a2 = 1 + a2;
    a1 = 1 + a1;
    var s12b = double.nan;
    final double j12;
    if (distance) {
      final b1 = _sinCosSeries(true, ssig2, csig2, c1a) - _sinCosSeries(true, ssig1, csig1, c1a);
      s12b = a1 * (sig12 + b1);
      final b2 = _sinCosSeries(true, ssig2, csig2, c2a) - _sinCosSeries(true, ssig1, csig1, c2a);
      j12 = m0x * sig12 + (a1 * b1 - a2 * b2);
    } else {
      for (var l = 1; l <= _order; l++) {
        c2a[l] = a1 * c1a[l] - a2 * c2a[l];
      }
      j12 =
          m0x * sig12 +
          (_sinCosSeries(true, ssig2, csig2, c2a) - _sinCosSeries(true, ssig1, csig1, c2a));
    }
    // Parentheses ensure accurate cancellation for coincident points.
    final m12b = dn2 * (csig1 * ssig2) - dn1 * (ssig1 * csig2) - csig1 * csig2 * j12;
    return (s12b, m12b, m0x);
  }

  /// Starting guess for Newton's method in the inverse problem. Returns
  /// (sig12, salp1, calp1, salp2, calp2, dnm); sig12 >= 0 (with salp2, calp2,
  /// dnm) only when the line is short enough to need no iteration.
  (double, double, double, double, double, double) _inverseStart(
    double sbet1,
    double cbet1,
    double dn1,
    double sbet2,
    double cbet2,
    double dn2,
    double lam12,
    double slam12,
    double clam12,
    List<double> c1a,
    List<double> c2a,
  ) {
    var sig12 = -1.0, salp2 = double.nan, calp2 = double.nan, dnm = double.nan;
    // bet12 = bet2 - bet1 in [0, pi); bet12a = bet2 + bet1 in (-pi, 0]
    final sbet12 = sbet2 * cbet1 - cbet2 * sbet1;
    final cbet12 = cbet2 * cbet1 + sbet2 * sbet1;
    final sbet12a = sbet2 * cbet1 + cbet2 * sbet1;

    final shortline = cbet12 >= 0 && sbet12 < 0.5 && cbet2 * lam12 < 0.5;
    double somg12, comg12;
    if (shortline) {
      var sbetm2 = _sq(sbet1 + sbet2);
      sbetm2 /= sbetm2 + _sq(cbet1 + cbet2); // sin((bet1 + bet2) / 2)^2
      dnm = math.sqrt(1 + _ep2 * sbetm2);
      final omg12 = lam12 / (_f1 * dnm);
      somg12 = math.sin(omg12);
      comg12 = math.cos(omg12);
    } else {
      somg12 = slam12;
      comg12 = clam12;
    }

    var salp1 = cbet2 * somg12;
    var calp1 = comg12 >= 0
        ? sbet12 + cbet2 * sbet1 * _sq(somg12) / (1 + comg12)
        : sbet12a - cbet2 * sbet1 * _sq(somg12) / (1 - comg12);

    final ssig12 = _hypot(salp1, calp1);
    final csig12 = sbet1 * sbet2 + cbet1 * cbet2 * comg12;

    if (shortline && ssig12 < _etol2) {
      // Really short line.
      salp2 = cbet1 * somg12;
      calp2 = sbet12 - cbet1 * sbet2 * (comg12 >= 0 ? _sq(somg12) / (1 + comg12) : 1 - comg12);
      (salp2, calp2) = _norm(salp2, calp2);
      sig12 = math.atan2(ssig12, csig12);
    } else if (_n.abs() >= 0.1 || csig12 >= 0 || ssig12 >= 6 * _n.abs() * math.pi * _sq(cbet1)) {
      // Zeroth-order spherical approximation is fine.
    } else {
      // Nearly antipodal: scale to coordinates where the antipode is at the
      // origin and the singular point at y = 0, x = -1.
      final lam12x = math.atan2(-slam12, -clam12);
      final double x, y, lamscale, betscale;
      if (_f >= 0) {
        // x = dlong, y = dlat
        final k2 = _sq(sbet1) * _ep2;
        final eps = k2 / (2 * (1 + math.sqrt(1 + k2)) + k2);
        lamscale = _f * cbet1 * _a3f(eps) * math.pi;
        betscale = lamscale * cbet1;
        x = lam12x / lamscale;
        y = sbet12a / betscale;
      } else {
        // x = dlat, y = dlong
        final cbet12a = cbet2 * cbet1 - sbet2 * sbet1;
        final bet12a = math.atan2(sbet12a, cbet12a);
        final (_, m12b, m0) = _lengths(
          _n,
          math.pi + bet12a,
          sbet1,
          -cbet1,
          dn1,
          sbet2,
          cbet2,
          dn2,
          c1a,
          c2a,
          distance: false,
        );
        x = -1 + m12b / (cbet1 * cbet2 * m0 * math.pi);
        betscale = x < -0.01 ? sbet12a / x : -_f * _sq(cbet1) * math.pi;
        lamscale = betscale / cbet1;
        y = lam12x / lamscale;
      }

      if (y > -_tol1 && x > -1 - _xthresh) {
        // Strip near the cut.
        if (_f >= 0) {
          salp1 = math.min(1.0, -x);
          calp1 = -math.sqrt(1 - _sq(salp1));
        } else {
          calp1 = math.max(x > -_tol1 ? 0.0 : -1.0, x);
          salp1 = math.sqrt(1 - _sq(calp1));
        }
      } else {
        // Estimate omg12 from the astroid problem, then alp1 spherically.
        final k = _astroid(x, y);
        final omg12a = lamscale * (_f >= 0 ? -x * k / (1 + k) : -y * (1 + k) / k);
        somg12 = math.sin(omg12a);
        comg12 = -math.cos(omg12a);
        salp1 = cbet2 * somg12;
        calp1 = sbet12a - cbet2 * sbet1 * _sq(somg12) / (1 - comg12);
      }
    }
    // Sanity check on the starting guess; the backwards test lets NaN through.
    if (!(salp1 <= 0)) {
      (salp1, calp1) = _norm(salp1, calp1);
    } else {
      salp1 = 1;
      calp1 = 0;
    }
    return (sig12, salp1, calp1, salp2, calp2, dnm);
  }

  /// Solves the hybrid problem: given alp1, the longitude difference lam12
  /// minus the target (slam120, clam120). Returns (lam12 error, salp2, calp2,
  /// sig12, ssig1, csig1, ssig2, csig2, eps, domg12, dlam12/dalp1).
  (double, double, double, double, double, double, double, double, double, double, double)
  _lambda12(
    double sbet1,
    double cbet1,
    double dn1,
    double sbet2,
    double cbet2,
    double dn2,
    double salp1,
    double calp1,
    double slam120,
    double clam120,
    bool diffp,
    List<double> c1a,
    List<double> c2a,
    List<double> c3a,
  ) {
    // Break the degeneracy of the equatorial line.
    if (sbet1 == 0 && calp1 == 0) calp1 = -_tiny;

    final salp0 = salp1 * cbet1; // sin(alp1) * cos(bet1) = sin(alp0)
    final calp0 = _hypot(calp1, salp1 * sbet1); // > 0

    // tan(bet1) = tan(sig1) * cos(alp1); tan(omg1) = sin(alp0) * tan(sig1)
    final somg1 = salp0 * sbet1, comg1 = calp1 * cbet1;
    final (ssig1, csig1) = _norm(sbet1, comg1);

    // Enforce symmetries when |bet2| = -bet1.
    final salp2 = cbet2 != cbet1 ? salp0 / cbet2 : salp1;
    final calp2 = cbet2 != cbet1 || sbet2.abs() != -sbet1
        ? math.sqrt(
                _sq(calp1 * cbet1) +
                    (cbet1 < -sbet1
                        ? (cbet2 - cbet1) * (cbet1 + cbet2)
                        : (sbet1 - sbet2) * (sbet1 + sbet2)),
              ) /
              cbet2
        : calp1.abs();
    final somg2 = salp0 * sbet2, comg2 = calp2 * cbet2;
    final (ssig2, csig2) = _norm(sbet2, comg2);

    // sig12 = sig2 - sig1 and omg12 = omg2 - omg1, limited to [0, pi].
    final sig12 = math.atan2(
      math.max(0.0, csig1 * ssig2 - ssig1 * csig2) + 0.0,
      csig1 * csig2 + ssig1 * ssig2,
    );
    final somg12 = math.max(0.0, comg1 * somg2 - somg1 * comg2) + 0.0;
    final comg12 = comg1 * comg2 + somg1 * somg2;
    // eta = omg12 - lam120
    final eta = math.atan2(
      somg12 * clam120 - comg12 * slam120,
      comg12 * clam120 + somg12 * slam120,
    );

    final k2 = _sq(calp0) * _ep2;
    final eps = k2 / (2 * (1 + math.sqrt(1 + k2)) + k2);
    _c3f(eps, c3a);
    final b312 = _sinCosSeries(true, ssig2, csig2, c3a) - _sinCosSeries(true, ssig1, csig1, c3a);
    final domg12 = -_f * _a3f(eps) * salp0 * (sig12 + b312);
    final lam12 = eta + domg12;

    var dlam12 = double.nan;
    if (diffp) {
      if (calp2 == 0) {
        dlam12 = -2 * _f1 * dn1 / sbet1;
      } else {
        final (_, m12b, _) = _lengths(
          eps,
          sig12,
          ssig1,
          csig1,
          dn1,
          ssig2,
          csig2,
          dn2,
          c1a,
          c2a,
          distance: false,
        );
        dlam12 = m12b * _f1 / (calp2 * cbet2);
      }
    }
    return (lam12, salp2, calp2, sig12, ssig1, csig1, ssig2, csig2, eps, domg12, dlam12);
  }

  double _a3f(double eps) => _polyval(_order - 1, _a3x, 0, eps);

  /// Sets c[1] .. c[5].
  void _c3f(double eps, List<double> c) {
    var mult = 1.0;
    var o = 0;
    for (var l = 1; l < _order; l++) {
      final m = _order - l - 1;
      mult *= eps;
      c[l] = mult * _polyval(m, _c3x, o, eps);
      o += m + 1;
    }
  }

  /// Sets c[0] .. c[5].
  void _c4f(double eps, List<double> c) {
    var mult = 1.0;
    var o = 0;
    for (var l = 0; l < _order; l++) {
      final m = _order - l - 1;
      c[l] = mult * _polyval(m, _c4x, o, eps);
      o += m + 1;
      mult *= eps;
    }
  }

  static double _authalicRadius2(Ellipsoid e) {
    final e2 = e.e2, b = e.b;
    final double t;
    if (e2 == 0) {
      t = 1;
    } else if (e2 > 0) {
      final x = math.sqrt(e2);
      t = 0.5 * math.log((1 + x) / (1 - x)) / x; // atanh(x) / x
    } else {
      t = math.atan(math.sqrt(-e2)) / math.sqrt(-e2);
    }
    return (_sq(e.a) + _sq(b) * t) / 2;
  }

  static List<double> _a3coeff(double n) {
    const coeff = <double>[
      -3, 128, //
      -2, -3, 64,
      -1, -3, -1, 16,
      3, -1, -2, 8,
      1, -1, 2,
      1, 1,
    ];
    final r = <double>[];
    var o = 0;
    for (var j = _order - 1; j >= 0; j--) {
      final m = math.min(_order - j - 1, j);
      r.add(_polyval(m, coeff, o, n) / coeff[o + m + 1]);
      o += m + 2;
    }
    return r;
  }

  static List<double> _c3coeff(double n) {
    const coeff = <double>[
      3, 128, //
      2, 5, 128,
      -1, 3, 3, 64,
      -1, 0, 1, 8,
      -1, 1, 4,
      5, 256,
      1, 3, 128,
      -3, -2, 3, 64,
      1, -3, 2, 32,
      7, 512,
      -10, 9, 384,
      5, -9, 5, 192,
      7, 512,
      -14, 7, 512,
      21, 2560,
    ];
    final r = <double>[];
    var o = 0;
    for (var l = 1; l < _order; l++) {
      for (var j = _order - 1; j >= l; j--) {
        final m = math.min(_order - j - 1, j);
        r.add(_polyval(m, coeff, o, n) / coeff[o + m + 1]);
        o += m + 2;
      }
    }
    return r;
  }

  static List<double> _c4coeff(double n) {
    const coeff = <double>[
      97, 15015, //
      1088, 156, 45045,
      -224, -4784, 1573, 45045,
      -10656, 14144, -4576, -858, 45045,
      64, 624, -4576, 6864, -3003, 15015,
      100, 208, 572, 3432, -12012, 30030, 45045,
      1, 9009,
      -2944, 468, 135135,
      5792, 1040, -1287, 135135,
      5952, -11648, 9152, -2574, 135135,
      -64, -624, 4576, -6864, 3003, 135135,
      8, 10725,
      1856, -936, 225225,
      -8448, 4992, -1144, 225225,
      -1440, 4160, -4576, 1716, 225225,
      -136, 63063,
      1024, -208, 105105,
      3584, -3328, 1144, 315315,
      -128, 135135,
      -2560, 832, 405405,
      128, 99099,
    ];
    final r = <double>[];
    var o = 0;
    for (var l = 0; l < _order; l++) {
      for (var j = _order - 1; j >= l; j--) {
        final m = _order - j - 1;
        r.add(_polyval(m, coeff, o, n) / coeff[o + m + 1]);
        o += m + 2;
      }
    }
    return r;
  }
}

// Order of the series in the third flattening and iteration limits.
const _order = 6;
const _maxit1 = 20;
const _maxit2 = _maxit1 + 53 + 10;

const _tol0 = 2.220446049250313e-16; // machine epsilon
const _tol1 = 200 * _tol0;
final _tol2 = math.sqrt(_tol0);
const _tolb = _tol0;
final _xthresh = 1000 * _tol2;
final _tiny = math.sqrt(2.2250738585072014e-308); // sqrt of the smallest normal

const _deg = math.pi / 180;
const _rad = 180 / math.pi;

/// A1 - 1, the distance scale factor.
double _a1m1f(double eps) {
  const coeff = <double>[1, 4, 64, 0, 256];
  final t = _polyval(_order ~/ 2, coeff, 0, _sq(eps)) / coeff[_order ~/ 2 + 1];
  return (t + eps) / (1 - eps);
}

/// A2 - 1, for the reduced length.
double _a2m1f(double eps) {
  const coeff = <double>[-11, -28, -192, 0, 256];
  final t = _polyval(_order ~/ 2, coeff, 0, _sq(eps)) / coeff[_order ~/ 2 + 1];
  return (t - eps) / (1 + eps);
}

/// Sets c[1] .. c[6] of a series in eps from packed [coeff].
void _seriesf(List<double> coeff, double eps, List<double> c) {
  final eps2 = _sq(eps);
  var d = eps;
  var o = 0;
  for (var l = 1; l <= _order; l++) {
    final m = (_order - l) ~/ 2;
    c[l] = d * _polyval(m, coeff, o, eps2) / coeff[o + m + 1];
    o += m + 2;
    d *= eps;
  }
}

void _c1f(double eps, List<double> c) => _seriesf(
  const [
    -1, 6, -16, 32, //
    -9, 64, -128, 2048,
    9, -16, 768,
    3, -5, 512,
    -7, 1280,
    -7, 2048,
  ],
  eps,
  c,
);

void _c1pf(double eps, List<double> c) => _seriesf(
  const [
    205, -432, 768, 1536, //
    4005, -4736, 3840, 12288,
    -225, 116, 384,
    -7173, 2695, 7680,
    3467, 7680,
    38081, 61440,
  ],
  eps,
  c,
);

void _c2f(double eps, List<double> c) => _seriesf(
  const [
    1, 2, 16, 32, //
    35, 64, 384, 2048,
    15, 80, 768,
    7, 35, 512,
    63, 1280,
    77, 2048,
  ],
  eps,
  c,
);

/// Clenshaw sum of c[i] sin(2 i x), i = 1..n (when [sinp]) or
/// c[i] cos((2 i + 1) x), i = 0..n-1.
double _sinCosSeries(bool sinp, double sinx, double cosx, List<double> c) {
  var k = c.length;
  var n = k - (sinp ? 1 : 0);
  final ar = 2 * (cosx - sinx) * (cosx + sinx); // 2 cos(2x)
  var y0 = 0.0, y1 = 0.0;
  if (n.isOdd) y0 = c[--k];
  n ~/= 2;
  while (n-- > 0) {
    y1 = ar * y0 - y1 + c[--k];
    y0 = ar * y1 - y0 + c[--k];
  }
  return sinp ? 2 * sinx * cosx * y0 : cosx * (y0 - y1);
}

/// Positive root k of k^4 + 2k^3 - (x^2 + y^2 - 1)k^2 - 2y^2 k - y^2 = 0.
double _astroid(double x, double y) {
  final p = _sq(x), q = _sq(y);
  final r = (p + q - 1) / 6;
  if (q == 0 && r <= 0) return 0;
  final s = p * q / 4; // r^3 * s
  final r2 = _sq(r), r3 = r * r2;
  // Discriminant of the quadratic for T3; zero on the evolute.
  final disc = s * (s + 2 * r3);
  var u = r;
  if (disc >= 0) {
    var t3 = s + r3;
    t3 += t3 < 0 ? -math.sqrt(disc) : math.sqrt(disc); // (r t)^3, avoid cancellation
    final t = _cbrt(t3);
    u += t + (t != 0 ? r2 / t : 0);
  } else {
    final ang = math.atan2(math.sqrt(-disc), -(s + r3));
    u += 2 * r * math.cos(ang / 3);
  }
  final v = math.sqrt(_sq(u) + q);
  final uv = u < 0 ? q / (v - u) : u + v; // u + v, positive
  final w = (uv - q) / (2 * v);
  return uv / (math.sqrt(uv + _sq(w)) + w);
}

double _polyval(int n, List<double> p, int s, double x) {
  var y = n < 0 ? 0.0 : p[s];
  for (var i = 1; i <= n; i++) {
    y = y * x + p[s + i];
  }
  return y;
}

double _sq(double x) => x * x;
double _hypot(double x, double y) => math.sqrt(x * x + y * y);
double _cbrt(double x) => _copysign(math.pow(x.abs(), 1 / 3).toDouble(), x);
double _copysign(double x, double y) => y.isNegative ? -x.abs() : x.abs();

(double, double) _norm(double x, double y) {
  final r = _hypot(x, y);
  return (x / r, y / r);
}

/// Error-free sum: (s, t) with s = round(u + v) and u + v = s + t.
(double, double) _sum(double u, double v) {
  final s = u + v;
  var up = s - v, vpp = s - up;
  up -= u;
  vpp -= v;
  return (s, s == 0 ? s : 0.0 - (up + vpp));
}

/// Rounds tiny angles so they underflow to zero, avoiding near-singular cases.
double _angRound(double x) {
  const z = 1 / 16;
  var y = x.abs();
  if (y < z) y = z - (z - y);
  return _copysign(y, x);
}

/// Remainder of x / y in [-y/2, y/2].
double _remainder(double x, double y) {
  if (!x.isFinite) return double.nan;
  final r = x.remainder(y); // exact, sign of x
  return r.abs() > y / 2 ? r - _copysign(y, r) : r;
}

double _angNormalize(double x) {
  final y = _remainder(x, 360);
  return y.abs() == 180 ? _copysign(180, x) : y;
}

double _latFix(double x) => x.abs() > 90 ? double.nan : x;

/// y - x reduced to [-180, 180], with its rounding error.
(double, double) _angDiff(double x, double y) {
  var (d, t) = _sum(_remainder(-x, 360), _remainder(y, 360));
  (d, t) = _sum(_remainder(d, 360), t);
  if (d == 0 || d.abs() == 180) d = _copysign(d, t == 0 ? y - x : -t);
  return (d, t);
}

/// Sine and cosine of [x] degrees, exact at multiples of 90.
(double, double) _sincosd(double x) {
  var r = x.isFinite ? x.remainder(360) : double.nan;
  final q = r.isNaN ? 0 : (r / 90).round();
  r = (r - 90 * q) * _deg;
  return _quadrant(math.sin(r), math.cos(r), q, x);
}

/// Sine and cosine of x + t degrees, x in [-180, 180] and t small.
(double, double) _sincosde(double x, double t) {
  final q = x.isFinite ? (x / 90).round() : 0;
  final r = _angRound((x - 90 * q) + t) * _deg;
  return _quadrant(math.sin(r), math.cos(r), q, x);
}

(double, double) _quadrant(double s, double c, int q, double x) {
  (s, c) = switch (q % 4) {
    1 => (c, -s),
    2 => (-s, -c),
    3 => (-c, s),
    _ => (s, c),
  };
  c += 0.0;
  if (s == 0) s = _copysign(s, x);
  return (s, c);
}

/// atan2 in degrees, exact for the cardinal directions.
double _atan2d(double y, double x) {
  var q = 0;
  if (y.abs() > x.abs()) {
    (x, y) = (y, x);
    q = 2;
  }
  if (x < 0) {
    q++;
    x = -x;
  }
  final ang = math.atan2(y, x) * _rad;
  return switch (q) {
    1 => _copysign(180, y) - ang,
    2 => 90 - ang,
    3 => -90 + ang,
    _ => ang,
  };
}
