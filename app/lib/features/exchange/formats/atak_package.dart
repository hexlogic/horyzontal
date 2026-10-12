import 'dart:convert';
import 'dart:typed_data';

import 'package:xml/xml.dart';

import '../../../core/data/model.dart';
import 'bundle.dart';
import 'common.dart';
import 'cot_format.dart';
import 'gpx_format.dart';
import 'kml_format.dart';
import 'zip_util.dart';

// ATAK data package (mission package), the zip ATAK sends and imports via
// Import Manager / Data Packages:
//
//   MANIFEST/manifest.xml
//   <uid>/<uid>.cot            one event per point (editable ATAK markers),
//                              and per shape that came from ATAK (u-d-f,
//                              u-d-r, u-d-c-c), so ATAK updates it in place
//   <layer id>/<layer>.kml     the layer's other polylines and polygons
//
//   <MissionPackageManifest version="2">
//     <Configuration>
//       <Parameter name="uid" value="…"/>
//       <Parameter name="name" value="…"/>
//     </Configuration>
//     <Contents>
//       <Content ignore="false" zipEntry="<uid>/<uid>.cot">
//         <Parameter name="uid" value="<uid>"/>
//       </Content>
//       <Content ignore="false" zipEntry="<layer id>/<layer>.kml">
//         <Parameter name="contentType" value="KML"/>
//         <Parameter name="visible" value="true"/>
//       </Content>
//     </Contents>
//   </MissionPackageManifest>
//
// Element and parameter names follow ATAK-CIV's MissionPackageManifest,
// MissionPackageConfiguration and MissionPackageContent classes. The
// package uid is derived from the layer ids, so re-sending the same layers
// replaces the package in ATAK instead of adding another.

const manifestPath = 'MANIFEST/manifest.xml';

/// Characters ATAK and every file system accept in an entry folder name.
String _entrySafe(String s) => s.replaceAll(RegExp(r'[^A-Za-z0-9._\-]'), '_');

Uint8List encodeAtakPackage(
  List<LayerBundle> layers, {
  required String name,
  required DateTime now,
}) {
  final files = <String, List<int>>{};
  final contents = StringBuffer();
  for (final l in layers) {
    for (final f in l.features.where(cotEncodable)) {
      final uid = cotUid(f);
      final dir = _entrySafe(uid);
      var path = '$dir/$dir.cot';
      for (var i = 2; files.containsKey(path); i++) {
        path = '$dir-$i/$dir.cot';
      }
      files[path] = utf8.encode(encodeCotEvent(f, layer: l.layer, now: now));
      contents
        ..writeln('    <Content ignore="false" zipEntry="${esc(path)}">')
        ..writeln('      <Parameter name="uid" value="${esc(uid)}"/>')
        ..writeln('    </Content>');
    }
    if (l.features.any((f) => !cotEncodable(f))) {
      final b = StringBuffer()
        ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
        ..writeln('<kml xmlns="http://www.opengis.net/kml/2.2">')
        ..writeln('<Document>')
        ..writeln('  <name>${esc(l.layer.name)}</name>');
      writeKmlFolder(b, l, only: (f) => !cotEncodable(f));
      b
        ..writeln('</Document>')
        ..writeln('</kml>');
      final path = '${_entrySafe(l.layer.id)}/${safeFileName(l.layer.name, fallback: 'layer')}.kml';
      files[path] = utf8.encode(b.toString());
      contents
        ..writeln('    <Content ignore="false" zipEntry="${esc(path)}">')
        ..writeln('      <Parameter name="contentType" value="KML"/>')
        ..writeln('      <Parameter name="visible" value="true"/>')
        ..writeln('    </Content>');
    }
  }
  final ids = [for (final l in layers) l.layer.id]..sort();
  final manifest = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
    ..writeln('<MissionPackageManifest version="2">')
    ..writeln('  <Configuration>')
    ..writeln('    <Parameter name="uid" value="${nameUuid('package:${ids.join(',')}')}"/>')
    ..writeln('    <Parameter name="name" value="${esc(name)}"/>')
    ..writeln('  </Configuration>')
    ..writeln('  <Contents>')
    ..write(contents)
    ..writeln('  </Contents>')
    ..writeln('</MissionPackageManifest>');
  return buildZip({manifestPath: utf8.encode(manifest.toString()), ...files}, time: now);
}

