import 'package:flutter/material.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

import '../l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

String systemName(AppLocalizations l, CoordinateSystem s) => switch (s) {
  CoordinateSystem.wgs84 => l.sysWgs84,
  CoordinateSystem.utm => l.sysUtm,
  CoordinateSystem.mgrs => l.sysMgrs,
  CoordinateSystem.sk42 => l.sysSk42,
  CoordinateSystem.sk42Gk => l.sysSk42Gk,
  CoordinateSystem.usk2000 => l.sysUsk2000,
  CoordinateSystem.usk2000Gk => l.sysUsk2000Gk,
  CoordinateSystem.usk2000Tm3 => l.sysUsk2000Tm3,
};

String systemHint(AppLocalizations l, CoordinateSystem s) => switch (s) {
  CoordinateSystem.utm => l.hintUtm,
  CoordinateSystem.mgrs => l.hintMgrs,
  CoordinateSystem.usk2000Tm3 => l.hintTm3,
  _ when s.isGrid => l.hintGrid,
  _ => l.hintGeographic,
};

String geoFormatName(AppLocalizations l, GeoFormat f) => switch (f) {
  GeoFormat.degrees => l.geoDegrees,
  GeoFormat.degMin => l.geoDegMin,
  GeoFormat.dms => l.geoDms,
};

String angleFormatName(AppLocalizations l, AngleFormat f) => switch (f) {
  AngleFormat.deg360 => l.angleDeg360,
  AngleFormat.mils6000 => l.angleMils6000,
  AngleFormat.mils6400 => l.angleMils6400,
  AngleFormat.dms => l.angleDms,
};

String coordinateErrorText(AppLocalizations l, CoordinateError e) => switch (e) {
  CoordinateError.empty || CoordinateError.unrecognized => l.errUnrecognized,
  CoordinateError.outOfRange => l.errOutOfRange,
  CoordinateError.missingZone => l.errMissingZone,
  CoordinateError.outsideSystem => l.errOutsideSystem,
};

/// `1234.57 м` below 10 km, `12.346 км` above.
String formatDistance(AppLocalizations l, double metres) => metres < 10000
    ? l.metres(metres.toStringAsFixed(2))
    : l.kilometres((metres / 1000).toStringAsFixed(3));

/// Display text of [wgs] in [system] with the user's geographic format.
/// The 3° cadastral grid keeps centimetres, as surveyors expect.
String formatPoint(Geodetic wgs, CoordinateSystem system, GeoFormat geoFormat, {int? zone}) =>
    formatCoordinates(
      wgs,
      system,
      geoFormat: geoFormat,
      zone: zone,
      metreDecimals: system == CoordinateSystem.usk2000Tm3 ? 2 : 0,
    );
