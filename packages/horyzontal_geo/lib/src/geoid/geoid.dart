import 'dart:convert';
import 'dart:typed_data';

import 'egm2008_ukraine.dart';

/// EGM2008 geoid height for Ukraine and the surrounding area (21.5-41°E,
/// 43.5-53.5°N), bilinear on a 5' grid; within about 0.1 m of the full model.
class Geoid {
  Geoid._() {
    final bytes = base64.decode(egm2008Data);
    _cm = bytes.buffer.asInt16List(bytes.offsetInBytes, bytes.lengthInBytes ~/ 2);
  }

  static final egm2008Ukraine = Geoid._();

  static const _step = 1 / 12;
  late final Int16List _cm;

  /// Geoid undulation N in metres at WGS 84 [lat], [lon], or null outside the
  /// grid. Height above sea level = ellipsoidal height - N.
  double? undulation(double lat, double lon) {
    final fx = (lon - egm2008Lon0) / _step, fy = (lat - egm2008Lat0) / _step;
    if (fx < 0 || fy < 0 || fx > egm2008Columns - 1 || fy > egm2008Rows - 1) return null;
    final i = fx.floor().clamp(0, egm2008Columns - 2), j = fy.floor().clamp(0, egm2008Rows - 2);
    final dx = fx - i, dy = fy - j;
    double at(int c, int r) => _cm[r * egm2008Columns + c] / 100;
    return at(i, j) * (1 - dx) * (1 - dy) +
        at(i + 1, j) * dx * (1 - dy) +
        at(i, j + 1) * (1 - dx) * dy +
        at(i + 1, j + 1) * dx * dy;
  }
}
