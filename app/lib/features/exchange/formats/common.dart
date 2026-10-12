import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:xml/xml.dart';

import '../../../core/data/ids.dart';
import '../../../core/data/model.dart';
import 'bundle.dart';

/// The colour layers from other apps get (the app's first layer colour).
const defaultLayerColor = 0xFF1565C0;

/// Shared state of one import: the clock and the warnings.
class ImportContext {
  ImportContext({required this.fileName, DateTime? now}) : now = (now ?? DateTime.now()).toUtc();

  final String fileName;
  final DateTime now;
  final warnings = <ImportWarning>[];

  void warn(String code, [String? detail]) => warnings.add(ImportWarning(code, detail));

  /// The file name without folders and extensions, the fallback layer name.
  String get baseName => fileBaseName(fileName);

  MapLayer newLayer(String name, {int? color}) => MapLayer(
    id: newId(),
    name: name.trim().isEmpty ? baseName : name.trim(),
    color: color ?? defaultLayerColor,
    visible: true,
    archived: false,
    createdAt: now,
    updatedAt: now,
  );
}

/// `a/b/Шар 1.kml.hrze` → `Шар 1`.
String fileBaseName(String fileName) {
  var name = fileName.split(RegExp(r'[/\\]')).last;
  const known = {'hrze', 'hrz', 'kml', 'kmz', 'gpx', 'cot', 'xml', 'zip', 'json', 'dpk'};
  while (true) {
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || !known.contains(name.substring(dot + 1).toLowerCase())) break;
    name = name.substring(0, dot);
  }
  return name.trim().isEmpty ? 'Import' : name.trim();
}

/// The lower-case extension of [fileName] (after stripping `.hrze`), or ''.
String fileExtension(String fileName) {
  var name = fileName.split(RegExp(r'[/\\]')).last.toLowerCase();
  if (name.endsWith('.hrze')) name = name.substring(0, name.length - 5);
  final dot = name.lastIndexOf('.');
  return dot < 0 ? '' : name.substring(dot + 1);
}

/// A file name that every file system and share sheet accepts: no path
/// separators, reserved or control characters, at most 80 characters.
/// Cyrillic and other letters are kept.
String safeFileName(String name, {String fallback = 'horyzontal'}) {
  var s = name
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[\x00-\x1f\x7f/\\:*?"<>|]'), '_')
      .trim();
  s = s.replaceAll(RegExp(r'^[. ]+|[. ]+$'), '');
  final runes = s.runes.toList();
  if (runes.length > 80) s = String.fromCharCodes(runes.take(80)).trim();
  const reserved = {'CON', 'PRN', 'AUX', 'NUL', 'COM1', 'COM2', 'COM3', 'LPT1', 'LPT2', 'LPT3'};
  if (s.isEmpty || reserved.contains(s.toUpperCase())) return fallback;
  return s;
}

// ---------------------------------------------------------------------------
// Text and XML

/// Decodes text bytes: UTF-8 with or without BOM, or UTF-16 with a BOM.
/// Malformed UTF-8 is replaced rather than refused.
String decodeText(Uint8List bytes) {
  if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
    return _utf16(bytes, 2, littleEndian: true);
  }
  if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
    return _utf16(bytes, 2, littleEndian: false);
  }
  var start = 0;
  if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) start = 3;
  return utf8.decode(Uint8List.sublistView(bytes, start), allowMalformed: true);
}

String _utf16(Uint8List b, int start, {required bool littleEndian}) {
  final units = <int>[];
  for (var i = start; i + 1 < b.length; i += 2) {
    units.add(littleEndian ? b[i] | (b[i + 1] << 8) : (b[i] << 8) | b[i + 1]);
  }
  return String.fromCharCodes(units);
}

/// Parses XML without ever expanding custom entities: documents declaring
/// any are refused, so neither external nor recursive entities get a chance.
XmlDocument parseXml(String text) {
  if (text.contains('<!ENTITY')) {
    throw const ImportException(ImportException.xmlEntities);
  }
  try {
    // HTML5 named entities (&nbsp; from sloppy exporters); nothing external
    // is ever resolved.
    return XmlDocument.parse(text, entityMapping: const XmlDefaultEntityMapping.html5());
  } on XmlException catch (e) {
    throw ImportException(ImportException.malformed, e.message);
  }
}

/// The local name of the root element without parsing the whole document,
/// or null when [text] does not look like XML.
String? sniffXmlRoot(String text) {
  var i = 0;
  final n = text.length;
  while (i < n) {
    final c = text.codeUnitAt(i);
    if (c == 0xFEFF || c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D) {
      i++;
      continue;
    }
    if (c != 0x3C) return null; // '<'
    if (text.startsWith('<?', i)) {
      final end = text.indexOf('?>', i);
      if (end < 0) return null;
      i = end + 2;
    } else if (text.startsWith('<!--', i)) {
      final end = text.indexOf('-->', i);
      if (end < 0) return null;
      i = end + 3;
    } else if (text.startsWith('<!', i)) {
      final end = text.indexOf('>', i);
      if (end < 0) return null;
      i = end + 1;
    } else {
      final m = RegExp(r'<([A-Za-z_][\w.\-]*:)?([A-Za-z_][\w.\-]*)').matchAsPrefix(text, i);
      return m?.group(2);
    }
  }
  return null;
}

