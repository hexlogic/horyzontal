import 'dart:convert';

import 'package:horyzontal_geo/horyzontal_geo.dart';
import 'package:xml/xml.dart';

import '../../../core/data/ids.dart';
import '../../../core/data/model.dart';
import 'bundle.dart';
import 'common.dart';

// GPX 1.1. Points are waypoints, polylines tracks, polygons closed tracks
// flagged `<hrz:kind>polygon</hrz:kind>`. App fields live in `hrz:`
// extensions; colours are also written as `osmand:color` so OsmAnd shows
// them. Several layers share one file: `metadata/extensions` lists them and
// every element names its layer, so the app splits them again while other
// apps see one file.

const hrzGpxNs = 'https://github.com/hexlogic/horyzontal/xmlns/gpx/1';
const osmandNs = 'https://osmand.net';
const _gpxNs = 'http://www.topografix.com/GPX/1/1';

String encodeGpx(List<LayerBundle> layers, {required DateTime now, String appVersion = ''}) {
  final b = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln(
      '<gpx version="1.1" creator="${esc('Horyzontal $appVersion'.trim())}" '
      'xmlns="$_gpxNs" xmlns:hrz="$hrzGpxNs" xmlns:osmand="$osmandNs">',
    )
    ..writeln('  <metadata>')
    ..writeln('    <name>${esc(layers.map((l) => l.layer.name).join(', '))}</name>')
    ..writeln('    <time>${iso(now)}</time>')
    ..writeln('    <extensions>');
  for (final l in layers) {
    final y = l.layer;
    b.writeln(
      '      <hrz:layer id="${esc(y.id)}" name="${esc(y.name)}" color="${colorHex(y.color)}" '
      'created="${iso(y.createdAt)}" updated="${iso(y.updatedAt)}"/>',
    );
  }
  b.writeln('    </extensions>');
  b.writeln('  </metadata>');
  final all = [
    for (final l in layers)
      for (final f in l.features) (l.layer, f),
  ];
  // GPX orders wpt before trk.
  for (final (layer, f) in all.where((e) => e.$2.kind == FeatureKind.point)) {
    final p = f.position;
    b.writeln('  <wpt lat="${fmtDeg(p.lat)}" lon="${fmtDeg(p.lon)}">');
    if (p.h != 0) b.writeln('    <ele>${fmtAlt(p.h)}</ele>');
    b.writeln('    <time>${iso(f.createdAt)}</time>');
    _texts(b, f, '    ');
    _extensions(b, f, layer, '    ');
    b.writeln('  </wpt>');
  }
  for (final (layer, f) in all.where((e) => e.$2.kind != FeatureKind.point)) {
    b.writeln('  <trk>');
    _texts(b, f, '    ');
    _extensions(b, f, layer, '    ');
    b.writeln('    <trkseg>');
    final vs = f.kind == FeatureKind.polygon ? [...f.vertices, f.vertices.first] : f.vertices;
    for (final v in vs) {
      b.write('      <trkpt lat="${fmtDeg(v.lat)}" lon="${fmtDeg(v.lon)}"');
      b.writeln(v.h != 0 ? '><ele>${fmtAlt(v.h)}</ele></trkpt>' : '/>');
    }
    b
      ..writeln('    </trkseg>')
      ..writeln('  </trk>');
  }
  b.writeln('</gpx>');
  return b.toString();
}

void _texts(StringBuffer b, MapFeature f, String i) {
  if (f.name.isNotEmpty) b.writeln('$i<name>${esc(f.name)}</name>');
  if (f.description.isNotEmpty) b.writeln('$i<desc>${esc(f.description)}</desc>');
}

void _extensions(StringBuffer b, MapFeature f, MapLayer layer, String i) {
  void x(String name, String value) => b.writeln('$i  <hrz:$name>${esc(value)}</hrz:$name>');
  b.writeln('$i<extensions>');
  x('id', f.id);
  x('layer', layer.id);
  if (f.kind == FeatureKind.polygon) x('kind', 'polygon');
  if (f.sidc != null) x('sidc', f.sidc!);
  if (f.author.isNotEmpty) x('author', f.author);
  if (f.color != null) x('color', colorHex(f.color!));
  if (f.radius != null) x('radius', '${f.radius}');
  x('created', iso(f.createdAt));
  x('updated', iso(f.updatedAt));
  if (f.extra.isNotEmpty) x('extra', jsonEncode(f.extra, toEncodable: (o) => o.toString()));
  b.writeln('$i  <osmand:color>${colorHex(f.color ?? layer.color)}</osmand:color>');
  b.writeln('$i</extensions>');
}

// ---------------------------------------------------------------------------
// Import

bool _isNs(XmlElement e, String uri, String prefix) =>
    e.name.namespaceUri == uri || e.name.prefix == prefix;

/// Text of the extension child [local] in namespace [uri] / [prefix].
String? _ext(XmlElement e, String local, {String uri = hrzGpxNs, String prefix = 'hrz'}) {
  final ext = kid(e, 'extensions');
  if (ext == null) return null;
  for (final c in ext.childElements) {
    if (c.localName == local && _isNs(c, uri, prefix)) {
      final t = c.innerText.trim();
      return t.isEmpty ? null : t;
    }
  }
  return null;
}

