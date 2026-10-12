/// Angle notations used in the field.
enum AngleFormat {
  /// Decimal degrees, full circle 360°.
  deg360(360),

  /// Mils of the goniometer (поділки кутоміра), 60-00 per circle: `15-30`.
  mils6000(6000),

  /// NATO mils, 64-00 per circle: `16-32`.
  mils6400(6400),

  /// Degrees, minutes, seconds: `123°27'05"`.
  dms(360);

  const AngleFormat(this.unitsPerCircle);
  final int unitsPerCircle;

  bool get isMils => this == mils6000 || this == mils6400;
}

/// Reduces [deg] to [0, 360).
double normalizeDegrees(double deg) {
  final r = deg % 360;
  return r == 360 ? 0 : r;
}

/// Reduces [deg] to (-180, 180].
double normalizeSignedDegrees(double deg) {
  final r = normalizeDegrees(deg);
  return r > 180 ? r - 360 : r;
}

double degreesToUnits(double deg, AngleFormat f) => deg * f.unitsPerCircle / 360;
double unitsToDegrees(double units, AngleFormat f) => units * 360 / f.unitsPerCircle;

/// Formats [degrees] in [format]. Directions are reduced to [0, 360);
/// [signed] keeps a sign instead (declination, convergence, deviations).
/// [decimals] applies to degrees (default 2) and DMS seconds (default 0).
String formatAngle(double degrees, AngleFormat format, {bool signed = false, int? decimals}) {
  var d = signed ? normalizeSignedDegrees(degrees) : normalizeDegrees(degrees);
  final neg = d < 0;
  d = d.abs();
  final sign = neg ? '-' : (signed && d != 0 ? '+' : '');
  switch (format) {
    case AngleFormat.deg360:
      final dec = decimals ?? 2;
      var s = d.toStringAsFixed(dec);
      if (!signed && double.parse(s) >= 360) s = 0.toStringAsFixed(dec);
      return '$sign$s°';
    case AngleFormat.mils6000:
    case AngleFormat.mils6400:
      var u = degreesToUnits(d, format).round();
      if (!signed && u >= format.unitsPerCircle) u -= format.unitsPerCircle;
      final hi = u ~/ 100, lo = u % 100;
      return '$sign$hi-${lo.toString().padLeft(2, '0')}';
    case AngleFormat.dms:
      final dec = decimals ?? 0;
      final scale = _pow10(dec);
      var total = (d * 3600 * scale).round(); // in 10^-dec seconds
      if (!signed && total >= 360 * 3600 * scale) total -= 360 * 3600 * scale;
      final deg = total ~/ (3600 * scale);
      final min = (total ~/ (60 * scale)) % 60;
      final sec = (total % (60 * scale)) / scale;
      final secStr = sec.toStringAsFixed(dec).padLeft(dec == 0 ? 2 : dec + 3, '0');
      return "$sign$deg°${min.toString().padLeft(2, '0')}'$secStr\"";
  }
}

int _pow10(int n) {
  var r = 1;
  for (var i = 0; i < n; i++) {
    r *= 10;
  }
  return r;
}

final _number = RegExp(r'\d+(?:\.\d*)?|\.\d+');

/// Parses an angle typed in [format] and returns degrees.
///
/// Mils: `15-30`, `15 30`, `1530`, `0-05`, `-0-12`. Degrees and DMS accept
/// either notation, so a degree value can be pasted into a DMS field:
/// `123.45`, `123,45°`, `123°27'05"`, `123 27 05`, `123°27.5'`.
double parseAngle(String input, AngleFormat format) {
  var s = input.trim().replaceAll(',', '.').replaceAll(RegExp(r'\s+'), ' ');
  if (s.isEmpty) throw FormatException('Empty angle', input);
  var neg = false;
  if (s.startsWith('-') || s.startsWith('−')) {
    neg = true;
    s = s.substring(1).trim();
  } else if (s.startsWith('+')) {
    s = s.substring(1).trim();
  }
  final double deg;
  if (format.isMils) {
    final m = RegExp(r'^(\d+)\s*[-–—. ]\s*(\d{1,2})$').firstMatch(s);
    final double units;
    if (m != null) {
      units = int.parse(m[1]!) * 100.0 + int.parse(m[2]!);
    } else if (RegExp(r'^\d+$').hasMatch(s)) {
      units = double.parse(s);
    } else {
      throw FormatException('Not a mil value', input);
    }
    deg = unitsToDegrees(units, format);
  } else {
    deg = _parseDegrees(s, input);
  }
  return neg ? -deg : deg;
}

double _parseDegrees(String s, String input) {
  final cleaned = s
      .replaceAll(RegExp('[º˚]'), '°')
      .replaceAll(RegExp('[′’‘ʹ`´]'), "'")
      .replaceAll(RegExp('[″”“ʺ]'), '"')
      .replaceAll("''", '"');
  if (!RegExp(r'''^[\d.°'" ]+$''').hasMatch(cleaned)) {
    throw FormatException('Not an angle', input);
  }
  final parts = _number.allMatches(cleaned).map((m) => double.parse(m[0]!)).toList();
  if (parts.isEmpty || parts.length > 3) {
    throw FormatException('Not an angle', input);
  }
  for (var i = 1; i < parts.length; i++) {
    if (parts[i] >= 60) throw FormatException('Minutes or seconds over 60', input);
    if (parts[i - 1] != parts[i - 1].truncateToDouble()) {
      throw FormatException('Only the last component may have decimals', input);
    }
  }
  var deg = parts[0];
  if (parts.length > 1) deg += parts[1] / 60;
  if (parts.length > 2) deg += parts[2] / 3600;
  return deg;
}
