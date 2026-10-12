import 'dart:convert';

import 'package:horyzontal_geo/horyzontal_geo.dart';
import 'package:xml/xml.dart';

import '../../../core/data/model.dart';
import 'bundle.dart';
import 'common.dart';
import 'cot_types.dart';

// Cursor on Target 2.0 events as ATAK writes them. A point is
//
//   <event version="2.0" uid="…" type="a-h-G-U-C-I" how="h-g-i-g-o"
//          time="…" start="…" stale="…">
//     <point lat="…" lon="…" hae="9999999.0" ce="9999999.0" le="9999999.0"/>
//     <detail>
//       <status readiness="true"/><archive/>
//       <contact callsign="name"/>
//       <link uid="…" type="a-f-G-U-C" parent_callsign="author" relation="p-p" …/>
//       <remarks>description</remarks>
//       <color argb="-65536"/>
//       <precisionlocation altsrc="???" geopointsrc="USER"/>
//       <__horyzontal id="…" sidc="…" …/>
//     </detail>
//   </event>
//
// `__horyzontal` carries what a CoT type cannot (exact SIDC, radius,
// timestamps, layer); other apps ignore it. Unknown altitude is
// hae 9999999 (the CoT "no value"), as ATAK does.

/// CoT's "unknown" for hae, ce and le.
const cotUnknown = 9999999.0;
const _hrzDetail = '__horyzontal';

/// How long exported markers stay fresh in ATAK.
const cotStale = Duration(days: 365);

/// CoT times: UTC, millisecond precision, `Z`.
String cotTime(DateTime t) {
  final u = t.toUtc();
  return DateTime.utc(
    u.year,
    u.month,
    u.day,
    u.hour,
    u.minute,
    u.second,
    u.millisecond,
  ).toIso8601String();
}

/// The CoT uid for [f]: the uid it was imported with, else its id.
String cotUid(MapFeature f) {
  final u = f.extra['cotUid'];
  return u is String && u.isNotEmpty ? u : f.id;
}

/// Whether [f] came from an ATAK drawing shape (`u-d-…`) and goes back to
/// ATAK as one, so the shape is updated in place rather than duplicated by
/// a KML overlay.
bool isAtakShape(MapFeature f) {
  final t = f.extra['cotType'];
  if (t is! String) return false;
  return switch (f.kind) {
    FeatureKind.point => t.startsWith('u-d-c-c') && f.radius != null,
    FeatureKind.polyline => t.startsWith('u-d-f'),
    FeatureKind.polygon =>
      t.startsWith('u-d-f') || (t.startsWith('u-d-r') && f.vertices.length == 4),
  };
}

/// Whether [f] can be written as a CoT event: points and ATAK shapes.
bool cotEncodable(MapFeature f) => f.kind == FeatureKind.point || isAtakShape(f);

/// The CoT type for [f]: from its SIDC, refined by the type it was
/// imported with when that is a more specific branch of the same type.
/// Points without a symbol keep a non-atom type they came with (spot
/// markers, waypoints) or become ATAK spot-map markers.
String cotTypeOf(MapFeature f) {
  final imported = f.extra['cotType'];
  if (isAtakShape(f)) return imported! as String;
  if (f.sidc == null) {
    return imported is String &&
            imported.isNotEmpty &&
            !imported.startsWith('a-') &&
            !imported.startsWith('u-d-')
        ? imported
        : 'b-m-p-s-m';
  }
  final t = sidcToCotType(f.sidc);
  if (imported is String && imported.startsWith('$t-')) return imported;
  return t;
}

int _signed(int argb) => (argb & 0xFFFFFFFF).toSigned(32);

