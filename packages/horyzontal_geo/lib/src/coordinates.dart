import 'datum.dart';
import 'gauss_kruger.dart';
import 'mgrs.dart';
import 'utm.dart';

/// Coordinate systems the app reads and writes. All conversions go through
/// WGS 84 geodetic coordinates.
enum CoordinateSystem {
  wgs84,
  utm,
  mgrs,
  sk42,
  sk42Gk,
  usk2000,
  usk2000Gk,

  /// УСК-2000 3° cadastral TM zones 7-13 (EPSG:6381-6387).
  usk2000Tm3;

  bool get isGeographic => this == wgs84 || this == sk42 || this == usk2000;
  bool get isGrid => this == sk42Gk || this == usk2000Gk || this == usk2000Tm3;

  /// Zone number is not part of the coordinates and has to be given.
  bool get needsZone => this == usk2000Tm3;

  Datum get datum => switch (this) {
    sk42 || sk42Gk => Datum.sk42,
    usk2000 || usk2000Gk || usk2000Tm3 => Datum.usk2000,
    _ => Datum.wgs84,
  };

  GaussKruger? get grid => switch (this) {
    sk42Gk => GaussKruger.sk42,
    usk2000Gk => GaussKruger.usk2000,
    usk2000Tm3 => GaussKruger.usk2000Tm3,
    _ => null,
  };
}

/// Notation for geographic coordinates.
enum GeoFormat {
  /// `50.450100, 30.523400`
  degrees,

  /// `50°27.0060'N 30°31.4040'E`
  degMin,

  /// `50°27'00.36"N 30°31'24.24"E`
  dms,
}

enum CoordinateError { empty, unrecognized, outOfRange, missingZone, outsideSystem }

class CoordinateParseException implements Exception {
  const CoordinateParseException(this.error, this.input);
  final CoordinateError error;
  final String input;

  @override
  String toString() => 'CoordinateParseException($error, "$input")';
}

/// Formats WGS 84 point [wgs] in [system].
///
/// [zone] forces a grid zone (neighbouring zone across a sheet edge, or the
/// zone of a 3° grid). [metreDecimals] applies to grid and UTM metres.
String formatCoordinates(
  Geodetic wgs,
  CoordinateSystem system, {
  GeoFormat geoFormat = GeoFormat.degrees,
  int mgrsDigits = 5,
  int? zone,
  int metreDecimals = 0,
}) {
  switch (system) {
    case CoordinateSystem.wgs84:
    case CoordinateSystem.sk42:
    case CoordinateSystem.usk2000:
      final g = system.datum.fromWgs84Geodetic(wgs);
      return formatGeographic(g.lat, g.lon, geoFormat);
    case CoordinateSystem.utm:
      final u = utmFromWgs84(wgs);
      return '${u.zone}${u.band} ${_m(u.easting, metreDecimals)} '
          '${_m(u.northing, metreDecimals)}';
    case CoordinateSystem.mgrs:
      return mgrsFromWgs84(wgs, digits: mgrsDigits).format();
    case CoordinateSystem.sk42Gk:
    case CoordinateSystem.usk2000Gk:
    case CoordinateSystem.usk2000Tm3:
      final p = system.grid!.fromWgs84(wgs, zone: zone);
      return formatGrid(p, system, metreDecimals: metreDecimals);
  }
}

/// `5593957 6324233` for 6° grids (X then Y, the zone is in Y), and
/// `5593954 324226 (10)` for the 3° grid.
String formatGrid(GkPoint p, CoordinateSystem system, {int metreDecimals = 0}) {
  final xy = '${_m(p.x, metreDecimals)} ${_m(p.y, metreDecimals)}';
  return system.needsZone ? '$xy (${p.zone})' : xy;
}

String _m(double v, int decimals) => v.toStringAsFixed(decimals);

String formatGeographic(double lat, double lon, GeoFormat f) {
  if (f == GeoFormat.degrees) {
    return '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}';
  }
  return '${_sexagesimal(lat, f, 'N', 'S', 2)} '
      '${_sexagesimal(lon, f, 'E', 'W', 3)}';
}

String _sexagesimal(double v, GeoFormat f, String pos, String neg, int width) {
  final h = v < 0 ? neg : pos;
  final a = v.abs();
  if (f == GeoFormat.degMin) {
    var total = (a * 60 * 10000).round(); // 1e-4 minute ≈ 0.2 m
    final d = total ~/ (60 * 10000);
    total -= d * 60 * 10000;
    final m = (total / 10000).toStringAsFixed(4).padLeft(7, '0');
    return "$d°$m'$h";
  }
  var total = (a * 3600 * 100).round(); // 0.01" ≈ 0.3 m
  final d = total ~/ (3600 * 100);
  total -= d * 3600 * 100;
  final m = total ~/ (60 * 100);
  final s = ((total - m * 60 * 100) / 100).toStringAsFixed(2).padLeft(5, '0');
  return "$d°${m.toString().padLeft(2, '0')}'$s\"$h";
}

