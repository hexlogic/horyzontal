import 'package:horyzontal_geo/horyzontal_geo.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  test('EGM2008 Ukraine grid matches PROJ us_nga_egm08_25', () {
    final err = MaxError('geoid', 'm');
    for (final r in readCsv('geoid.csv')) {
      final n = Geoid.egm2008Ukraine.undulation(r.d('lat'), r.d('lon'))!;
      expect(err.add((n - r.d('n')).abs()), lessThan(0.15), reason: '$r');
    }
    err.report();
  });

  test('outside the grid', () {
    expect(Geoid.egm2008Ukraine.undulation(60, 30), isNull);
    expect(Geoid.egm2008Ukraine.undulation(50, 10), isNull);
    expect(Geoid.egm2008Ukraine.undulation(50.4501, 30.5234), closeTo(25.25, 0.05));
  });
}
