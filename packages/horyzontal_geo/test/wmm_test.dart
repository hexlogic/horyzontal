import 'dart:io';

import 'package:horyzontal_geo/horyzontal_geo.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  test('WMM2025 matches the official NOAA test values', () {
    final err = MaxError('WMM declination', 'deg');
    final lines = File('test/fixtures/WMM2025_TEST_VALUES.txt')
        .readAsLinesSync()
        .where((l) => l.trim().isNotEmpty && !l.startsWith('#'));
    for (final l in lines) {
      final f = l.trim().split(RegExp(r'\s+')).map(double.parse).toList();
      final b = Wmm.wmm2025.at(f[2], f[3], f[1] * 1000, f[0]);
      final why = l.trim();
      // Published to 0.1 nT and 0.01°.
      expect(b.x, closeTo(f[4], 0.06), reason: why);
      expect(b.y, closeTo(f[5], 0.06), reason: why);
      expect(b.z, closeTo(f[6], 0.06), reason: why);
      expect(b.h, closeTo(f[7], 0.06), reason: why);
      expect(b.f, closeTo(f[8], 0.06), reason: why);
      expect(b.inclination, closeTo(f[9], 0.006), reason: why);
      expect(err.add((b.declination - f[10]).abs()), lessThan(0.006), reason: why);
    }
    err.report();
  });

  test('declination in Kyiv is a few degrees east', () {
    final d = Wmm.wmm2025.at(50.45, 30.52, 150, 2026.78).declination;
    expect(d, inInclusiveRange(7, 10));
  });

  test('decimal year and validity', () {
    expect(decimalYear(DateTime.utc(2025)), 2025.0);
    expect(decimalYear(DateTime.utc(2026, 7, 2, 12)), closeTo(2026.5, 0.001));
    expect(Wmm.wmm2025.isValidAt(2026.8), isTrue);
    expect(Wmm.wmm2025.isValidAt(2030.5), isFalse);
  });
}
