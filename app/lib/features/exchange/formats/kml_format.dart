import 'dart:convert';
import 'dart:typed_data';

import 'package:horyzontal_geo/horyzontal_geo.dart';
import 'package:xml/xml.dart';

import '../../../core/data/ids.dart';
import '../../../core/data/model.dart';
import 'bundle.dart';
import 'common.dart';
import 'zip_util.dart';

// KML 2.2 (Google Earth, ATAK, OsmAnd, QGIS…). One Folder per layer, app
// fields in ExtendedData under `hrz:` names, styles inline per placemark.

const _hrz = 'hrz:';

/// KML `aabbggrr` from ARGB.
String kmlColor(int argb) {
  String h(int v) => (v & 0xFF).toRadixString(16).padLeft(2, '0');
  return '${h(argb >> 24)}${h(argb)}${h(argb >> 8)}${h(argb >> 16)}';
}

/// ARGB from KML `aabbggrr` (a leading `#` and 6-digit `bbggrr` tolerated).
int? parseKmlColor(String? s) {
  if (s == null) return null;
  var t = s.trim();
  if (t.startsWith('#')) t = t.substring(1);
  if (t.length == 6) t = 'ff$t';
  if (t.length != 8) return null;
  final v = int.tryParse(t, radix: 16);
  if (v == null) return null;
  final a = (v >> 24) & 0xFF, b = (v >> 16) & 0xFF, g = (v >> 8) & 0xFF, r = v & 0xFF;
  return (a << 24) | (r << 16) | (g << 8) | b;
}

String encodeKml(List<LayerBundle> layers, {required String documentName}) {
  final b = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<kml xmlns="http://www.opengis.net/kml/2.2">')
    ..writeln('<Document>')
    ..writeln('  <name>${esc(documentName)}</name>');
  for (final l in layers) {
    writeKmlFolder(b, l);
  }
  b
    ..writeln('</Document>')
    ..writeln('</kml>');
  return b.toString();
}

/// One layer as a `<Folder>`; [only] limits the features written.
void writeKmlFolder(StringBuffer b, LayerBundle l, {bool Function(MapFeature)? only}) {
  final layer = l.layer;
  b
    ..writeln('  <Folder>')
    ..writeln('    <name>${esc(layer.name)}</name>')
    ..writeln('    <ExtendedData>');
  _data(b, 'layerId', layer.id, 6);
  _data(b, 'color', colorHex(layer.color), 6);
  _data(b, 'created', iso(layer.createdAt), 6);
  _data(b, 'updated', iso(layer.updatedAt), 6);
  b.writeln('    </ExtendedData>');
  for (final f in l.features) {
    if (only != null && !only(f)) continue;
    _placemark(b, f, f.color ?? layer.color);
  }
  b.writeln('  </Folder>');
}

void _data(StringBuffer b, String name, String value, int indent) {
  b.writeln('${' ' * indent}<Data name="$_hrz$name"><value>${esc(value)}</value></Data>');
}

void _placemark(StringBuffer b, MapFeature f, int color) {
  b.writeln('    <Placemark>');
  b.writeln('      <name>${esc(f.name)}</name>');
  if (f.description.isNotEmpty) b.writeln('      <description>${esc(f.description)}</description>');
  b.writeln('      <Style>');
  switch (f.kind) {
    case FeatureKind.point:
      b.writeln('        <IconStyle><color>${kmlColor(color)}</color></IconStyle>');
    case FeatureKind.polyline:
      b.writeln('        <LineStyle><color>${kmlColor(color)}</color><width>3</width></LineStyle>');
    case FeatureKind.polygon:
      b
        ..writeln(
          '        <LineStyle><color>${kmlColor(color)}</color><width>2</width></LineStyle>',
        )
        ..writeln(
          '        <PolyStyle><color>${kmlColor((color & 0xFFFFFF) | 0x40000000)}</color></PolyStyle>',
        );
  }
  b
    ..writeln('      </Style>')
    ..writeln('      <ExtendedData>');
  _data(b, 'id', f.id, 8);
  if (f.sidc != null) _data(b, 'sidc', f.sidc!, 8);
  if (f.author.isNotEmpty) _data(b, 'author', f.author, 8);
  if (f.radius != null) _data(b, 'radius', '${f.radius}', 8);
  if (f.color != null) _data(b, 'color', colorHex(f.color!), 8);
  _data(b, 'created', iso(f.createdAt), 8);
  _data(b, 'updated', iso(f.updatedAt), 8);
  if (f.extra.isNotEmpty) {
    _data(b, 'extra', jsonEncode(f.extra, toEncodable: (o) => o.toString()), 8);
  }
  b.writeln('      </ExtendedData>');
  final has3d = f.vertices.any((v) => v.h != 0);
  final mode = has3d ? '<altitudeMode>absolute</altitudeMode>' : '';
  String coords(List<Geodetic> vs) =>
      vs.map((v) => '${fmtDeg(v.lon)},${fmtDeg(v.lat)}${has3d ? ',${fmtAlt(v.h)}' : ''}').join(' ');
  switch (f.kind) {
    case FeatureKind.point:
      b.writeln(
        '      <Point>$mode<coordinates>${coords(f.vertices.take(1).toList())}</coordinates></Point>',
      );
    case FeatureKind.polyline:
      b
        ..writeln('      <LineString>$mode')
        ..writeln('        <coordinates>${coords(f.vertices)}</coordinates>')
        ..writeln('      </LineString>');
    case FeatureKind.polygon:
      b
        ..writeln('      <Polygon>$mode')
        ..writeln('        <outerBoundaryIs><LinearRing>')
        ..writeln(
          '          <coordinates>${coords([...f.vertices, f.vertices.first])}</coordinates>',
        )
        ..writeln('        </LinearRing></outerBoundaryIs>')
        ..writeln('      </Polygon>');
  }
  b.writeln('    </Placemark>');
}