/// Whether the opened zip is a data package rather than a KMZ.
bool isAtakPackage(SafeZip zip) =>
    zip.find(manifestPath) != null || zip.entries.keys.any((k) => k.toLowerCase().endsWith('.cot'));

const _quietExtensions = {'png', 'jpg', 'jpeg', 'gif', 'svg', 'bmp', 'webp'};

List<LayerBundle> decodeAtakPackage(SafeZip zip, ImportContext ctx, SizeBudget budget) {
  String? packageName;
  var paths = zip.entries.keys.toList();
  final manifest = zip.find(manifestPath);
  if (manifest != null) {
    try {
      final root = parseXml(decodeText(zip.read(manifest))).rootElement;
      final config = kid(root, 'Configuration');
      if (config != null) {
        for (final p in kids(config, 'Parameter')) {
          if (p.getAttribute('name') == 'name') packageName = p.getAttribute('value');
        }
      }
      final listed = <String>[];
      final contents = kid(root, 'Contents');
      for (final c in contents == null ? const <XmlElement>[] : kids(contents, 'Content')) {
        if (c.getAttribute('ignore') == 'true') continue;
        final entry = c.getAttribute('zipEntry');
        if (entry == null) continue;
        final found = zip.find(entry);
        if (found == null) {
          ctx.warn(ImportWarning.entryMissing, entry);
        } else {
          listed.add(found);
        }
      }
      paths = listed;
    } on ImportException catch (e) {
      // A broken manifest: fall back to scanning the entries.
      ctx.warn(ImportWarning.entryFailed, '$manifestPath: ${e.code}');
    }
  }
  final defaultName = packageName == null || packageName.trim().isEmpty
      ? ctx.baseName
      : fileBaseName(packageName);

  final layers = <(String?, LayerBundle)>[];
  final items = <CotItem>[];
  for (final path in paths) {
    if (path.toLowerCase() == manifestPath.toLowerCase()) continue;
    final ext = fileExtension(path);
    try {
      switch (ext) {
        case 'cot':
          items.addAll(parseCot(decodeText(zip.read(path)), ctx));
        case 'kml':
          layers.addAll(decodeKmlLayers(decodeText(zip.read(path)), ctx));
        case 'kmz':
          layers.addAll(decodeKmzLayers(zip.read(path), ctx, budget));
        case 'gpx':
          layers.addAll([for (final b in decodeGpx(decodeText(zip.read(path)), ctx)) (null, b)]);
        case 'xml' when sniffXmlRoot(decodeText(zip.read(path))) == 'event':
          items.addAll(parseCot(decodeText(zip.read(path)), ctx));
        default:
          if (!_quietExtensions.contains(ext)) ctx.warn(ImportWarning.entrySkipped, path);
      }
    } on ImportException catch (e) {
      if (e.code == ImportException.tooLarge) rethrow;
      ctx.warn(ImportWarning.entryFailed, '$path: ${e.code}');
    }
  }

  // Points rejoin the KML layer they were exported with.
  final byOriginal = <String, int>{};
  for (final (i, (orig, _)) in layers.indexed) {
    if (orig != null) byOriginal[orig] = i;
  }
  final joined = <int, List<MapFeature>>{};
  final rest = <CotItem>[];
  for (final item in items) {
    final i = item.layerKey == null ? null : byOriginal[item.layerKey];
    if (i == null) {
      rest.add(item);
    } else {
      joined.putIfAbsent(i, () => []).add(item.feature);
    }
  }
  return [
    for (final (i, (_, b)) in layers.indexed)
      joined[i] == null
          ? b
          : LayerBundle(b.layer, dedupe([...rebind(joined[i]!, b.layer.id), ...b.features], ctx)),
    ...groupCot(rest, ctx, defaultName: defaultName),
  ];
}
