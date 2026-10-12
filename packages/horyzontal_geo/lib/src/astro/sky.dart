import 'dart:math' as math;

import '../datum.dart';
import 'moon_terms.dart';
import 'time.dart';

const _rad = math.pi / 180;
const _deg = 180 / math.pi;
const _au = 149597870.7; // km
const _earthRadius = 6378.14; // km, Meeus

double _norm(double a) {
  final r = a % 360;
  return r < 0 ? r + 360 : r;
}

/// −180 < a ≤ 180.
double _signed(double a) {
  final r = _norm(a);
  return r > 180 ? r - 360 : r;
}

double _sin(double d) => math.sin(d * _rad);
double _cos(double d) => math.cos(d * _rad);

enum SkyBody { sun, moon }

/// Where a body is seen from a place: topocentric, apparent (aberration and
/// nutation included), without refraction unless asked.
class SkyPosition {
  const SkyPosition({
    required this.azimuth,
    required this.altitude,
    required this.hourAngle,
    required this.distanceKm,
    required this.rightAscension,
    required this.declination,
  });

  /// True azimuth, degrees clockwise from north, 0 ≤ a < 360.
  final double azimuth;

  /// Altitude of the centre above the horizon without refraction, degrees.
  final double altitude;

  /// Local hour angle, degrees, −180 < H ≤ 180; 0 at the upper culmination.
  final double hourAngle;

  final double distanceKm;

  /// Topocentric right ascension and declination, degrees.
  final double rightAscension, declination;

  /// Altitude as seen through a standard atmosphere (10 °C, 1010 hPa):
  /// refraction lifts a body on the horizon by about 34′.
  double get apparentAltitude => altitude + refraction(altitude);
}

/// Atmospheric refraction for a true [altitude], degrees (Sæmundsson, as in
/// Meeus 16.4). Zero well below the horizon.
double refraction(double altitude) {
  if (altitude < -1.9) return 0;
  final r = 1.02 / math.tan((altitude + 10.3 / (altitude + 5.11)) * _rad); // arcminutes
  return math.max(r, 0) / 60;
}

class MoonPosition extends SkyPosition {
  const MoonPosition({
    required super.azimuth,
    required super.altitude,
    required super.hourAngle,
    required super.distanceKm,
    required super.rightAscension,
    required super.declination,
    required this.illumination,
    required this.elongation,
    required this.waxing,
  });

  /// Lit fraction of the disc, 0 (new) to 1 (full).
  final double illumination;

  /// Ecliptic longitude of the Moon minus that of the Sun, 0 ≤ e < 360:
  /// 0 new, 90 first quarter, 180 full, 270 last quarter.
  final double elongation;
  final bool waxing;

  /// Days since the new moon, from the elongation and the mean synodic month.
  double get age => elongation / 360 * 29.530589;

  MoonPhase get phase => switch (elongation) {
    < 6 || >= 354 => MoonPhase.newMoon,
    < 84 => MoonPhase.waxingCrescent,
    < 96 => MoonPhase.firstQuarter,
    < 174 => MoonPhase.waxingGibbous,
    < 186 => MoonPhase.fullMoon,
    < 264 => MoonPhase.waningGibbous,
    < 276 => MoonPhase.lastQuarter,
    _ => MoonPhase.waningCrescent,
  };
}

enum MoonPhase {
  newMoon,
  waxingCrescent,
  firstQuarter,
  waxingGibbous,
  fullMoon,
  waningGibbous,
  lastQuarter,
  waningCrescent,
}

/// Geocentric apparent ecliptic position: longitude, latitude (degrees),
/// distance (km).
typedef _Ecliptic = ({double lon, double lat, double dist});

class _Epoch {
  _Epoch(DateTime t) : jd = julianDay(t) {
    final jde = ephemerisDay(jd);
    this.t = centuries(jde);
    final n = nutation(this.t);
    dPsi = n.dPsi;
    eps = meanObliquity(this.t) + n.dEps;
    theta = siderealTime(jd, dPsi: dPsi, eps: eps);
  }

  final double jd;
  late final double t, dPsi, eps, theta;
}

/// The Sun after Meeus ch. 25: about 0.01° near the present.
_Ecliptic _sun(_Epoch e) {
  final t = e.t;
  final l0 = 280.46646 + 36000.76983 * t + 0.0003032 * t * t;
  final m = 357.52911 + 35999.05029 * t - 0.0001537 * t * t;
  final ecc = 0.016708634 - 0.000042037 * t - 0.0000001267 * t * t;
  final c = (1.914602 - 0.004817 * t - 0.000014 * t * t) * _sin(m) +
      (0.019993 - 0.000101 * t) * _sin(2 * m) +
      0.000289 * _sin(3 * m);
  final nu = m + c;
  final r = 1.000001018 * (1 - ecc * ecc) / (1 + ecc * _cos(nu)); // AU
  // Nutation and aberration (20.4898″ / R).
  final lon = l0 + c + e.dPsi - 20.4898 / 3600 / r;
  return (lon: _norm(lon), lat: 0, dist: r * _au);
}

