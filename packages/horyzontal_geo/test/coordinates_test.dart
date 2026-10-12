import 'package:horyzontal_geo/horyzontal_geo.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

const kyiv = Geodetic(50.4501, 30.5234);

void main() {
  group('geographic parsing', () {
    const cases = {
      '50.4501, 30.5234': (50.4501, 30.5234),
      '50.4501 30.5234': (50.4501, 30.5234),
      '50,4501 30,5234': (50.4501, 30.5234),
      '50,4501, 30,5234': (50.4501, 30.5234),
      '50.4501,30.5234': (50.4501, 30.5234),
      '50,30': (50.0, 30.0),
      '-33.9 18.4': (-33.9, 18.4),
      '50.4501N 30.5234E': (50.4501, 30.5234),
      'N50.4501 E30.5234': (50.4501, 30.5234),
      '30.5234E 50.4501N': (50.4501, 30.5234),
      '33.9S 18.4W': (-33.9, -18.4),
      '50°27\'00.36"N 30°31\'24.24"E': (50.4501, 30.5234),
      '50°27′00.36″ пн. ш., 30°31′24.24″ сх. д.': (50.4501, 30.5234),
      '50°27\'00.36" 30°31\'24.24"': (50.4501, 30.5234),
      '50°27.0060\'N 30°31.4040\'E': (50.4501, 30.5234),
      '50 27 00.36 30 31 24.24': (50.4501, 30.5234),
      '50 27.006 30 31.404': (50.4501, 30.5234),
      '50°27\' 30°31\'': (50.45, 30.516666666),
      'пн 50.4501 сх 30.5234': (50.4501, 30.5234),
      '50.4501 с.ш. 30.5234 в.д.': (50.4501, 30.5234),
    };
    cases.forEach((input, expected) {
      test(input, () {
        final (lat, lon) = parseGeographic(input);
        expect(lat, closeTo(expected.$1, 1e-7));
        expect(lon, closeTo(expected.$2, 1e-7));
      });
    });

    test('errors', () {
      for (final s in [
        '',
        'hello',
        '50.45',
        '1 2 3',
        '95 30',
        '50 190',
        '50 61 30 10',
        '50.5 30 30 10',
        '50N 30N',
      ]) {
        expect(() => parseGeographic(s), throwsA(isA<CoordinateParseException>()), reason: s);
      }
    });
  });

  test('format geographic', () {
    expect(formatGeographic(50.4501, 30.5234, GeoFormat.degrees), '50.450100, 30.523400');
    expect(formatGeographic(50.4501, 30.5234, GeoFormat.dms), '50°27\'00.36"N 30°31\'24.24"E');
    expect(formatGeographic(50.4501, 30.5234, GeoFormat.degMin), '50°27.0060\'N 30°31.4040\'E');
    expect(formatGeographic(-33.9, -18.4, GeoFormat.dms), '33°54\'00.00"S 18°24\'00.00"W');
    expect(formatGeographic(50.99999999, 30, GeoFormat.dms), '51°00\'00.00"N 30°00\'00.00"E');
  });

  test('grid parsing', () {
    const sk = CoordinateSystem.sk42Gk;
    for (final s in [
      '5593957 6324233',
      'X=5593957 Y=6324233',
      'Y=6324233, X=5593957',
      'х 5593957 у 6324233',
      '6324233 5593957',
      '5593957,0 6324233,0',
    ]) {
      final p = parseGrid(s, sk);
      expect(p.zone, 6, reason: s);
      expect(p.x, 5593957, reason: s);
      expect(p.y, 6324233, reason: s);
    }
    final t = parseGrid('5593954 324226 (10)', CoordinateSystem.usk2000Tm3);
    expect((t.zone, t.x, t.y), (10, 5593954, 324226));
    final t2 = parseGrid('X=5593954 Y=324226', CoordinateSystem.usk2000Tm3, zone: 10);
    expect(t2.zone, 10);
    expect(
      () => parseGrid('5593954 324226', CoordinateSystem.usk2000Tm3),
      throwsA(
        isA<CoordinateParseException>().having(
          (e) => e.error,
          'error',
          CoordinateError.missingZone,
        ),
      ),
    );
    expect(() => parseGrid('5593957', sk), throwsA(isA<CoordinateParseException>()));
    expect(() => parseGrid('12 34', sk), throwsA(isA<CoordinateParseException>()));
  });

  test('UTM parsing', () {
    final u = parseUtm('36U 324183 5591607');
    expect((u.zone, u.band, u.easting, u.northing), (36, 'U', 324183, 5591607));
    expect(parseUtm('36 324183 5591607').band, 'U');
    expect(parseUtm('34H 261878 6243186').north, isFalse);
    expect(() => parseUtm('36U 24183 5591607'), throwsA(isA<CoordinateParseException>()));
  });

  test('every system round-trips through text', () {
    final rows = readCsv('datum_ukraine.csv');
    final err = MaxError('text round trip', 'm');
    for (final r in rows.take(120)) {
      final g = Geodetic(r.d('wgs_lat'), r.d('wgs_lon'));
      for (final sys in CoordinateSystem.values) {
        for (final f in GeoFormat.values) {
          if (!sys.isGeographic && f != GeoFormat.degrees) continue;
          final text = formatCoordinates(g, sys, geoFormat: f);
          final back = parseCoordinates(text, sys);
          // Display precision: 1 m grids, 1 m MGRS cell, ~0.3 m sexagesimal.
          final tol = switch (sys) {
            CoordinateSystem.mgrs => 0.75,
            _ when sys.isGeographic => 0.3,
            _ => 0.72,
          };
          expect(
            err.add(groundError(back.lat, back.lon, g.lat, g.lon)),
            lessThan(tol),
            reason: '$sys $f $text',
          );
        }
      }
    }
    err.report();
  });

  test('Kyiv in all systems', () {
    String f(CoordinateSystem s) => formatCoordinates(kyiv, s, geoFormat: GeoFormat.dms);
    expect(f(CoordinateSystem.wgs84), '50°27\'00.36"N 30°31\'24.24"E');
    expect(f(CoordinateSystem.sk42Gk), '5593957 6324233');
    expect(f(CoordinateSystem.usk2000Gk), '5593954 6324226');
    expect(f(CoordinateSystem.usk2000Tm3), '5591157 337291 (10)');
    expect(f(CoordinateSystem.mgrs), '36U UA 24182 91607');
    expect(f(CoordinateSystem.utm), '36U 324182 5591608');
    expect(formatCoordinates(kyiv, CoordinateSystem.sk42Gk, zone: 5), startsWith('55'));
  });
}
