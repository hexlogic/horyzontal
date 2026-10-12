import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horyzontal/core/settings.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

void main() {
  test('map round trip', () {
    const s = AppSettings(
      system: CoordinateSystem.sk42Gk,
      geoFormat: GeoFormat.dms,
      angleInput: AngleFormat.mils6000,
      angleOutput: AngleFormat.mils6400,
      callsign: 'Сокіл',
      themeMode: ThemeMode.dark,
      biometrics: true,
      lockAfter: Duration(minutes: 5),
    );
    expect(AppSettings.fromMap(s.toMap()), s);
  });

  test('unknown and missing values fall back to defaults', () {
    final s = AppSettings.fromMap({'system': 'pz90', 'lockAfterSeconds': 'x', 'callsign': 'A'});
    expect(s.system, const AppSettings().system);
    expect(s.lockAfter, const AppSettings().lockAfter);
    expect(s.callsign, 'A');
  });
}