/// The Moon after Meeus ch. 47: about 10″ in longitude near the present.
_Ecliptic _moon(_Epoch e) {
  final t = e.t, t2 = t * t, t3 = t2 * t, t4 = t3 * t;
  final lp = 218.3164477 + 481267.88123421 * t - 0.0015786 * t2 + t3 / 538841 - t4 / 65194000;
  final d = 297.8501921 + 445267.1114034 * t - 0.0018819 * t2 + t3 / 545868 - t4 / 113065000;
  final m = 357.5291092 + 35999.0502909 * t - 0.0001536 * t2 + t3 / 24490000;
  final mp = 134.9633964 + 477198.8675055 * t + 0.0087414 * t2 + t3 / 69699 - t4 / 14712000;
  final f = 93.2720950 + 483202.0175233 * t - 0.0036539 * t2 - t3 / 3526000 + t4 / 863310000;
  final a1 = 119.75 + 131.849 * t, a2 = 53.09 + 479264.290 * t, a3 = 313.45 + 481266.484 * t;
  final ecc = 1 - 0.002516 * t - 0.0000074 * t2;

  double eFactor(int mm) => switch (mm.abs()) { 1 => ecc, 2 => ecc * ecc, _ => 1 };

  var sl = 0.0, sr = 0.0, sb = 0.0;
  for (final r in moonLr) {
    final arg = r[0] * d + r[1] * m + r[2] * mp + r[3] * f;
    final k = eFactor(r[1]);
    sl += r[4] * k * _sin(arg);
    sr += r[5] * k * _cos(arg);
  }
  for (final r in moonB) {
    sb += r[4] * eFactor(r[1]) * _sin(r[0] * d + r[1] * m + r[2] * mp + r[3] * f);
  }
  sl += 3958 * _sin(a1) + 1962 * _sin(lp - f) + 318 * _sin(a2);
  sb += -2235 * _sin(lp) + 382 * _sin(a3) + 175 * _sin(a1 - f) + 175 * _sin(a1 + f) +
      127 * _sin(lp - mp) - 115 * _sin(lp + mp);
  return (lon: _norm(lp + sl / 1e6 + e.dPsi), lat: sb / 1e6, dist: 385000.56 + sr / 1000);
}

/// Topocentric horizontal position of a body at [ecl] seen from [place]
/// (Meeus ch. 13 and 40).
SkyPosition _horizontal(_Ecliptic ecl, _Epoch e, Geodetic place) {
  final lon = ecl.lon, lat = ecl.lat;
  final ra = _norm(math.atan2(_sin(lon) * _cos(e.eps) - math.tan(lat * _rad) * _sin(e.eps), _cos(lon)) * _deg);
  final dec = math.asin(_sin(lat) * _cos(e.eps) + _cos(lat) * _sin(e.eps) * _sin(lon)) * _deg;

  // Parallax: the observer is off the Earth's centre.
  final phi = place.lat;
  const ba = 0.99664719;
  final u = math.atan(ba * math.tan(phi * _rad));
  final hr = place.h / 6378140;
  final rhoSin = ba * math.sin(u) + hr * _sin(phi);
  final rhoCos = math.cos(u) + hr * _cos(phi);
  final sinPi = _earthRadius / ecl.dist;
  final h = _norm(e.theta + place.lon - ra);
  final dRa = math.atan2(-rhoCos * sinPi * _sin(h), _cos(dec) - rhoCos * sinPi * _cos(h)) * _deg;
  final decT = math.atan2((_sin(dec) - rhoSin * sinPi) * _cos(dRa), _cos(dec) - rhoCos * sinPi * _cos(h)) * _deg;
  final hT = h - dRa;

  final az = math.atan2(_sin(hT), _cos(hT) * _sin(phi) - math.tan(decT * _rad) * _cos(phi)) * _deg + 180;
  final alt = math.asin(_sin(phi) * _sin(decT) + _cos(phi) * _cos(decT) * _cos(hT)) * _deg;
  // Distance from the observer, by the law of cosines on the parallax
  // triangle: close enough for the semidiameter.
  final topoDist = ecl.dist * math.sqrt(1 - 2 * sinPi * (rhoSin * _sin(dec) + rhoCos * _cos(dec) * _cos(h)) +
      sinPi * sinPi * (rhoSin * rhoSin + rhoCos * rhoCos));
  return SkyPosition(
    azimuth: _norm(az),
    altitude: alt,
    hourAngle: _signed(hT),
    distanceKm: topoDist,
    rightAscension: _norm(ra + dRa),
    declination: decT,
  );
}

/// The Sun seen from [place] (WGS 84, height above the ellipsoid) at [time].
SkyPosition sunPosition(Geodetic place, DateTime time) {
  final e = _Epoch(time);
  return _horizontal(_sun(e), e, place);
}