/// Parses [input] written in [system] and returns WGS 84 coordinates.
/// [zone] is required for [CoordinateSystem.usk2000Tm3] unless the input
/// names it.
Geodetic parseCoordinates(String input, CoordinateSystem system, {int? zone}) {
  if (input.trim().isEmpty) {
    throw CoordinateParseException(CoordinateError.empty, input);
  }
  switch (system) {
    case CoordinateSystem.wgs84:
    case CoordinateSystem.sk42:
    case CoordinateSystem.usk2000:
      final (lat, lon) = parseGeographic(input);
      return system.datum.toWgs84Geodetic(Geodetic(lat, lon));
    case CoordinateSystem.utm:
      return utmToWgs84(parseUtm(input));
    case CoordinateSystem.mgrs:
      try {
        return mgrsToWgs84(parseMgrs(input), centre: true);
      } on FormatException {
        throw CoordinateParseException(CoordinateError.unrecognized, input);
      }
    case CoordinateSystem.sk42Gk:
    case CoordinateSystem.usk2000Gk:
    case CoordinateSystem.usk2000Tm3:
      return system.grid!.toWgs84(parseGrid(input, system, zone: zone));
  }
}

// --- Geographic -----------------------------------------------------------

const _cyr = 'А-ЯІЇЄҐ';

RegExp _word(String w) => RegExp('(?<![$_cyr])$w(?![$_cyr])');

final _hemiWords = <RegExp, String>{
  RegExp(r'ПН\.?\s*Ш\.?'): ' N ',
  RegExp(r'ПД\.?\s*Ш\.?'): ' S ',
  RegExp(r'СХ\.?\s*Д\.?'): ' E ',
  RegExp(r'ЗХ\.?\s*Д\.?'): ' W ',
  _word('ПН'): ' N ',
  _word('ПД'): ' S ',
  _word('СХ'): ' E ',
  _word('ЗХ'): ' W ',
  // Russian-language sources.
  RegExp(r'С\.?\s*Ш\.?'): ' N ',
  RegExp(r'Ю\.?\s*Ш\.?'): ' S ',
  RegExp(r'В\.?\s*Д\.?'): ' E ',
  RegExp(r'З\.?\s*Д\.?'): ' W ',
};

final _token = RegExp(r'''([+-]?\d+(?:\.\d+)?)\s*([°'"])?|([NSEW])''');