Uint8List encodeKmz(List<LayerBundle> layers, {required String documentName, DateTime? now}) =>
    buildZip({'doc.kml': utf8.encode(encodeKml(layers, documentName: documentName))}, time: now);

// ---------------------------------------------------------------------------
// Import

/// Layers of a KMZ: `doc.kml`, else the first `.kml` at the root, else any.
List<(String?, LayerBundle)> decodeKmzLayers(
  Uint8List bytes,
  ImportContext ctx,
  SizeBudget budget,
) => decodeKmzZip(SafeZip.open(bytes, budget), ctx);

List<(String?, LayerBundle)> decodeKmzZip(SafeZip zip, ImportContext ctx) {
  final kmls = zip.entries.keys.where((k) => k.toLowerCase().endsWith('.kml')).toList();
  if (kmls.isEmpty) throw const ImportException(ImportException.malformed, 'no .kml in archive');
  final main =
      zip.find('doc.kml') ?? kmls.firstWhere((k) => !k.contains('/'), orElse: () => kmls.first);
  return decodeKmlLayers(decodeText(zip.read(main)), ctx);
}

class _Group {
  _Group(this.name, this.meta);

  final String name;
  final Map<String, String> meta;
  final placemarks = <XmlElement>[];
}

List<LayerBundle> decodeKml(String text, ImportContext ctx) => [
  for (final (_, b) in decodeKmlLayers(text, ctx)) b,
];

/// Layers with the id they had in the exporting app (`hrz:layerId`), if any.
List<(String?, LayerBundle)> decodeKmlLayers(String text, ImportContext ctx) {
  final doc = parseXml(text);
  final root = doc.rootElement;
  if (root.localName != 'kml' && root.localName != 'Document' && root.localName != 'Folder') {
    throw ImportException(ImportException.malformed, 'root <${root.localName}>');
  }
  final styles = <String, XmlElement>{};
  for (final e in root.descendantElements) {
    if (e.localName == 'Style' || e.localName == 'StyleMap') {
      final id = e.getAttribute('id');
      if (id != null) styles[id] = e;
    }
  }

  // The top container: <kml>, or its single <Document>.
  var top = root;
  if (root.localName == 'kml') {
    final docs = root.childElements.where((e) => e.localName == 'Document').toList();
    if (docs.length == 1) top = docs.single;
  }
  final groups = <_Group>[];
  final topName = kidText(top, 'name') ?? ctx.baseName;

  void walk(XmlElement container, List<String> path, _Group group) {
    for (final e in container.childElements) {
      switch (e.localName) {
        case 'Placemark':
          group.placemarks.add(e);
        case 'Folder' || 'Document':
          final name = kidText(e, 'name');
          final p = [...path, ?name];
          final g = _Group(p.isEmpty ? topName : p.join(' / '), _extendedData(e));
          groups.add(g);
          walk(e, p, g);
        case 'NetworkLink' || 'GroundOverlay' || 'ScreenOverlay' || 'PhotoOverlay':
          ctx.warn(ImportWarning.overlayIgnored, kidText(e, 'name') ?? e.localName);
      }
    }
  }

  final rootGroup = _Group(topName, _extendedData(top));
  groups.add(rootGroup);
  walk(top, [], rootGroup);

  final out = <(String?, LayerBundle)>[];
  for (final g in groups) {
    final isLayer = g.meta.containsKey('${_hrz}layerId');
    if (g.placemarks.isEmpty && !isLayer) continue;
    var layer = ctx.newLayer(g.name, color: parseColor(g.meta['${_hrz}color']));
    final created = parseTime(g.meta['${_hrz}created']);
    if (created != null) {
      layer = MapLayer(
        id: layer.id,
        name: layer.name,
        color: layer.color,
        visible: true,
        archived: false,
        createdAt: created,
        updatedAt: parseTime(g.meta['${_hrz}updated']) ?? created,
      );
    }
    final features = <MapFeature>[];
    for (final p in g.placemarks) {
      features.addAll(_placemarkFeatures(p, layer.id, styles, ctx));
    }
    out.add((g.meta['${_hrz}layerId'], LayerBundle(layer, dedupe(features, ctx))));
  }
  return out;
}

