import 'package:horyzontal_geo/horyzontal_geo.dart';

import '../../core/data/model.dart';
import '../../core/labels.dart';
import '../../core/settings.dart';
import '../../l10n/app_localizations.dart';

/// Plain text of a point for messengers: name, the user's default system,
/// WGS 84 and MGRS (readable by anyone).
String featureShareText(AppLocalizations l, MapFeature f, AppSettings s) {
  final p = f.position;
  final systems = {s.system, CoordinateSystem.wgs84, CoordinateSystem.mgrs};
  return [
    if (f.name.isNotEmpty) f.name,
    for (final sys in systems)
      if (_safe(p, sys, s.geoFormat) case final v?) '${systemName(l, sys)}: $v',
    if (f.description.isNotEmpty) f.description,
    if (f.author.isNotEmpty) '${l.author}: ${f.author}',
  ].join('\n');
}

String? _safe(Geodetic p, CoordinateSystem sys, GeoFormat f) {
  try {
    return formatPoint(p, sys, f);
  } on RangeError {
    return null;
  }
}

String formatDateTime(DateTime t) {
  String two(int v) => v.toString().padLeft(2, '0');
  final l = t.toLocal();
  return '${two(l.day)}.${two(l.month)}.${l.year} ${two(l.hour)}:${two(l.minute)}';
}
