import 'dart:math' as math;

import 'ellipsoid.dart';

const _arcsec = math.pi / (180 * 3600);

/// Seven-parameter Helmert transformation from a datum to WGS 84, coordinate
/// frame rotation convention (EPSG method 1032/9607). Translations in metres,
/// rotations in arc-seconds, scale in ppm.
class Helmert {
  const Helmert({
    this.tx = 0,
    this.ty = 0,
    this.tz = 0,
    this.rx = 0,
    this.ry = 0,
    this.rz = 0,
    this.ds = 0,
  });

  final double tx, ty, tz, rx, ry, rz, ds;

  static const identity = Helmert();

  bool get isIdentity => tx == 0 && ty == 0 && tz == 0 && rx == 0 && ry == 0 && rz == 0 && ds == 0;

  /// Datum -> WGS 84. Small-angle rotation matrix, as in PROJ.
  Ecef forward(Ecef p) {
    final m = 1 + ds * 1e-6;
    final x = rx * _arcsec, y = ry * _arcsec, z = rz * _arcsec;
    return Ecef(
      m * (p.x + z * p.y - y * p.z) + tx,
      m * (-z * p.x + p.y + x * p.z) + ty,
      m * (y * p.x - x * p.y + p.z) + tz,
    );
  }

  /// WGS 84 -> datum, through the transposed rotation matrix (as in PROJ).
  Ecef inverse(Ecef p) {
    final m = 1 + ds * 1e-6;
    final x = rx * _arcsec, y = ry * _arcsec, z = rz * _arcsec;
    final px = p.x - tx, py = p.y - ty, pz = p.z - tz;
    return Ecef(
      (px - z * py + y * pz) / m,
      (z * px + py - x * pz) / m,
      (-y * px + x * py + pz) / m,
    );
  }
}

/// Earth-centred, earth-fixed cartesian coordinates, metres.
class Ecef {
  const Ecef(this.x, this.y, this.z);
  final double x, y, z;
}

/// Geodetic coordinates on some datum: degrees and metres above the ellipsoid.
class Geodetic {
  const Geodetic(this.lat, this.lon, [this.h = 0]);
  final double lat, lon, h;

  @override
  String toString() => 'Geodetic($lat, $lon, $h)';
}

/// Geodetic datum: an ellipsoid plus the transformation to WGS 84.
class Datum {
  const Datum(this.name, this.ellipsoid, this.toWgs84);

  final String name;
  final Ellipsoid ellipsoid;
  final Helmert toWgs84;

  static const wgs84 = Datum('WGS 84', Ellipsoid.wgs84, Helmert.identity);

  /// СК-42 (Pulkovo 1942). EPSG:15865 "Pulkovo 1942 to WGS 84 (16)", 4.5 m,
  /// the transformation PROJ picks for Ukraine. Ukraine has no single
  /// published official set; the alternatives differ by about 1 m.
  static const sk42 = Datum(
    'СК-42',
    Ellipsoid.krassowsky,
    Helmert(tx: 25, ty: -141, tz: -78.5, ry: -0.35, rz: -0.736),
  );

  /// УСК-2000. EPSG:7817 "UCS-2000 to ITRF2000 (1)" (the official parameters
  /// that EPSG:5840 rounds), treating WGS 84 as ITRF2000.
  static const usk2000 = Datum(
    'УСК-2000',
    Ellipsoid.krassowsky,
    Helmert(tx: 24.322, ty: -121.372, tz: -75.847),
  );

  Ecef toEcef(Geodetic g) => geodeticToEcef(ellipsoid, g);
  Geodetic fromEcef(Ecef p) => ecefToGeodetic(ellipsoid, p);

  /// Datum coordinates to WGS 84. As with EPSG 2D transformations, the height
  /// is carried through unchanged.
  Geodetic toWgs84Geodetic(Geodetic g) {
    if (toWgs84.isIdentity && ellipsoid == Ellipsoid.wgs84) return g;
    final r = ecefToGeodetic(Ellipsoid.wgs84, toWgs84.forward(toEcef(g)));
    return Geodetic(r.lat, r.lon, g.h);
  }

  Geodetic fromWgs84Geodetic(Geodetic g) {
    if (toWgs84.isIdentity && ellipsoid == Ellipsoid.wgs84) return g;
    final r = fromEcef(toWgs84.inverse(geodeticToEcef(Ellipsoid.wgs84, g)));
    return Geodetic(r.lat, r.lon, g.h);
  }
}

Ecef geodeticToEcef(Ellipsoid e, Geodetic g) {
  final phi = g.lat * math.pi / 180, lam = g.lon * math.pi / 180;
  final s = math.sin(phi), c = math.cos(phi);
  final n = e.a / math.sqrt(1 - e.e2 * s * s);
  return Ecef(
    (n + g.h) * c * math.cos(lam),
    (n + g.h) * c * math.sin(lam),
    (n * (1 - e.e2) + g.h) * s,
  );
}

Geodetic ecefToGeodetic(Ellipsoid e, Ecef p) {
  final lon = math.atan2(p.y, p.x);
  final r = math.sqrt(p.x * p.x + p.y * p.y);
  // Bowring's starting value, then fixed-point iteration; converges to well
  // below a micrometre in a few steps for terrestrial heights.
  final ep2 = e.e2 / (1 - e.e2);
  var u = math.atan2(p.z * e.a, r * e.b);
  var phi = math.atan2(
    p.z + ep2 * e.b * math.pow(math.sin(u), 3),
    r - e.e2 * e.a * math.pow(math.cos(u), 3),
  );
  for (var i = 0; i < 5; i++) {
    u = math.atan2((1 - e.f) * math.sin(phi), math.cos(phi));
    final next = math.atan2(
      p.z + ep2 * e.b * math.pow(math.sin(u), 3),
      r - e.e2 * e.a * math.pow(math.cos(u), 3),
    );
    if ((next - phi).abs() < 1e-15) {
      phi = next;
      break;
    }
    phi = next;
  }
  final s = math.sin(phi), c = math.cos(phi);
  final n = e.a / math.sqrt(1 - e.e2 * s * s);
  final h = c.abs() > 1e-10 ? r / c - n : p.z.abs() / s.abs() - n * (1 - e.e2);
  return Geodetic(phi * 180 / math.pi, lon * 180 / math.pi, h);
}
