import 'dart:io';
import 'dart:math' as math;

/// Rows of a fixture CSV as maps keyed by the header.
List<Map<String, String>> readCsv(String name) {
  final lines = File('test/fixtures/$name').readAsLinesSync();
  final header = lines.first.split(',');
  return [
    for (final l in lines.skip(1).where((l) => l.isNotEmpty))
      Map.fromIterables(header, l.split(',')),
  ];
}

extension RowNum on Map<String, String> {
  double d(String k) => double.parse(this[k]!);
  int i(String k) => int.parse(this[k]!);
}

/// Metres per degree of latitude, close enough for error reporting.
const mPerDegLat = 111320.0;
double mPerDegLon(double lat) => 111320.0 * math.cos(lat * math.pi / 180);

/// Ground distance between two lat/lon pairs in metres (small separations).
double groundError(double lat1, double lon1, double lat2, double lon2) {
  final dy = (lat1 - lat2) * mPerDegLat;
  var dl = lon1 - lon2;
  if (dl > 180) dl -= 360;
  if (dl < -180) dl += 360;
  final dx = dl * mPerDegLon(lat1);
  return math.sqrt(dx * dx + dy * dy);
}

/// Tracks the worst error of a test series and prints it, so that the CI log
/// shows how close the implementation is to the reference.
class MaxError {
  MaxError(this.label, this.unit);
  final String label, unit;
  double max = 0;
  int n = 0;

  double add(double e) {
    n++;
    if (e > max) max = e;
    return e;
  }

  void report() => print('$label: max ${max.toStringAsExponential(2)} $unit over $n');
}