Map<String, String> _extendedData(XmlElement e) {
  final ext = kid(e, 'ExtendedData');
  if (ext == null) return const {};
  final out = <String, String>{};
  for (final d in ext.descendantElements) {
    if (d.localName == 'Data') {
      final name = d.getAttribute('name');
      final value = kid(d, 'value')?.innerText.trim();
      if (name != null && value != null) out[name] = value;
    } else if (d.localName == 'SimpleData') {
      final name = d.getAttribute('name');
      if (name != null) out[name] = d.innerText.trim();
    }
  }
  return out;
}

/// The `<Style>` that applies to [p] (inline first, then `styleUrl`,
/// following a StyleMap to its `normal` pair).
XmlElement? _style(XmlElement p, Map<String, XmlElement> styles) {
  XmlElement? resolve(XmlElement? s, int depth) {
    if (s == null || depth > 4) return null;
    if (s.localName == 'Style') return s;
    if (s.localName == 'StyleMap') {
      for (final pair in kids(s, 'Pair')) {
        if ((kidText(pair, 'key') ?? 'normal') != 'normal') continue;
        final inline = kid(pair, 'Style');
        if (inline != null) return inline;
        return resolve(_byUrl(kidText(pair, 'styleUrl'), styles), depth + 1);
      }
    }
    return null;
  }

  return resolve(kid(p, 'Style') ?? kid(p, 'StyleMap'), 0) ??
      resolve(_byUrl(kidText(p, 'styleUrl'), styles), 0);
}

XmlElement? _byUrl(String? url, Map<String, XmlElement> styles) {
  if (url == null) return null;
  final hash = url.lastIndexOf('#');
  return styles[hash < 0 ? url : url.substring(hash + 1)];
}

int? _styleColor(XmlElement? style, FeatureKind kind) {
  if (style == null) return null;
  int? of(String sub) {
    final s = kid(style, sub);
    return s == null ? null : parseKmlColor(kidText(s, 'color'));
  }

  return switch (kind) {
    FeatureKind.point => of('IconStyle') ?? of('LabelStyle'),
    FeatureKind.polyline => of('LineStyle'),
    FeatureKind.polygon => of('LineStyle') ?? _opaque(of('PolyStyle')),
  };
}

int? _opaque(int? c) => c == null ? null : c | 0xFF000000;

class _Geometry {
  _Geometry(this.kind, this.vertices);

  final FeatureKind kind;
  final List<Geodetic> vertices;
}

