import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal/features/exchange/point_qr.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

void main() {
  test('encode and decode a point', () {
    const qr = PointQr(
      position: Geodetic(50.4501, 30.5234, 170),
      id: '0f0e6f5c-2c1b-4c1e-8f7a-1d2e3f4a5b6c',
      name: 'КСП «Береза»',
      sidc: '10031000001211000000',
      callsign: 'СОКІЛ',
      description: 'біля лісосмуги & мосту',
    );
    final text = qr.encode();
    expect(text.split('\n').first, '36U UA 24182 91607');
    final back = PointQr.decode(text)!;
    expect(back.position.lat, closeTo(50.4501, 1e-6));
    expect(back.position.lon, closeTo(30.5234, 1e-6));
    expect(back.position.h, 170);
    expect(back.name, qr.name);
    expect(back.sidc, qr.sidc);
    expect(back.callsign, qr.callsign);
    expect(back.description, qr.description);
    expect(back.id, qr.id);
  });

  test('long descriptions are cut, junk is rejected', () {
    final long = PointQr(position: const Geodetic(1, 2), description: 'x' * 500).encode();
    expect(PointQr.decode(long)!.description, hasLength(PointQr.maxDescription));
    expect(PointQr.decode('hello'), isNull);
    expect(PointQr.decode('horyzontal://p?ll=95,10'), isNull);
    expect(PointQr.decode('horyzontal://p?ll=50,30&s=evil')!.sidc, isNull);
  });
}