/// Escapes text for element content and attribute values, dropping the
/// characters XML 1.0 cannot carry.
String esc(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    switch (r) {
      case 0x26:
        b.write('&amp;');
      case 0x3C:
        b.write('&lt;');
      case 0x3E:
        b.write('&gt;');
      case 0x22:
        b.write('&quot;');
      case 0x27:
        b.write('&apos;');
      case 0x09 || 0x0A:
        b.writeCharCode(r);
      case 0x0D:
        b.write('&#13;');
      default:
        if (r < 0x20 || r == 0xFFFE || r == 0xFFFF) continue;
        b.writeCharCode(r);
    }
  }
  return b.toString();
}

/// Direct child elements of [e] with local name [name], any namespace.
Iterable<XmlElement> kids(XmlElement e, String name) =>
    e.childElements.where((c) => c.localName == name);

XmlElement? kid(XmlElement e, String name) {
  for (final c in e.childElements) {
    if (c.localName == name) return c;
  }
  return null;
}

/// Trimmed text of the first child [name], or null when absent or empty.
String? kidText(XmlElement e, String name) {
  final k = kid(e, name);
  if (k == null) return null;
  final t = k.innerText.trim();
  return t.isEmpty ? null : t;
}

/// Attribute by local name, any namespace.
String? attr(XmlElement e, String name) {
  for (final a in e.attributes) {
    if (a.localName == name) return a.value;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Numbers, coordinates, colours, times

bool validLatLon(double lat, double lon) =>
    lat.isFinite && lon.isFinite && lat.abs() <= 90 && lon.abs() <= 180;

/// [v] with at most [decimals] digits and no trailing zeros.
String fmt(double v, int decimals) {
  var s = v.toStringAsFixed(decimals);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  }
  if (s == '-0') s = '0';
  return s;
}

/// Degrees to 1e-8 (about 1 mm), metres to 1 mm.
String fmtDeg(double v) => fmt(v, 8);
String fmtAlt(double v) => fmt(v, 3);

/// `#AARRGGBB`.
String colorHex(int argb) =>
    '#${(argb & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0').toUpperCase()}';

/// `#RRGGBB`, `#AARRGGBB`, `AARRGGBB` or a decimal / signed 32-bit integer.
int? parseColor(String? s) {
  if (s == null) return null;
  var t = s.trim();
  if (t.isEmpty) return null;
  if (t.startsWith('#')) {
    t = t.substring(1);
    if (t.length == 6) t = 'FF$t';
    if (t.length != 8) return null;
    return int.tryParse(t, radix: 16);
  }
  if (RegExp(r'^-?\d+$').hasMatch(t)) {
    final v = int.tryParse(t);
    return v == null ? null : v & 0xFFFFFFFF;
  }
  if (t.length == 8) return int.tryParse(t, radix: 16);
  return null;
}

String iso(DateTime t) => t.toUtc().toIso8601String();

DateTime? parseTime(String? s) {
  if (s == null || s.trim().isEmpty) return null;
  return DateTime.tryParse(s.trim())?.toUtc();
}

// ---------------------------------------------------------------------------
// Identifiers

final _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

bool isUuid(String? s) => s != null && _uuid.hasMatch(s);

/// Namespace of [nameUuid], fixed forever so re-imports keep matching.
const _namespace = [
  0x3f, 0x1e, 0x8a, 0x52, 0x6c, 0x0d, 0x4b, 0x7e, //
  0x9a, 0x41, 0x0d, 0x2c, 0x7e, 0x5b, 0x8f, 0x13,
];

/// RFC 4122 version 5 UUID of [name] in the app's own namespace, so the same
/// foreign id (a CoT uid) always maps to the same object id.
String nameUuid(String name) {
  final digest = crypto.sha1.convert([..._namespace, ...utf8.encode(name)]).bytes;
  final b = digest.sublist(0, 16);
  b[6] = (b[6] & 0x0f) | 0x50;
  b[8] = (b[8] & 0x3f) | 0x80;
  String hex(int from, int to) =>
      b.sublist(from, to).map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}

/// [id] when it is a UUID (lower-cased), else a stable UUID derived from it,
/// else a fresh one.
String featureIdFrom(String? id, {String scope = ''}) {
  if (id == null || id.trim().isEmpty) return newId();
  final t = id.trim();
  if (isUuid(t)) return t.toLowerCase();
  return nameUuid('$scope$t');
}

/// The features of [bundle] with duplicate ids collapsed (last wins).
List<MapFeature> dedupe(List<MapFeature> features, ImportContext ctx) {
  final byId = <String, MapFeature>{};
  for (final f in features) {
    if (byId.containsKey(f.id)) ctx.warn(ImportWarning.duplicateId, f.name.isEmpty ? f.id : f.name);
    byId[f.id] = f;
  }
  return byId.values.toList();
}

/// Rebinds [features] to [layerId].
List<MapFeature> rebind(Iterable<MapFeature> features, String layerId) => [
  for (final f in features) f.layerId == layerId ? f : f.copyWith(layerId: layerId),
];

/// Drops the closing vertex of a ring.
List<T> openRing<T>(List<T> v, bool Function(T a, T b) same) =>
    v.length > 1 && same(v.first, v.last) ? v.sublist(0, v.length - 1) : v;
