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
      offlineOnly: true,
      onlineMap: false,
      screenshotProtection: true,
      privacyNoticeSeen: true,
      lastSeenVersion: '0.2.0',
      camera: MapCamera(50.45, 30.52, 12.5),
      symbolFavorites: ['10031000001211000000'],
      symbolRecent: ['10061500001116000000', '10031000001211000000'],
      reliefTint: true,
      clustering: false,
    );
    expect(AppSettings.fromMap(s.toMap()), s);
    expect(AppSettings.fromMap(s.toMap()).toMap(), s.toMap());
  });

  test('copyWith changes every field', () {
    const d = AppSettings();
    final changed = d.copyWith(
      offlineOnly: true,
      onlineMap: false,
      screenshotProtection: true,
      privacyNoticeSeen: true,
      lastSeenVersion: 'x',
      camera: const MapCamera(1, 2, 3),
      symbolFavorites: ['10031000001211000000'],
      symbolRecent: ['10031000001211000000'],
      reliefTint: true,
      clustering: false,
    );
    final a = d.toMap(), b = changed.toMap();
    for (final k in ['offlineOnly', 'onlineMap', 'screenshotProtection', 'privacyNoticeSeen',
        'lastSeenVersion', 'camera', 'symbolFavorites', 'symbolRecent', 'reliefTint', 'clustering']) {
      expect(b[k], isNot(a[k]), reason: k);
    }
  });

  test('unknown and missing values fall back to defaults', () {
    final s = AppSettings.fromMap({'system': 'pz90', 'lockAfterSeconds': 'x', 'callsign': 'A'});
    expect(s.system, const AppSettings().system);
    expect(s.lockAfter, const AppSettings().lockAfter);
    expect(s.callsign, 'A');
    expect(s.clustering, isTrue);
    expect(s.reliefTint, isFalse);
  });
}