/// The Moon seen from [place] at [time], with its phase.
MoonPosition moonPosition(Geodetic place, DateTime time) {
  final e = _Epoch(time);
  final moon = _moon(e), sun = _sun(e);
  final p = _horizontal(moon, e, place);
  final elong = _norm(moon.lon - sun.lon);
  // Phase angle at the Moon (Meeus 48.2, 48.3).
  final psi = math.acos(_cos(moon.lat) * _cos(moon.lon - sun.lon));
  final i = math.atan2(sun.dist * math.sin(psi), moon.dist - sun.dist * math.cos(psi));
  return MoonPosition(
    azimuth: p.azimuth,
    altitude: p.altitude,
    hourAngle: p.hourAngle,
    distanceKm: p.distanceKm,
    rightAscension: p.rightAscension,
    declination: p.declination,
    illumination: (1 + math.cos(i)) / 2,
    elongation: elong,
    waxing: elong < 180,
  );
}

/// Position of [body] from [place] at [time].
SkyPosition skyPosition(SkyBody body, Geodetic place, DateTime time) =>
    body == SkyBody.sun ? sunPosition(place, time) : moonPosition(place, time);

enum SkyEventKind {
  rise,
  set,

  /// Upper culmination: the body crosses the meridian, highest in the sky.
  transit,
  civilDawn,
  civilDusk,
  nauticalDawn,
  nauticalDusk,
  astronomicalDawn,
  astronomicalDusk,
}

class SkyEvent {
  const SkyEvent(this.body, this.kind, this.time, this.position);
  final SkyBody body;
  final SkyEventKind kind;

  /// UTC, to about a second of the model's own answer.
  final DateTime time;
  final SkyPosition position;

  @override
  String toString() => 'SkyEvent(${body.name} ${kind.name} $time)';
}

/// Altitude of the Sun's centre at sunrise and sunset: the upper limb on
/// the horizon through 34′ of refraction.
const sunRiseAltitude = -0.8333;

/// Altitude of the Moon's centre at moonrise: refraction and the
/// topocentric semidiameter, which follows the distance.
double moonRiseAltitude(double distanceKm) => -(34 / 60 + math.asin(1737.4 / distanceKm) * _deg);

/// Rise, set, culmination and twilight of the Sun and the Moon at [place]
/// between [from] and [from] + [span], in time order. A body that does not
/// rise or set in that time (polar day or night) simply has no such event.
List<SkyEvent> skyEvents(Geodetic place, DateTime from, Duration span) {
  const step = Duration(minutes: 10);
  final start = from.toUtc();
  final n = (span.inSeconds / step.inSeconds).ceil();
  final events = <SkyEvent>[];

  double sunAlt(SkyPosition p) => p.altitude;
  double moonAlt(SkyPosition p) => p.altitude - moonRiseAltitude(p.distanceKm);

  for (final body in SkyBody.values) {
    SkyPosition at(DateTime t) => skyPosition(body, place, t);
    var t0 = start;
    var p0 = at(t0);
    for (var i = 1; i <= n; i++) {
      final t1 = start.add(step * i);
      final p1 = at(t1);

      void crossing(double Function(SkyPosition) f, SkyEventKind up, SkyEventKind? down) {
        final a = f(p0), b = f(p1);
        if ((a < 0) == (b < 0)) return;
        final kind = a < 0 ? up : down;
        if (kind == null) return;
        final t = _bisect(t0, t1, (t) => f(at(t)) < 0, a < 0);
        events.add(SkyEvent(body, kind, t, at(t)));
      }

      if (body == SkyBody.sun) {
        crossing((p) => sunAlt(p) - sunRiseAltitude, SkyEventKind.rise, SkyEventKind.set);
        crossing((p) => p.altitude + 6, SkyEventKind.civilDawn, SkyEventKind.civilDusk);
        crossing((p) => p.altitude + 12, SkyEventKind.nauticalDawn, SkyEventKind.nauticalDusk);
        crossing((p) => p.altitude + 18, SkyEventKind.astronomicalDawn, SkyEventKind.astronomicalDusk);
      } else {
        crossing(moonAlt, SkyEventKind.rise, SkyEventKind.set);
      }
      // Culmination: the hour angle passes 0, from east of the meridian to west.
      if (p0.hourAngle < 0 && p1.hourAngle >= 0 && p1.hourAngle - p0.hourAngle < 90) {
        final t = _bisect(t0, t1, (t) => at(t).hourAngle < 0, true);
        events.add(SkyEvent(body, SkyEventKind.transit, t, at(t)));
      }
      t0 = t1;
      p0 = p1;
    }
  }
  events.sort((a, b) => a.time.compareTo(b.time));
  return events;
}

/// The moment in [t0, t1] where [below] flips, to a second. [risingBelow]
/// says whether [below] holds at [t0].
DateTime _bisect(DateTime t0, DateTime t1, bool Function(DateTime) below, bool risingBelow) {
  var lo = t0, hi = t1;
  while (hi.difference(lo) > const Duration(milliseconds: 500)) {
    final mid = lo.add(hi.difference(lo) ~/ 2);
    if (below(mid) == risingBelow) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return lo.add(hi.difference(lo) ~/ 2);
}
