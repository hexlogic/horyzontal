import 'package:horyzontal_geo/horyzontal_geo.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  test('UTM matches PROJ', () {
    final err = MaxError('UTM', 'm');
    for (final r in readCsv('utm.csv')) {
      final g = Geodetic(r.d('lat'), r.d('lon'));
      final u = utmFromWgs84(g);
      expect(u.zone, r.i('zone'), reason: '$g');
      final de = u.easting - r.d('easting'), dn = u.northing - r.d('northing');
      expect(err.add(de.abs() + dn.abs()), lessThan(1e-3), reason: '$g');
      final back = utmToWgs84(u);
      expect(groundError(back.lat, back.lon, g.lat, g.lon), lessThan(1e-4));
    }
    err.report();
  });

  test('MGRS matches GEOTRANS', () {
    var n = 0;
    for (final r in readCsv('mgrs.csv')) {
      final g = Geodetic(r.d('lat'), r.d('lon'));
      expect(mgrsFromWgs84(g).format(spaces: false), r['mgrs5'], reason: '$g');
      final back = mgrsToWgs84(parseMgrs(r['mgrs5']!), centre: true);
      // 1 m cell, centre within 0.71 m of any point in it.
      expect(groundError(back.lat, back.lon, g.lat, g.lon), lessThan(0.75), reason: '$g');
      n++;
    }
    print('MGRS: $n references');
  });

  test('MGRS parsing and precision', () {
    final p = parseMgrs('36u ua 2418 9160');
    expect(p.zone, 36);
    expect(p.band, 'U');
    expect(p.square, 'UA');
    expect(p.digits, 4);
    expect(p.easting, 24180);
    expect(p.northing, 91600);
    expect(parseMgrs('36UUA2418291607').format(), '36U UA 24182 91607');
    expect(mgrsFromWgs84(const Geodetic(50.4501, 30.5234), digits: 3).format(), '36U UA 241 916');
    expect(() => parseMgrs('36UUA241829160'), throwsFormatException);
    expect(() => parseMgrs('hello'), throwsFormatException);
    expect(() => parseMgrs('36U IA 1 1'), throwsFormatException);
  });
}