/// One `<event>` for a point; [layer] goes into `__horyzontal` so the app
/// can regroup a package.
String encodeCotEvent(
  MapFeature f, {
  MapLayer? layer,
  required DateTime now,
  bool declaration = true,
}) {
  final type = cotTypeOf(f);
  final shape = isAtakShape(f);
  final p = shape && f.kind != FeatureKind.point ? _centre(f.vertices) : f.position;
  final color = f.color ?? layer?.color;
  final b = StringBuffer();
  if (declaration) b.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
  b
    ..writeln(
      '<event version="2.0" uid="${esc(cotUid(f))}" type="${esc(type)}" how="h-g-i-g-o" '
      'time="${cotTime(now)}" start="${cotTime(now)}" stale="${cotTime(now.add(cotStale))}">',
    )
    ..writeln(
      '  <point lat="${fmtDeg(p.lat)}" lon="${fmtDeg(p.lon)}" '
      'hae="${p.h != 0 ? fmtAlt(mslToHae(p)) : '$cotUnknown'}" ce="$cotUnknown" le="$cotUnknown"/>',
    )
    ..writeln('  <detail>')
    ..writeln('    <status readiness="true"/>')
    ..writeln('    <archive/>')
    ..writeln('    <contact callsign="${esc(f.name)}"/>');
  if (f.author.isNotEmpty) {
    b.writeln(
      '    <link uid="${nameUuid('callsign:${f.author}')}" production_time="${cotTime(f.updatedAt)}" '
      'type="a-f-G-U-C" parent_callsign="${esc(f.author)}" relation="p-p"/>',
    );
  }
  if (f.description.isNotEmpty) b.writeln('    <remarks>${esc(f.description)}</remarks>');
  if (shape) {
    _shapeDetail(b, f, type);
    if (color != null) b.writeln('    <strokeColor value="${_signed(color)}"/>');
    b.writeln('    <strokeWeight value="3.0"/>');
    if (f.kind == FeatureKind.polygon && color != null) {
      b.writeln('    <fillColor value="${_signed((color & 0xFFFFFF) | 0x40000000)}"/>');
    }
  } else if (color != null) {
    b.writeln('    <color argb="${_signed(color)}"/>');
  }
  if (type == 'b-m-p-s-m') {
    b.writeln(
      '    <usericon iconsetpath="COT_MAPPING_SPOTMAP/b-m-p-s-m/${_signed(color ?? 0xFFFFFFFF)}"/>',
    );
  }
  b.writeln('    <precisionlocation altsrc="${p.h != 0 ? 'USER' : '???'}" geopointsrc="USER"/>');
  final hrz = <String, String>{
    'id': f.id,
    if (f.sidc != null) 'sidc': f.sidc!,
    if (f.author.isNotEmpty) 'author': f.author,
    if (f.radius != null) 'radius': '${f.radius}',
    if (f.color != null) 'color': colorHex(f.color!),
    'created': iso(f.createdAt),
    'updated': iso(f.updatedAt),
    if (layer != null) ...{
      'layer': layer.id,
      'layerName': layer.name,
      'layerColor': colorHex(layer.color),
    },
    if (f.extra.isNotEmpty) 'extra': jsonEncode(f.extra, toEncodable: (o) => o.toString()),
  };
  b.writeln('    <$_hrzDetail ${hrz.entries.map((e) => '${e.key}="${esc(e.value)}"').join(' ')}/>');
  b
    ..writeln('  </detail>')
    ..writeln('</event>');
  return b.toString();
}

Geodetic _centre(List<Geodetic> v) {
  var lat = 0.0, lon = 0.0;
  for (final p in v) {
    lat += p.lat;
    lon += p.lon;
  }
  return Geodetic(lat / v.length, lon / v.length);
}

/// The geometry details of an ATAK shape: `link point`s for polylines
/// (repeating the first point when closed, as ATAK does) and rectangles,
/// an ellipse for circles.
void _shapeDetail(StringBuffer b, MapFeature f, String type) {
  if (f.kind == FeatureKind.point) {
    final r = fmtAlt(f.radius!);
    b.writeln('    <shape><ellipse major="$r" minor="$r" angle="360"/></shape>');
    return;
  }
  final closed = f.kind == FeatureKind.polygon && !type.startsWith('u-d-r');
  for (final v in [...f.vertices, if (closed) f.vertices.first]) {
    b.writeln(
      '    <link point="${fmtDeg(v.lat)},${fmtDeg(v.lon)}${v.h != 0 ? ',${fmtAlt(v.h)}' : ''}"/>',
    );
  }
}

/// Every point (and ATAK shape) of [layers] as events, one after another (the format the
/// importer, TAK Server dumps and several tools accept; ATAK itself reads
/// one event per file, see the data package for that).
String encodeCot(List<LayerBundle> layers, {required DateTime now}) {
  final b = StringBuffer();
  var first = true;
  for (final l in layers) {
    for (final f in l.features.where(cotEncodable)) {
      b.write(encodeCotEvent(f, layer: l.layer, now: now, declaration: first));
      first = false;
    }
  }
  return b.toString();
}

// ---------------------------------------------------------------------------
// Import

/// A parsed event: the feature (bound to no layer yet) and the layer it
/// says it belongs to.
class CotItem {
  CotItem(this.feature, {this.layerKey, this.layerName, this.layerColor});

  final MapFeature feature;
  final String? layerKey, layerName;
  final int? layerColor;
}

