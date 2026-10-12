import 'datum.dart';
import 'utm.dart';

/// MGRS grid reference on WGS 84 (UTM part, 80°S..84°N; polar UPS areas are
/// not supported).
class MgrsPoint {
  const MgrsPoint(this.zone, this.band, this.square, this.easting, this.northing, this.digits);

  final int zone;
  final String band;

  /// 100 km square identifier, two letters.
  final String square;

  /// Easting and northing within the square, metres (0..99999.x).
  final double easting, northing;

  /// Digits per coordinate, 1..5.
  final int digits;

  /// `36U UA 24182 91607`; coordinates are truncated, as MGRS requires.
  String format({bool spaces = true}) {
    final div = _pow10(5 - digits);
    String part(double v) => (v ~/ div).toString().padLeft(digits, '0');
    final sep = spaces ? ' ' : '';
    final z = zone.toString().padLeft(2, '0');
    if (digits == 0) return '$z$band$sep$square';
    return '$z$band$sep$square$sep${part(easting)}$sep${part(northing)}';
  }

  @override
  String toString() => format();
}

const _columns = ['ABCDEFGH', 'JKLMNPQR', 'STUVWXYZ'];
const _rows = 'ABCDEFGHJKLMNPQRSTUV';

int _pow10(int n) {
  var r = 1;
  for (var i = 0; i < n; i++) {
    r *= 10;
  }
  return r;
}

MgrsPoint mgrsFromWgs84(Geodetic g, {int digits = 5}) {
  final u = utmFromWgs84(g);
  return mgrsFromUtm(u, digits: digits);
}

MgrsPoint mgrsFromUtm(UtmPoint u, {int digits = 5}) {
  // Truncate to 1 µm first so that floating point noise right below a
  // kilometre line does not flip the square.
  final e = (u.easting * 1e6).floorToDouble() / 1e6;
  final n = (u.northing * 1e6).floorToDouble() / 1e6;
  final col = (e / 100000).floor();
  final row = (n / 100000).floor();
  final set = (u.zone - 1) % 3;
  final colLetter = _columns[set][col - 1];
  final rowLetter = _rows[(row + (u.zone.isEven ? 5 : 0)) % 20];
  return MgrsPoint(
    u.zone,
    u.band,
    '$colLetter$rowLetter',
    e - col * 100000,
    n - row * 100000,
    digits,
  );
}

final _mgrsPattern = RegExp(
  r'^(\d{1,2})\s*([C-HJ-NP-X])\s*([A-HJ-NP-Z])\s*([A-HJ-NP-V])\s*(\d*)\s*(\d*)$',
);

/// Parses `36UUA2418291607`, `36U UA 24182 91607`, `36U UA 2418 9160`, etc.
/// Returns the south-west corner of the referenced cell plus half a cell, so
/// a reduced-precision reference lands in the middle of its square.
MgrsPoint parseMgrs(String input) {
  final s = input.trim().toUpperCase();
  final m = _mgrsPattern.firstMatch(s);
  if (m == null) throw FormatException('Not an MGRS reference', input);
  final zone = int.parse(m[1]!);
  if (zone < 1 || zone > 60) throw FormatException('Bad UTM zone', input);
  var e = m[5]!, n = m[6]!;
  if (n.isEmpty && e.length.isEven) {
    n = e.substring(e.length ~/ 2);
    e = e.substring(0, e.length ~/ 2);
  }
  if (e.length != n.length || e.length > 5) {
    throw FormatException('Easting and northing must have equal length', input);
  }
  return MgrsPoint(
    zone,
    m[2]!,
    '${m[3]}${m[4]}',
    e.isEmpty ? 0 : int.parse(e) * _pow10(5 - e.length).toDouble(),
    n.isEmpty ? 0 : int.parse(n) * _pow10(5 - n.length).toDouble(),
    e.length,
  );
}

UtmPoint mgrsToUtm(MgrsPoint p, {bool centre = false}) {
  final set = (p.zone - 1) % 3;
  final col = _columns[set].indexOf(p.square[0]);
  var row = _rows.indexOf(p.square[1]);
  if (col < 0 || row < 0) {
    throw FormatException('Bad 100 km square ${p.square} for zone ${p.zone}');
  }
  row = (row - (p.zone.isEven ? 5 : 0)) % 20;
  final half = centre ? _pow10(5 - p.digits) / 2 : 0;
  final easting = (col + 1) * 100000 + p.easting + half;
  var northing = row * 100000 + p.northing + half;

  // The row letters repeat every 2000 km; pick the cycle that falls into the
  // latitude band. Band south edge northing, less some slack because the
  // edge is curved in grid coordinates.
  final south = utmBandSouth(p.band);
  final bandMin = utmFromWgs84(Geodetic(south, utmCentralMeridian(p.zone)), zone: p.zone).northing;
  while (northing < bandMin - 30000) {
    northing += 2000000;
  }
  return UtmPoint(p.zone, p.band, easting, northing);
}

Geodetic mgrsToWgs84(MgrsPoint p, {bool centre = false}) =>
    utmToWgs84(mgrsToUtm(p, centre: centre));