List<LayerBundle> decodeGpx(String text, ImportContext ctx) {
  final root = parseXml(text).rootElement;
  if (root.localName != 'gpx') {
    throw ImportException(ImportException.malformed, 'root <${root.localName}>');
  }
  final meta = kid(root, 'metadata');
  // GPX 1.0 has <name> directly under <gpx>.
  final fileName = (meta == null ? null : kidText(meta, 'name')) ?? kidText(root, 'name');

  // Layers the app wrote, by their original id.
  final declared = <String, MapLayer>{};
  final metaExt = meta == null ? null : kid(meta, 'extensions');
  if (metaExt != null) {
    for (final l in metaExt.childElements) {
      if (l.localName != 'layer' || !_isNs(l, hrzGpxNs, 'hrz')) continue;
      final id = l.getAttribute('id');
      if (id == null) continue;
      final base = ctx.newLayer(
        l.getAttribute('name') ?? '',
        color: parseColor(l.getAttribute('color')),
      );
      final created = parseTime(l.getAttribute('created')) ?? ctx.now;
      declared[id] = MapLayer(
        id: base.id,
        name: base.name,
        color: base.color,
        visible: true,
        archived: false,
        createdAt: created,
        updatedAt: parseTime(l.getAttribute('updated')) ?? created,
      );
    }
  }
  final fallback = declared.length == 1
      ? declared.values.single
      : ctx.newLayer(fileName ?? ctx.baseName);
  final byLayer = <String, List<MapFeature>>{};
  final layers = <String, MapLayer>{};

  void add(XmlElement e, MapFeature Function(String layerId) make) {
    final layer = declared[_ext(e, 'layer')] ?? fallback;
    layers[layer.id] = layer;
    byLayer.putIfAbsent(layer.id, () => []).add(make(layer.id));
  }

  for (final e in root.childElements) {
    switch (e.localName) {
      case 'wpt':
        final v = _point(e, ctx);
        if (v == null) continue;
        add(e, (layerId) => _feature(e, layerId, FeatureKind.point, [v], ctx));
      case 'rte':
        final vs = _points(kids(e, 'rtept'), e, ctx);
        if (vs == null) continue;
        add(e, (layerId) => _feature(e, layerId, FeatureKind.polyline, vs, ctx));
      case 'trk':
        final polygon = _ext(e, 'kind') == 'polygon';
        final segs = kids(e, 'trkseg').toList();
        for (final (i, seg) in segs.indexed) {
          var vs = _points(kids(seg, 'trkpt'), e, ctx);
          if (vs == null) continue;
          var kind = FeatureKind.polyline;
          if (polygon) {
            final open = openRing<Geodetic>(vs, (a, b) => a.lat == b.lat && a.lon == b.lon);
            if (open.length >= 3 && open.length < vs.length) {
              vs = open;
              kind = FeatureKind.polygon;
            }
          }
          final k = kind, points = vs;
          add(e, (layerId) => _feature(e, layerId, k, points, ctx, part: i));
        }
    }
  }
  final out = [
    for (final l in declared.values) LayerBundle(l, dedupe(byLayer[l.id] ?? const [], ctx)),
    if (!declared.values.contains(fallback) && layers.containsKey(fallback.id))
      LayerBundle(fallback, dedupe(byLayer[fallback.id]!, ctx)),
  ];
  if (out.isEmpty) out.add(LayerBundle(fallback, const []));
  return out;
}

Geodetic? _point(XmlElement e, ImportContext ctx) {
  final lat = double.tryParse(e.getAttribute('lat') ?? '');
  final lon = double.tryParse(e.getAttribute('lon') ?? '');
  if (lat == null || lon == null || !validLatLon(lat, lon)) {
    ctx.warn(ImportWarning.badCoordinate, kidText(e, 'name') ?? e.localName);
    return null;
  }
  final h = double.tryParse(kidText(e, 'ele') ?? '') ?? 0;
  return Geodetic(lat, lon, h.isFinite ? h : 0);
}

List<Geodetic>? _points(Iterable<XmlElement> pts, XmlElement owner, ImportContext ctx) {
  final out = <Geodetic>[];
  for (final p in pts) {
    final v = _point(p, ctx);
    if (v == null) return null;
    out.add(v);
  }
  if (out.length < 2) {
    ctx.warn(ImportWarning.invalidFeature, kidText(owner, 'name') ?? owner.localName);
    return null;
  }
  return out;
}

MapFeature _feature(
  XmlElement e,
  String layerId,
  FeatureKind kind,
  List<Geodetic> vertices,
  ImportContext ctx, {
  int part = 0,
}) {
  final id = _ext(e, 'id');
  final own = id != null;
  final created = parseTime(_ext(e, 'created')) ?? parseTime(kidText(e, 'time')) ?? ctx.now;
  final radius = double.tryParse(_ext(e, 'radius') ?? '');
  Map<String, Object?> extra = const {};
  final extraJson = _ext(e, 'extra');
  if (extraJson != null) {
    try {
      final x = jsonDecode(extraJson);
      if (x is Map<String, Object?>) extra = Map.unmodifiable(x);
    } on FormatException {
      // A damaged extra field loses only import leftovers.
    }
  }
  return MapFeature(
    id: id == null
        ? newId()
        : part == 0
        ? featureIdFrom(id)
        : nameUuid('$id#$part'),
    layerId: layerId,
    kind: kind,
    vertices: vertices,
    name: kidText(e, 'name') ?? '',
    description: kidText(e, 'desc') ?? kidText(e, 'cmt') ?? '',
    author: _ext(e, 'author') ?? '',
    sidc: _ext(e, 'sidc'),
    color: own
        ? parseColor(_ext(e, 'color'))
        : parseColor(_ext(e, 'color', uri: osmandNs, prefix: 'osmand')),
    radius: radius != null && radius.isFinite && radius > 0 ? radius : null,
    extra: extra,
    createdAt: created,
    updatedAt: parseTime(_ext(e, 'updated')) ?? created,
  );
}