/// Parses one or several concatenated `<event>`s (with or without their own
/// XML declarations and BOMs).
List<CotItem> parseCot(String text, ImportContext ctx) {
  if (text.contains('<!ENTITY')) throw const ImportException(ImportException.xmlEntities);
  final body = text
      .replaceAll('﻿', '')
      .replaceAll(RegExp(r'<\?xml[^>]*\?>'), '')
      .replaceAll(RegExp(r'<!DOCTYPE[^>]*>'), '');
  final root = parseXml('<cot-events>$body</cot-events>').rootElement;
  final events = <XmlElement>[
    for (final e in root.childElements)
      if (e.localName == 'event') e else ...e.findElements('event'),
  ];
  if (events.isEmpty) throw const ImportException(ImportException.malformed, 'no <event>');
  final out = <CotItem>[];
  for (final e in events) {
    final item = _event(e, ctx);
    if (item != null) out.add(item);
  }
  return out;
}

/// Groups parsed events into layers: by the layer each names, the rest
/// into one layer called [defaultName].
List<LayerBundle> groupCot(List<CotItem> items, ImportContext ctx, {String? defaultName}) {
  final layers = <String, MapLayer>{};
  final features = <String, List<MapFeature>>{};
  for (final i in items) {
    final key = i.layerKey ?? '';
    final layer = layers.putIfAbsent(
      key,
      () => ctx.newLayer(
        i.layerKey == null ? defaultName ?? ctx.baseName : i.layerName ?? defaultName ?? '',
        color: i.layerKey == null ? null : i.layerColor,
      ),
    );
    features.putIfAbsent(key, () => []).add(i.feature.copyWith(layerId: layer.id));
  }
  return [
    for (final MapEntry(:key, :value) in layers.entries)
      LayerBundle(value, dedupe(features[key]!, ctx)),
  ];
}

const _skipPrefixes = ['t-', 'b-t-', 'y-', 'c-', 'b-f-t-', 'u-r', 'b-a-'];

CotItem? _event(XmlElement e, ImportContext ctx) {
  final uid = e.getAttribute('uid')?.trim();
  final type = e.getAttribute('type')?.trim() ?? '';
  final detail = kid(e, 'detail');
  final contact = detail == null ? null : kid(detail, 'contact');
  final name = contact?.getAttribute('callsign') ?? '';
  final label = name.isEmpty ? uid ?? type : name;
  if (uid == null || uid.isEmpty || type.isEmpty) {
    ctx.warn(ImportWarning.cotInvalid, label);
    return null;
  }
  if (_skipPrefixes.any(type.startsWith)) {
    ctx.warn(ImportWarning.cotUnsupported, '$type $label');
    return null;
  }
  final hrz = detail == null ? null : kid(detail, _hrzDetail);
  String? h(String a) {
    final v = hrz?.getAttribute(a);
    return v == null || v.isEmpty ? null : v;
  }

  // Geometry.
  FeatureKind kind;
  List<Geodetic> vertices;
  double? radius = double.tryParse(h('radius') ?? '');
  int? shapeColor;
  if (type.startsWith('u-d-')) {
    final shape = _shape(e, detail, type, ctx, label);
    if (shape == null) return null;
    (kind, vertices) = (shape.$1, shape.$2);
    radius = shape.$3 ?? radius;
    shapeColor = shape.$4;
  } else {
    final point = kid(e, 'point');
    final v = point == null ? null : _pointAttrs(point);
    if (v == null) {
      ctx.warn(ImportWarning.badCoordinate, label);
      return null;
    }
    kind = FeatureKind.point;
    vertices = [v];
  }

  // Symbol: our exact SIDC while it still agrees with the type.
  final hrzSidc = h('sidc');
  final fromType = cotTypeToSidc(type);
  final ours = hrzSidc == null ? null : sidcToCotType(hrzSidc);
  final sidc =
      ours != null &&
          fromType != null &&
          (type == ours || type.startsWith('$ours-') || ours == sidcToCotType(fromType))
      ? hrzSidc
      : fromType;

  String author = h('author') ?? '';
  if (author.isEmpty && detail != null) {
    for (final l in kids(detail, 'link')) {
      final c = l.getAttribute('parent_callsign');
      if (c != null && c.isNotEmpty && (l.getAttribute('relation') ?? 'p-p') == 'p-p') {
        author = c;
        break;
      }
    }
  }
  int? color;
  if (hrz != null) {
    color = parseColor(h('color'));
  } else {
    final c = detail == null ? null : kid(detail, 'color');
    color = shapeColor ?? parseColor(c?.getAttribute('argb') ?? c?.getAttribute('value'));
  }

  Map<String, Object?> extra;
  final extraJson = h('extra');
  if (hrz != null) {
    extra = const {};
    if (extraJson != null) {
      try {
        final x = jsonDecode(extraJson);
        if (x is Map<String, Object?>) extra = Map.unmodifiable(x);
      } on FormatException {
        // A damaged extra field loses only import leftovers.
      }
    }
  } else {
    extra = {'cotUid': uid, 'cotType': type};
  }

  // The uid decides identity. Our own id is trusted only while it still
  // belongs to this uid (a marker copied in ATAK keeps the detail but gets
  // a new uid, and must not replace the original).
  final hrzId = h('id');
  final id = hrzId != null && (hrzId == uid || extra['cotUid'] == uid)
      ? featureIdFrom(hrzId)
      : featureIdFrom(uid, scope: 'cot:');

  final time = parseTime(e.getAttribute('time'));
  final created = parseTime(h('created')) ?? time ?? ctx.now;
  final remarks = detail == null ? null : kid(detail, 'remarks');
  return CotItem(
    MapFeature(
      id: id,
      layerId: '',
      kind: kind,
      vertices: vertices,
      name: name,
      description: remarks?.innerText.trim() ?? '',
      author: author,
      sidc: sidc,
      color: color,
      radius: radius != null && radius.isFinite && radius > 0 ? radius : null,
      extra: extra,
      createdAt: created,
      updatedAt: parseTime(h('updated')) ?? time ?? created,
    ),
    layerKey: h('layer'),
    layerName: h('layerName'),
    layerColor: parseColor(h('layerColor')),
  );
}