/// Parses latitude and longitude in degrees, degrees-minutes or DMS, with
/// optional hemisphere letters (N/S/E/W, пн/пд/сх/зх) before or after each
/// value, decimal comma or point. Order is latitude, longitude unless the
/// hemisphere letters say otherwise.
(double lat, double lon) parseGeographic(String input) {
  var s = input.toUpperCase().trim();
  s = s
      .replaceAll(RegExp('[º˚]'), '°')
      .replaceAll(RegExp('[′’‘ʹ`´]'), "'")
      .replaceAll(RegExp('[″”“ʺ]'), '"')
      .replaceAll("''", '"')
      .replaceAll('−', '-');
  for (final e in _hemiWords.entries) {
    s = s.replaceAll(e.key, e.value);
  }
  // Decimal commas: if there is no decimal point anywhere and commas sit
  // between digits more than once ("50,45 30,52" or "50,45, 30,52"), or
  // the numbers are otherwise separated, the commas are decimal.
  final digitCommas = RegExp(r'(\d),(\d)').allMatches(s).length;
  final otherSeparators = RegExp(
    r'\d[\s;°'
    "'"
    r'"NSEW]+[+-]?\d',
  ).hasMatch(s.replaceAll(RegExp(r'(\d),(\d)'), r'$1$2'));
  if (!s.contains('.') && digitCommas > 0 && (digitCommas > 1 || otherSeparators)) {
    s = s.replaceAllMapped(RegExp(r'(\d),(\d)'), (m) => '${m[1]}.${m[2]}');
  }
  s = s.replaceAll(RegExp(r'[,;]'), ' ');
  if (RegExp(r'''[^\d\s.°'"+\-NSEW]''').hasMatch(s)) {
    throw CoordinateParseException(CoordinateError.unrecognized, input);
  }

  final tokens = _token.allMatches(s).toList();
  if (tokens.isEmpty) {
    throw CoordinateParseException(CoordinateError.unrecognized, input);
  }

  // Group numbers into the two values.
  final groups = <_Group>[];
  final hasLetters = tokens.any((t) => t[3] != null);
  final letterFirst = tokens.first[3] != null;
  final hasDegreeMarks = tokens.any((t) => t[2] == '°');
  var cur = _Group();
  void close() {
    if (cur.parts.isNotEmpty || cur.hemi != null) groups.add(cur);
    cur = _Group();
  }

  for (final t in tokens) {
    if (t[3] != null) {
      if (letterFirst) {
        close();
        cur.hemi = t[3];
      } else {
        cur.hemi = t[3];
        close();
      }
      continue;
    }
    final mark = t[2];
    if (!hasLetters && hasDegreeMarks && mark == '°' && cur.parts.isNotEmpty) {
      close();
    }
    cur.parts.add(t[1]!);
    cur.marks.add(mark);
    if (!hasLetters && mark == '"') close();
  }
  close();

  if (!hasLetters && !hasDegreeMarks && groups.length == 1) {
    // Bare numbers: 2, 4 or 6 of them split evenly.
    final all = groups.single;
    final n = all.parts.length;
    if (n != 2 && n != 4 && n != 6) {
      throw CoordinateParseException(CoordinateError.unrecognized, input);
    }
    groups
      ..clear()
      ..add(_Group()..parts.addAll(all.parts.sublist(0, n ~/ 2)))
      ..add(_Group()..parts.addAll(all.parts.sublist(n ~/ 2)));
  }
  if (groups.length != 2) {
    throw CoordinateParseException(CoordinateError.unrecognized, input);
  }

  var a = groups[0], b = groups[1];
  if (a.isLongitude || b.isLatitude) (a, b) = (b, a);
  if (a.isLongitude || b.isLatitude) {
    throw CoordinateParseException(CoordinateError.unrecognized, input);
  }
  final lat = a.value(input), lon = b.value(input);
  if (lat.abs() > 90 || lon.abs() > 180) {
    throw CoordinateParseException(CoordinateError.outOfRange, input);
  }
  return (lat, lon);
}

class _Group {
  final parts = <String>[];
  final marks = <String?>[];
  String? hemi;

  bool get isLatitude => hemi == 'N' || hemi == 'S';
  bool get isLongitude => hemi == 'E' || hemi == 'W';

  double value(String input) {
    if (parts.isEmpty || parts.length > 3) {
      throw CoordinateParseException(CoordinateError.unrecognized, input);
    }
    final nums = parts.map(double.parse).toList();
    var neg = nums[0] < 0 || parts[0].startsWith('-');
    var v = nums[0].abs();
    for (var i = 1; i < nums.length; i++) {
      if (nums[i] < 0 || nums[i] >= 60 || nums[i - 1] != nums[i - 1].truncateToDouble()) {
        throw CoordinateParseException(CoordinateError.unrecognized, input);
      }
      v += nums[i] / (i == 1 ? 60 : 3600);
    }
    if (hemi == 'S' || hemi == 'W') neg = !neg;
    return neg ? -v : v;
  }
}

// --- UTM --------------------------------------------------------------------

final _utmPattern = RegExp(
  r'^(\d{1,2})\s*([C-HJ-NP-X])?\s+(\d+(?:[.,]\d+)?)\s*[,;\s]\s*(\d+(?:[.,]\d+)?)$',
);

/// `36U 324183 5591607`. The letter is the latitude band (as GPS receivers
/// write it); without a letter the northern hemisphere is assumed.
UtmPoint parseUtm(String input) {
  final m = _utmPattern.firstMatch(input.trim().toUpperCase());
  if (m == null) throw CoordinateParseException(CoordinateError.unrecognized, input);
  final zone = int.parse(m[1]!);
  final e = double.parse(m[3]!.replaceAll(',', '.'));
  final n = double.parse(m[4]!.replaceAll(',', '.'));
  if (zone < 1 || zone > 60 || e < 100000 || e > 900000 || n > 10000000) {
    throw CoordinateParseException(CoordinateError.outOfRange, input);
  }
  var band = m[2];
  if (band == null) {
    // Northern hemisphere, band from the latitude.
    final g = utmToWgs84(UtmPoint(zone, 'N', e, n));
    band = utmBand(g.lat);
  }
  return UtmPoint(zone, band, e, n);
}

// --- Gauss-Krüger -------------------------------------------------------------

