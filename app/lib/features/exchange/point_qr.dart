import 'package:horyzontal_geo/horyzontal_geo.dart';

import '../../core/data/model.dart';

/// One point per QR code. The first line is MGRS, so any phone camera shows
/// readable coordinates; the second line is the app link with everything
/// else. Example:
///
///     36U UA 24182 91607
///     horyzontal://p?ll=50.450100,30.523400&a=170&n=%D0%9A%D0%A1%D0%9F&s=10031000001211000000&c=SOKIL
class PointQr {
  const PointQr({
    required this.position,
    this.id,
    this.name = '',
    this.sidc,
    this.callsign = '',
    this.description = '',
  });

  final Geodetic position;
  final String? id;
  final String name, callsign, description;
  final String? sidc;

  static const maxDescription = 200;

  factory PointQr.of(MapFeature f) => PointQr(
        position: f.position,
        id: f.id,
        name: f.name,
        sidc: f.sidc,
        callsign: f.author,
        description: f.description,
      );

  String encode() {
    final p = position;
    final q = <String, String>{
      'll': '${p.lat.toStringAsFixed(6)},${p.lon.toStringAsFixed(6)}',
      if (p.h != 0) 'a': p.h.toStringAsFixed(0),
      if (name.isNotEmpty) 'n': name,
      's': ?sidc,
      if (callsign.isNotEmpty) 'c': callsign,
      if (description.isNotEmpty)
        'd': description.length > maxDescription ? description.substring(0, maxDescription) : description,
      'i': ?id,
    };
    final link = Uri(scheme: 'horyzontal', host: 'p', queryParameters: q).toString();
    String mgrs;
    try {
      mgrs = mgrsFromWgs84(p).format();
    } on RangeError {
      return link;
    }
    return '$mgrs\n$link';
  }

  /// Finds the app link in scanned text; null if there is none.
  static PointQr? decode(String text) {
    final line = text
        .split(RegExp(r'\s+'))
        .firstWhere((l) => l.startsWith('horyzontal://p'), orElse: () => '');
    if (line.isEmpty) return null;
    final Uri u;
    try {
      u = Uri.parse(line);
    } on FormatException {
      return null;
    }
    final ll = u.queryParameters['ll']?.split(',');
    if (ll == null || ll.length != 2) return null;
    final lat = double.tryParse(ll[0]), lon = double.tryParse(ll[1]);
    if (lat == null || lon == null || lat.abs() > 90 || lon.abs() > 180) return null;
    final alt = double.tryParse(u.queryParameters['a'] ?? '') ?? 0;
    final sidc = u.queryParameters['s'];
    return PointQr(
      position: Geodetic(lat, lon, alt),
      id: u.queryParameters['i'],
      name: u.queryParameters['n'] ?? '',
      sidc: sidc != null && RegExp(r'^\d{20}(\d{10})?$').hasMatch(sidc) ? sidc : null,
      callsign: u.queryParameters['c'] ?? '',
      description: u.queryParameters['d'] ?? '',
    );
  }
}
