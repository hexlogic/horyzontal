import 'dart:math' as math;

import 'package:horyzontal_geo/horyzontal_geo.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

const _rad = math.pi / 180;

/// Angle between two directions on the sky, degrees.
double separation(double az1, double alt1, double az2, double alt2) {
  final c = math.sin(alt1 * _rad) * math.sin(alt2 * _rad) +
      math.cos(alt1 * _rad) * math.cos(alt2 * _rad) * math.cos((az1 - az2) * _rad);
  return math.acos(c.clamp(-1.0, 1.0)) / _rad;
}

bool modern(DateTime t) => t.year >= 1900 && t.year < 2100;

void main() {
  final positions = readCsv('astro_positions.csv');

  test('Sun and Moon positions match skyfield with DE440, 1900–2100', () {
    final sun = MaxError('Sun 1900–2100', '°'), moon = MaxError('Moon 1900–2100', '°');
    final lit = MaxError('Moon lit fraction', ''), dist = MaxError('Moon distance', 'km');
    for (final r in positions) {
      final t = DateTime.parse(r['time']!);
      if (!modern(t)) continue;
      final g = Geodetic(r.d('lat'), r.d('lon'), r.d('h'));
      final s = sunPosition(g, t), m = moonPosition(g, t);
      expect(sun.add(separation(s.azimuth, s.altitude, r.d('sun_az'), r.d('sun_alt'))), lessThan(0.015), reason: '$t $g');
      expect(moon.add(separation(m.azimuth, m.altitude, r.d('moon_az'), r.d('moon_alt'))), lessThan(0.03),
          reason: '$t $g');
      expect(lit.add((m.illumination - r.d('moon_lit')).abs()), lessThan(0.005), reason: '$t');
      expect(dist.add((m.distanceKm - r.d('moon_km')).abs()), lessThan(50), reason: '$t');
    }
    for (final e in [sun, moon, lit, dist]) {
      e.report();
    }
  });

  test('positions stay usable across 1600–2600', () {
    final sun = MaxError('Sun 1600–2600', '°'), moon = MaxError('Moon 1600–2600', '°');
    for (final r in positions) {
      final t = DateTime.parse(r['time']!);
      if (modern(t)) continue;
      final g = Geodetic(r.d('lat'), r.d('lon'), r.d('h'));
      final s = sunPosition(g, t), m = moonPosition(g, t);
      expect(sun.add(separation(s.azimuth, s.altitude, r.d('sun_az'), r.d('sun_alt'))), lessThan(0.02), reason: '$t');
      expect(moon.add(separation(m.azimuth, m.altitude, r.d('moon_az'), r.d('moon_alt'))), lessThan(0.1),
          reason: '$t');
    }
    sun.report();
    moon.report();
  });

  test('rise, set, culmination and twilight match skyfield', () {
    final byCase = <String, List<Map<String, String>>>{};
    for (final r in readCsv('astro_events.csv')) {
      byCase.putIfAbsent(r['case']!, () => []).add(r);
    }
    final modernErr = MaxError('events 1950–2080', 's'), wideErr = MaxError('events 1700–2500', 's');
    for (final rows in byCase.values) {
      final r0 = rows.first;
      final from = DateTime.parse(r0['from']!);
      final g = Geodetic(r0.d('lat'), r0.d('lon'), r0.d('h'));
      final ours = skyEvents(g, from, const Duration(days: 2));
      final wide = from.year < 1950 || from.year >= 2080;
      for (final r in rows) {
        final t = DateTime.parse(r['time']!);
        final same = ours.where((e) => e.body.name == r['body'] && e.kind.name == r['kind']);
        expect(same, isNotEmpty, reason: '${r['body']} ${r['kind']} $t at $g');
        final err = same.map((e) => e.time.difference(t).inMilliseconds.abs() / 1000).reduce(math.min);
        expect((wide ? wideErr : modernErr).add(err), lessThan(wide ? 60 : 30), reason: '${r['body']} ${r['kind']} $t $g');
      }
      // Nothing that skyfield did not find, except right at the window's ends.
      for (final e in ours) {
        if (e.time.difference(from).inMinutes < 5 || from.add(const Duration(days: 2)).difference(e.time).inMinutes < 5) {
          continue;
        }
        expect(
          rows.any((r) => r['body'] == e.body.name && r['kind'] == e.kind.name &&
              DateTime.parse(r['time']!).difference(e.time).inMinutes.abs() < 10),
          isTrue,
          reason: 'extra $e at $g',
        );
      }
    }
    modernErr.report();
    wideErr.report();
  });

  test('polar night: no sunrise in Longyearbyen in December', () {
    final events = skyEvents(const Geodetic(78.22, 15.65), DateTime.utc(2026, 12, 20), const Duration(days: 2));
    expect(events.where((e) => e.body == SkyBody.sun && e.kind == SkyEventKind.rise), isEmpty);
    expect(sunPosition(const Geodetic(78.22, 15.65), DateTime.utc(2026, 12, 21, 12)).altitude, lessThan(-10));
  });

  test('refraction lifts a body on the horizon by about 29′ to 35′', () {
    expect(refraction(-0.5) * 60, closeTo(34, 3));
    expect(refraction(45) * 60, closeTo(1, 0.1));
    expect(refraction(-5), 0);
  });

  test('ΔT is about a minute today and grows into the past', () {
    expect(deltaT(2000), closeTo(63.8, 0.2));
    expect(deltaT(1900), closeTo(-2.8, 0.5));
    expect(deltaT(1000), closeTo(1574, 1));
    expect(julianDay(DateTime.utc(2000, 1, 1, 12)), 2451545.0);
    expect(fromJulianDay(2451545.0), DateTime.utc(2000, 1, 1, 12));
  });
}