List<MapFeature> _placemarkFeatures(
  XmlElement p,
  String layerId,
  Map<String, XmlElement> styles,
  ImportContext ctx,
) {
  final name = kidText(p, 'name') ?? '';
  final geometries = <_Geometry>[];
  var bad = false;

  void geometry(XmlElement g) {
    switch (g.localName) {
      case 'Point':
        final v = _coordinates(g, ctx, name);
        if (v == null || v.isEmpty) {
          bad = true;
        } else {
          geometries.add(_Geometry(FeatureKind.point, [v.first]));
        }
      case 'LineString':
        final v = _coordinates(g, ctx, name);
        if (v == null || v.length < 2) {
          bad = true;
        } else {
          geometries.add(_Geometry(FeatureKind.polyline, v));
        }
      case 'LinearRing':
        final v = _ring(g, ctx, name);
        if (v == null) {
          bad = true;
        } else {
          geometries.add(_Geometry(FeatureKind.polygon, v));
        }
      case 'Polygon':
        final outer = kid(g, 'outerBoundaryIs');
        final ring = outer == null ? null : kid(outer, 'LinearRing');
        if (kids(g, 'innerBoundaryIs').isNotEmpty) {
          ctx.warn(ImportWarning.innerBoundaryDropped, name);
        }
        final v = ring == null ? null : _ring(ring, ctx, name, mode: kidText(g, 'altitudeMode'));
        if (v == null) {
          bad = true;
        } else {
          geometries.add(_Geometry(FeatureKind.polygon, v));
        }
      case 'MultiGeometry':
        for (final c in g.childElements) {
          geometry(c);
        }
      case 'Track' || 'MultiTrack':
        ctx.warn(ImportWarning.trackIgnored, name);
      case 'Model':
        ctx.warn(ImportWarning.unsupportedGeometry, name);
    }
  }

  final before = ctx.warnings.length;
  for (final c in p.childElements) {
    geometry(c);
  }
  if (geometries.isEmpty) {
    // One warning per placemark: a specific one if a geometry gave one.
    if (ctx.warnings.length == before) ctx.warn(ImportWarning.invalidFeature, name);
    return const [];
  }
  if (bad && ctx.warnings.length == before) ctx.warn(ImportWarning.invalidFeature, name);

  final data = _extendedData(p);
  final own = data.containsKey('${_hrz}id');
  final style = _style(p, styles);
  final when = parseTime(
    kid(p, 'TimeStamp') == null ? null : kidText(kid(p, 'TimeStamp')!, 'when'),
  );
  final created = parseTime(data['${_hrz}created']) ?? when ?? ctx.now;
  final updated = parseTime(data['${_hrz}updated']) ?? created;
  final description = kid(p, 'description')?.innerText.trim() ?? '';
  final sidc = data['${_hrz}sidc'] ?? data['sidc'] ?? data['SIDC'];
  final author = data['${_hrz}author'] ?? data['author'] ?? '';
  final radius = double.tryParse(data['${_hrz}radius'] ?? '');
  Map<String, Object?> extra = const {};
  final extraJson = data['${_hrz}extra'];
  if (extraJson != null) {
    try {
      final e = jsonDecode(extraJson);
      if (e is Map<String, Object?>) extra = Map.unmodifiable(e);
    } on FormatException {
      // Ignored: a damaged extra field loses only import leftovers.
    }
  }
  final baseId = data['${_hrz}id'];
  return [
    for (final (i, g) in geometries.indexed)
      MapFeature(
        id: baseId == null
            ? newId()
            : i == 0
            ? featureIdFrom(baseId)
            : nameUuid('$baseId#$i'),
        layerId: layerId,
        kind: g.kind,
        vertices: g.vertices,
        name: name,
        description: description,
        author: author,
        sidc: sidc == null || sidc.isEmpty ? null : sidc,
        color: own ? parseColor(data['${_hrz}color']) : _styleColor(style, g.kind),
        radius: radius != null && radius.isFinite && radius > 0 ? radius : null,
        extra: extra,
        createdAt: created,
        updatedAt: updated,
      ),
  ];
}

List<Geodetic>? _ring(XmlElement ring, ImportContext ctx, String name, {String? mode}) {
  final v = _coordinates(ring, ctx, name, mode: mode);
  if (v == null) return null;
  final open = openRing<Geodetic>(v, (a, b) => a.lat == b.lat && a.lon == b.lon);
  return open.length < 3 ? null : open;
}

/// Parses `lon,lat[,alt]` tuples. Altitude is kept only for
/// `altitudeMode` absolute (KML's default, clampToGround, ignores it).
List<Geodetic>? _coordinates(XmlElement g, ImportContext ctx, String name, {String? mode}) {
  final text = kidText(g, 'coordinates');
  if (text == null) return null;
  final absolute = (kidText(g, 'altitudeMode') ?? mode) == 'absolute';
  final out = <Geodetic>[];
  final tuples = text.replaceAll(RegExp(r'\s*,\s*'), ',').split(RegExp(r'\s+'));
  for (final t in tuples) {
    if (t.isEmpty) continue;
    final parts = t.split(',');
    if (parts.length < 2) {
      ctx.warn(ImportWarning.badCoordinate, name);
      return null;
    }
    final lon = double.tryParse(parts[0]), lat = double.tryParse(parts[1]);
    final h = parts.length > 2 ? double.tryParse(parts[2]) ?? 0.0 : 0.0;
    if (lat == null || lon == null || !validLatLon(lat, lon)) {
      ctx.warn(ImportWarning.badCoordinate, name);
      return null;
    }
    out.add(Geodetic(lat, lon, absolute && h.isFinite ? h : 0));
  }
  return out;
}
