import 'dart:convert';

import 'package:horyzontal_geo/horyzontal_geo.dart';

import '../../../core/data/model.dart';
import 'bundle.dart';
import 'common.dart';

/// The app's own lossless format, versioned JSON:
///
/// ```json
/// {"format": "horyzontal", "version": 1, "exported": "2026-10-12T08:00:00.000Z",
///  "app": "0.1.0", "layers": [{"id": "…", "name": "…", "color": "#FF1565C0",
///  "visible": true, "archived": false, "createdAt": "…", "updatedAt": "…",
///  "features": [{"id": "…", "kind": "point", "name": "…", "description": "…",
///  "author": "…", "sidc": "…", "color": "#FFC62828", "radius": 50.0,
///  "vertices": [[50.45, 30.52, 170.0]], "extra": {}, "createdAt": "…",
///  "updatedAt": "…"}]}]}
/// ```
///
/// Vertices are `[lat, lon]` or `[lat, lon, h]` (h omitted when 0 = unknown).
/// Readers ignore fields they do not know; a version above
/// [hrzVersion] is refused.
const hrzVersion = 1;
const hrzMagic = 'horyzontal';

String encodeHrz(List<LayerBundle> layers, {required DateTime now, String appVersion = ''}) {
  final doc = {
    'format': hrzMagic,
    'version': hrzVersion,
    'exported': iso(now),
    'app': appVersion,
    'layers': [
      for (final b in layers)
        {
          'id': b.layer.id,
          'name': b.layer.name,
          'color': colorHex(b.layer.color),
          'visible': b.layer.visible,
          'archived': b.layer.archived,
          'createdAt': iso(b.layer.createdAt),
          'updatedAt': iso(b.layer.updatedAt),
          'features': [for (final f in b.features) _feature(f)],
        },
    ],
  };
  return const JsonEncoder.withIndent(' ', _encodable).convert(doc);
}

Object? _encodable(Object? o) => o is DateTime ? iso(o) : o.toString();

Map<String, Object?> _feature(MapFeature f) => {
  'id': f.id,
  'kind': f.kind.name,
  'name': f.name,
  if (f.description.isNotEmpty) 'description': f.description,
  if (f.author.isNotEmpty) 'author': f.author,
  if (f.sidc != null) 'sidc': f.sidc,
  if (f.color != null) 'color': colorHex(f.color!),
  if (f.radius != null) 'radius': f.radius,
  'vertices': [
    for (final v in f.vertices) [v.lat, v.lon, if (v.h != 0) v.h],
  ],
  if (f.extra.isNotEmpty) 'extra': f.extra,
  'createdAt': iso(f.createdAt),
  'updatedAt': iso(f.updatedAt),
};

/// Whether [text] is an .hrz document (cheap check before a full parse).
bool looksLikeHrz(String text) {
  final t = text.trimLeft();
  return t.startsWith('{') && t.contains('"format"') && t.contains(hrzMagic);
}

List<LayerBundle> decodeHrz(String text, ImportContext ctx) {
  final Object? doc;
  try {
    doc = jsonDecode(text);
  } on FormatException catch (e) {
    throw ImportException(ImportException.malformed, e.message);
  }
  if (doc is! Map<String, Object?> || doc['format'] != hrzMagic) {
    throw const ImportException(ImportException.malformed, 'not a horyzontal document');
  }
  final version = doc['version'];
  if (version is! int || version < 1) {
    throw ImportException(ImportException.malformed, 'version $version');
  }
  if (version > hrzVersion) {
    throw ImportException(ImportException.unsupportedVersion, '$version');
  }
  final layers = doc['layers'];
  if (layers is! List) throw const ImportException(ImportException.malformed, 'layers');
  final out = <LayerBundle>[];
  for (final l in layers) {
    if (l is! Map<String, Object?>) {
      ctx.warn(ImportWarning.invalidFeature, 'layer');
      continue;
    }
    final layer = MapLayer(
      id: _str(l['id']).isEmpty ? ctx.newLayer('').id : _str(l['id']),
      name: _str(l['name']).isEmpty ? ctx.baseName : _str(l['name']),
      color: parseColor(_colorStr(l['color'])) ?? defaultLayerColor,
      visible: l['visible'] is bool ? l['visible']! as bool : true,
      archived: l['archived'] is bool ? l['archived']! as bool : false,
      createdAt: parseTime(_str(l['createdAt'])) ?? ctx.now,
      updatedAt: parseTime(_str(l['updatedAt'])) ?? ctx.now,
    );
    final features = <MapFeature>[];
    final fs = l['features'];
    if (fs is List) {
      for (final f in fs) {
        final feature = f is Map<String, Object?> ? _decodeFeature(f, layer.id, ctx) : null;
        if (feature != null) features.add(feature);
      }
    }
    out.add(LayerBundle(layer, dedupe(features, ctx)));
  }
  return out;
}

MapFeature? _decodeFeature(Map<String, Object?> f, String layerId, ImportContext ctx) {
  final name = _str(f['name']);
  final kind = FeatureKind.values.where((k) => k.name == f['kind']).firstOrNull;
  if (kind == null) {
    ctx.warn(ImportWarning.hrzUnknownKind, '${f['kind']}');
    return null;
  }
  final vertices = <Geodetic>[];
  final raw = f['vertices'];
  if (raw is List) {
    for (final v in raw) {
      if (v is List && v.length >= 2 && v[0] is num && v[1] is num) {
        final lat = (v[0]! as num).toDouble(), lon = (v[1]! as num).toDouble();
        final h = v.length > 2 && v[2] is num ? (v[2]! as num).toDouble() : 0.0;
        if (!validLatLon(lat, lon) || !h.isFinite) {
          ctx.warn(ImportWarning.badCoordinate, name);
          return null;
        }
        vertices.add(Geodetic(lat, lon, h));
      } else {
        ctx.warn(ImportWarning.badCoordinate, name);
        return null;
      }
    }
  }
  final need = switch (kind) {
    FeatureKind.point => 1,
    FeatureKind.polyline => 2,
    FeatureKind.polygon => 3,
  };
  if (vertices.length < need || (kind == FeatureKind.point && vertices.length != 1)) {
    ctx.warn(ImportWarning.invalidFeature, name);
    return null;
  }
  final extra = f['extra'];
  final radius = f['radius'];
  return MapFeature(
    id: featureIdFrom(_str(f['id'])),
    layerId: layerId,
    kind: kind,
    vertices: vertices,
    name: name,
    description: _str(f['description']),
    author: _str(f['author']),
    sidc: f['sidc'] is String && (f['sidc']! as String).isNotEmpty ? f['sidc']! as String : null,
    color: parseColor(_colorStr(f['color'])),
    radius: radius is num && radius.isFinite && radius > 0 ? radius.toDouble() : null,
    extra: extra is Map<String, Object?> ? Map.unmodifiable(extra) : const {},
    createdAt: parseTime(_str(f['createdAt'])) ?? ctx.now,
    updatedAt: parseTime(_str(f['updatedAt'])) ?? ctx.now,
  );
}

String _str(Object? o) => o is String ? o : '';

String? _colorStr(Object? o) => switch (o) {
  final String s => s,
  final int i => '$i',
  _ => null,
};