final _labelled = RegExp(r'([XYХУ])\s*[=:]?\s*(\d+(?:[.,]\d+)?)');
final _plainNumber = RegExp(r'\d+(?:[.,]\d+)?');

/// Rectangular coordinates: `5593957 6324233`, `X=5593957 Y=6324233`,
/// `Y 6324233 X 5593957` (Latin or Cyrillic letters). Without labels the
/// order is X, Y; it is swapped when only the swapped reading is valid, or
/// when both are and only the swapped one falls in and around Ukraine. The 3° grid
/// takes the zone from [zone], from a third small number (`5593954 324226 10`
/// or `... (10)`).
GkPoint parseGrid(String input, CoordinateSystem system, {int? zone}) {
  final grid = system.grid!;
  final s = input.toUpperCase();
  double num(String v) => double.parse(v.replaceAll(',', '.'));

  double? x, y;
  final labelled = _labelled.allMatches(s).toList();
  var rest = s;
  if (labelled.length == 2) {
    for (final m in labelled) {
      final isX = m[1] == 'X' || m[1] == 'Х';
      if (isX) {
        x = num(m[2]!);
      } else {
        y = num(m[2]!);
      }
      rest = rest.replaceFirst(m[0]!, ' ');
    }
    if (x == null || y == null) {
      throw CoordinateParseException(CoordinateError.unrecognized, input);
    }
  }
  final numbers = _plainNumber.allMatches(rest).map((m) => m[0]!).toList();

  int? z = zone;
  if (x == null) {
    // A small integer among three numbers is the zone.
    if (numbers.length == 3) {
      final i = numbers.indexWhere((n) => !n.contains(RegExp('[.,]')) && int.parse(n) <= 60);
      if (i < 0) throw CoordinateParseException(CoordinateError.unrecognized, input);
      z = int.parse(numbers.removeAt(i));
    }
    if (numbers.length != 2) {
      throw CoordinateParseException(CoordinateError.unrecognized, input);
    }
    final a = num(numbers[0]), b = num(numbers[1]);
    final ab = _validGrid(grid, a, b, zone: z), ba = _validGrid(grid, b, a, zone: z);
    // Both readings can be valid points (X of 6324233 is ~57°N); then
    // prefer the one in and around Ukraine, else the X-first convention.
    final preferAb = ab && (!ba || _nearUkraine(grid, a, b, z) || !_nearUkraine(grid, b, a, z));
    if (preferAb || !ba) {
      x = a;
      y = b;
    } else {
      x = b;
      y = a;
    }
  } else if (numbers.length == 1 && int.tryParse(numbers.single) != null) {
    z = int.parse(numbers.single);
  }

  if (grid.prefixedEasting) {
    z = grid.zoneFromEasting(y!);
  } else if (z == null) {
    throw CoordinateParseException(CoordinateError.missingZone, input);
  }
  if (!_validGrid(grid, x, y!, zone: z)) {
    throw CoordinateParseException(CoordinateError.outOfRange, input);
  }
  return GkPoint(z!, x, y);
}

bool _nearUkraine(GaussKruger grid, double x, double y, int? zone) {
  final z = grid.prefixedEasting ? grid.zoneFromEasting(y)! : zone ?? 10;
  final g = grid.toGeodetic(GkPoint(z, x, y));
  return g.lat > 43 && g.lat < 53.5 && g.lon > 20 && g.lon < 42;
}

/// Plausible grid reading: the point lies within the zone plus a margin for
/// readings taken in the neighbouring zone.
bool _validGrid(GaussKruger grid, double x, double y, {int? zone}) {
  if (x < 0 || x > 9400000) return false; // up to ~85° latitude
  final z = grid.prefixedEasting ? grid.zoneFromEasting(y)! : zone ?? 10;
  if (z < 1 || z > (grid.prefixedEasting ? 60 : 120)) return false;
  if ((y - grid.falseEasting(z)).abs() > 1000000) return false;
  final g = grid.toGeodetic(GkPoint(z, x, y));
  var dl = (g.lon - grid.centralMeridian(z)) % 360;
  if (dl > 180) dl -= 360;
  return dl.abs() <= grid.zoneWidth * 0.75;
}

/// Datum geodetic coordinates in [system] for display next to the grid
/// value; null for non-geographic systems.
Geodetic? toSystemGeodetic(Geodetic wgs, CoordinateSystem system) =>
    system == CoordinateSystem.mgrs || system == CoordinateSystem.utm
    ? null
    : system.datum.fromWgs84Geodetic(wgs);
