import 'package:horyzontal_geo/horyzontal_geo.dart';
import 'package:test/test.dart';

void main() {
  test('format', () {
    expect(formatAngle(123.456, AngleFormat.deg360), '123.46°');
    expect(formatAngle(-10, AngleFormat.deg360), '350.00°');
    expect(formatAngle(359.999, AngleFormat.deg360), '0.00°');
    expect(formatAngle(90, AngleFormat.mils6000), '15-00');
    expect(formatAngle(90, AngleFormat.mils6400), '16-00');
    expect(formatAngle(0.3, AngleFormat.mils6000), '0-05');
    expect(formatAngle(359.99, AngleFormat.mils6000), '0-00');
    expect(formatAngle(123.4514, AngleFormat.dms), '123°27\'05"');
    expect(formatAngle(123.4514, AngleFormat.dms, decimals: 1), '123°27\'05.0"');
    expect(formatAngle(359.99999, AngleFormat.dms), '0°00\'00"');
    expect(formatAngle(-7.2, AngleFormat.deg360, signed: true), '-7.20°');
    expect(formatAngle(7.2, AngleFormat.mils6000, signed: true), '+1-20');
    expect(formatAngle(-0.72, AngleFormat.mils6000, signed: true), '-0-12');
  });

  test('parse', () {
    expect(parseAngle('15-30', AngleFormat.mils6000), closeTo(91.8, 1e-12));
    expect(parseAngle('1530', AngleFormat.mils6000), closeTo(91.8, 1e-12));
    expect(parseAngle('15 30', AngleFormat.mils6000), closeTo(91.8, 1e-12));
    expect(parseAngle('0-05', AngleFormat.mils6000), closeTo(0.3, 1e-12));
    expect(parseAngle('-0-12', AngleFormat.mils6000), closeTo(-0.72, 1e-12));
    expect(parseAngle('16-00', AngleFormat.mils6400), closeTo(90, 1e-12));
    expect(parseAngle('123,45', AngleFormat.deg360), closeTo(123.45, 1e-12));
    expect(parseAngle('123.45°', AngleFormat.deg360), closeTo(123.45, 1e-12));
    expect(parseAngle('123°27\'05"', AngleFormat.dms), closeTo(123.451389, 1e-6));
    expect(parseAngle('123 27 05', AngleFormat.dms), closeTo(123.451389, 1e-6));
    expect(parseAngle('123°27.5′', AngleFormat.dms), closeTo(123.458333, 1e-6));
  });

  test('parse errors', () {
    for (final s in ['', 'abc', '12-345', '10 61', '1 2 3 4']) {
      expect(
        () => parseAngle(s, s.contains('-') ? AngleFormat.mils6000 : AngleFormat.dms),
        throwsFormatException,
        reason: s,
      );
    }
    expect(() => parseAngle('12.5 30', AngleFormat.dms), throwsFormatException);
  });

  test('round trip', () {
    for (final f in AngleFormat.values) {
      for (var d = 0.0; d < 360; d += 7.3) {
        final text = formatAngle(d, f, decimals: f == AngleFormat.dms ? 1 : 4);
        final back = parseAngle(text, f);
        final tol = f.isMils ? 360 / f.unitsPerCircle / 2 : 1e-4;
        expect(normalizeSignedDegrees(back - d).abs(), lessThanOrEqualTo(tol), reason: '$f $text');
      }
    }
  });
}
