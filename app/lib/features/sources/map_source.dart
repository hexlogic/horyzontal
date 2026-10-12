import 'dart:math' as math;

import 'package:flutter/foundation.dart';

enum MapSourceKind { url, file }

/// A raster map source the user added: an XYZ/TMS URL template, or an
/// MBTiles/PMTiles file in Documents/sources.
@immutable
class MapSource {
  const MapSource({
    required this.id,
    required this.name,
    required this.kind,
    this.url,
    this.tms = false,
    this.subdomains = const [],
    this.file,
    this.minZoom = 0,
    this.maxZoom = 19,
    this.tileSize = 256,
    this.attribution = '',
    this.enabled = true,
    this.opacity = 1,
    required this.createdAt,
  });

  final String id, name;
  final MapSourceKind kind;

  /// URL template, see [parseTemplate].
  final String? url;

  /// Rows counted from the south (TMS) instead of from the north (XYZ).
  final bool tms;
  final List<String> subdomains;

  /// File name in Documents/sources.
  final String? file;
  final int minZoom, maxZoom, tileSize;
  final String attribution;
  final bool enabled;
  final double opacity;
  final DateTime createdAt;

  /// The file an area download of a URL source goes to.
  String get downloadFile => '$id.mbtiles';

  MapSource copyWith({
    String? name,
    String? url,
    bool? tms,
    List<String>? subdomains,
    int? minZoom,
    int? maxZoom,
    int? tileSize,
    String? attribution,
    bool? enabled,
    double? opacity,
  }) => MapSource(
    id: id,
    name: name ?? this.name,
    kind: kind,
    url: url ?? this.url,
    tms: tms ?? this.tms,
    subdomains: subdomains ?? this.subdomains,
    file: file,
    minZoom: minZoom ?? this.minZoom,
    maxZoom: maxZoom ?? this.maxZoom,
    tileSize: tileSize ?? this.tileSize,
    attribution: attribution ?? this.attribution,
    enabled: enabled ?? this.enabled,
    opacity: opacity ?? this.opacity,
    createdAt: createdAt,
  );
}

enum TemplateError { empty, notHttps, noHost, noTileCoordinates, quadkey, subdomainsMissing }

/// A checked URL template: `{z}`, `{x}`, `{y}` or `{-y}` (TMS), `{s}` for
/// subdomains, or `{bbox-epsg-3857}` for a WMS GetMap request.
class TileTemplate {
  const TileTemplate(this.url, {required this.tms, required this.host});
  final String url;
  final bool tms;
  final String host;
}

/// Checks a template typed by the user. `{-y}` becomes `{y}` with the TMS
/// scheme, which is how MapLibre takes it. Only https: plain http would
/// show the area being viewed to anyone on the way.
({TileTemplate? template, TemplateError? error}) parseTemplate(String input, {List<String> subdomains = const []}) {
  var t = input.trim();
  if (t.isEmpty) return (template: null, error: TemplateError.empty);
  final probe = Uri.tryParse(t.replaceAll(RegExp(r'\{[^}]*\}'), '0'));
  if (probe == null || probe.scheme != 'https') return (template: null, error: TemplateError.notHttps);
  if (probe.host.isEmpty) return (template: null, error: TemplateError.noHost);
  if (t.contains('{q}') || t.contains('{quadkey}')) return (template: null, error: TemplateError.quadkey);
  if (t.contains('{s}') && subdomains.isEmpty) return (template: null, error: TemplateError.subdomainsMissing);
  final tms = t.contains('{-y}');
  t = t.replaceAll('{-y}', '{y}');
  final xyz = t.contains('{z}') && t.contains('{x}') && t.contains('{y}');
  if (!xyz && !t.contains('{bbox-epsg-3857}')) return (template: null, error: TemplateError.noTileCoordinates);
  // The host with {s} filled in, for the network allow list.
  final host = Uri.parse(t.replaceAll('{s}', subdomains.isEmpty ? '' : subdomains.first)
      .replaceAll(RegExp(r'\{[^}]*\}'), '0')).host;
  return (template: TileTemplate(t, tms: tms, host: host), error: null);
}

/// Every host a URL source may contact.
Set<String> sourceHosts(MapSource s) {
  final url = s.url;
  if (s.kind != MapSourceKind.url || url == null) return const {};
  final subs = s.subdomains.isEmpty ? const [''] : s.subdomains;
  return {
    for (final sub in subs)
      Uri.tryParse(url.replaceAll('{s}', sub).replaceAll(RegExp(r'\{[^}]*\}'), '0'))?.host ?? '',
  }..remove('');
}

/// The `tiles` array for MapLibre: one URL per subdomain.
List<String> tileUrls(MapSource s) {
  final url = s.url!;
  if (!url.contains('{s}')) return [url];
  return [for (final sub in s.subdomains) url.replaceAll('{s}', sub)];
}

/// Web Mercator bounding box of a tile, metres: west, south, east, north.
List<double> tileBbox3857(int z, int x, int y) {
  const r = 20037508.342789244;
  final size = 2 * r / (1 << z);
  final west = -r + x * size, north = r - y * size;
  return [west, north - size, west + size, north];
}

/// The URL of one tile (XYZ row [y], counted from the north).
String tileUrl(MapSource s, int z, int x, int y) {
  final subs = s.subdomains;
  var url = s.url!;
  if (subs.isNotEmpty) url = url.replaceAll('{s}', subs[(x + y) % subs.length]);
  final row = s.tms ? (1 << z) - 1 - y : y;
  final b = tileBbox3857(z, x, y);
  return url
      .replaceAll('{z}', '$z')
      .replaceAll('{x}', '$x')
      .replaceAll('{y}', '$row')
      .replaceAll('{bbox-epsg-3857}', b.map((v) => v.toStringAsFixed(6)).join(','));
}

/// XYZ tile column and row of a point at zoom [z].
(int, int) tileOf(double lat, double lon, int z) {
  final n = 1 << z;
  final x = ((lon + 180) / 360 * n).floor().clamp(0, n - 1);
  final la = lat.clamp(-85.0511, 85.0511) * math.pi / 180;
  final y = ((1 - math.log(math.tan(la) + 1 / math.cos(la)) / math.pi) / 2 * n).floor().clamp(0, n - 1);
  return (x, y);
}

/// Tiles covering a bounding box from [minZoom] to [maxZoom].
Iterable<(int, int, int)> tilesIn(
  ({double south, double west, double north, double east}) b,
  int minZoom,
  int maxZoom,
) sync* {
  for (var z = minZoom; z <= maxZoom; z++) {
    final (x0, y0) = tileOf(b.north, b.west, z);
    final (x1, y1) = tileOf(b.south, b.east, z);
    for (var x = x0; x <= x1; x++) {
      for (var y = y0; y <= y1; y++) {
        yield (z, x, y);
      }
    }
  }
}

int tileCount(({double south, double west, double north, double east}) b, int minZoom, int maxZoom) {
  var n = 0;
  for (var z = minZoom; z <= maxZoom; z++) {
    final (x0, y0) = tileOf(b.north, b.west, z);
    final (x1, y1) = tileOf(b.south, b.east, z);
    n += (x1 - x0 + 1) * (y1 - y0 + 1);
  }
  return n;
}