Geodetic? _pointAttrs(XmlElement p) {
  final lat = double.tryParse(p.getAttribute('lat') ?? '');
  final lon = double.tryParse(p.getAttribute('lon') ?? '');
  if (lat == null || lon == null || !validLatLon(lat, lon)) return null;
  return Geodetic(lat, lon, haeToMsl(lat, lon, _hae(p.getAttribute('hae'))));
}

double _hae(String? s) {
  final h = double.tryParse(s ?? '');
  return h == null || !h.isFinite || h.abs() >= cotUnknown ? 0 : h;
}

/// The app keeps altitudes above sea level (what maps and the user give);
/// CoT `hae` is above the WGS 84 ellipsoid. EGM2008 covers Ukraine and
/// around; elsewhere the value passes through unchanged. 0 stays "unknown".
double mslToHae(Geodetic p) => p.h + (Geoid.egm2008Ukraine.undulation(p.lat, p.lon) ?? 0);

double haeToMsl(double lat, double lon, double hae) =>
    hae == 0 ? 0 : hae - (Geoid.egm2008Ukraine.undulation(lat, lon) ?? 0);

/// ATAK drawing shapes: `u-d-f` (polyline, closed = polygon), `u-d-r`
/// (rectangle), `u-d-c-c` (circle → point with radius). Returns kind,
/// vertices, radius and stroke colour.
(FeatureKind, List<Geodetic>, double?, int?)? _shape(
  XmlElement e,
  XmlElement? detail,
  String type,
  ImportContext ctx,
  String label,
) {
  final stroke = detail == null ? null : kid(detail, 'strokeColor')?.getAttribute('value');
  final color = parseColor(stroke);
  if (type.startsWith('u-d-c-c')) {
    final point = kid(e, 'point');
    final centre = point == null ? null : _pointAttrs(point);
    final shape = detail == null ? null : kid(detail, 'shape');
    final ellipse = shape == null ? null : kid(shape, 'ellipse');
    final r = double.tryParse(ellipse?.getAttribute('major') ?? '');
    if (centre == null) {
      ctx.warn(ImportWarning.badCoordinate, label);
      return null;
    }
    return (FeatureKind.point, [centre], r, color);
  }
  if (!type.startsWith('u-d-f') && !type.startsWith('u-d-r')) {
    ctx.warn(ImportWarning.cotUnsupported, '$type $label');
    return null;
  }
  final points = <Geodetic>[];
  for (final l in detail == null ? const <XmlElement>[] : kids(detail, 'link')) {
    final p = l.getAttribute('point');
    if (p == null) continue;
    final parts = p.split(',');
    final lat = parts.isNotEmpty ? double.tryParse(parts[0].trim()) : null;
    final lon = parts.length > 1 ? double.tryParse(parts[1].trim()) : null;
    if (lat == null || lon == null || !validLatLon(lat, lon)) {
      ctx.warn(ImportWarning.badCoordinate, label);
      return null;
    }
    points.add(Geodetic(lat, lon, parts.length > 2 ? haeToMsl(lat, lon, _hae(parts[2].trim())) : 0));
  }
  final open = openRing<Geodetic>(points, (a, b) => a.lat == b.lat && a.lon == b.lon);
  final closed = type.startsWith('u-d-r') || open.length < points.length;
  if (closed && open.length >= 3) return (FeatureKind.polygon, open, null, color);
  if (!closed && points.length >= 2) return (FeatureKind.polyline, points, null, color);
  ctx.warn(ImportWarning.invalidFeature, label);
  return null;
}
