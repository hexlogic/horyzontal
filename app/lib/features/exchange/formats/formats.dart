/// File exchange formats: the app's own .hrz, KML/KMZ, GPX, CoT and ATAK
/// data packages, plus optional password encryption (.hrze).
///
/// Pure Dart: bytes in, bytes out. Import is synchronous except for
/// decryption; [importFile] is async for that reason only.
library;

import 'dart:convert';
import 'dart:typed_data';

import '../../../core/data/model.dart';
import 'atak_package.dart';
import 'bundle.dart';
import 'common.dart';
import 'cot_format.dart';
import 'encryption.dart';
import 'gpx_format.dart';
import 'hrz_format.dart';
import 'kml_format.dart';
import 'zip_util.dart';

export 'bundle.dart';
export 'cot_types.dart' show cotTable, cotTypeToSidc, isNumberSidc, sidcToCotType;
export 'encryption.dart'
    show decryptExport, defaultKdfIterations, encryptExport, encryptedExtension, isEncryptedExport;

enum ExportFormat {
  hrz('hrz'),
  kml('kml'),
  kmz('kmz'),
  gpx('gpx'),
  cot('cot'),
  atakPackage('zip');

  const ExportFormat(this.extension);

  /// File extension without the dot.
  final String extension;
}

/// Serialises [layers] in [format]. [now] stamps the export (defaults to
/// the clock); [appVersion] goes into the file's creator field.
Uint8List exportLayers(
  List<LayerBundle> layers,
  ExportFormat format, {
  DateTime? now,
  String appVersion = '',
}) {
  final t = (now ?? DateTime.now()).toUtc();
  final name = _title(layers);
  return switch (format) {
    ExportFormat.hrz => utf8.encode(encodeHrz(layers, now: t, appVersion: appVersion)),
    ExportFormat.kml => utf8.encode(encodeKml(layers, documentName: name)),
    ExportFormat.kmz => encodeKmz(layers, documentName: name, now: t),
    ExportFormat.gpx => utf8.encode(encodeGpx(layers, now: t, appVersion: appVersion)),
    ExportFormat.cot => utf8.encode(encodeCot(layers, now: t)),
    ExportFormat.atakPackage => encodeAtakPackage(layers, name: name, now: t),
  };
}

/// What [format] cannot carry for [layers], as codes for the UI to show
/// before exporting:
/// * `cot.noPoints`: nothing to export, CoT holds points only;
/// * `cot.pointsOnly`: polylines and polygons are left out (except shapes
///   that came from ATAK);
/// * `cot.severalEvents`: more than one point; ATAK reads one event per
///   file, so prefer the data package;
/// * `gpx.layersMerged`: other apps see one layer;
/// * `atakPackage.emptyLayers`: layers without objects are left out.
Set<String> exportCaveats(List<LayerBundle> layers, ExportFormat format) {
  final all = [for (final l in layers) ...l.features];
  final points = all.where(cotEncodable).length;
  return {
    if (format == ExportFormat.cot && points == 0) 'cot.noPoints',
    if (format == ExportFormat.cot && points < all.length) 'cot.pointsOnly',
    if (format == ExportFormat.cot && points > 1) 'cot.severalEvents',
    if (format == ExportFormat.gpx && layers.length > 1) 'gpx.layersMerged',
    if (format == ExportFormat.atakPackage && layers.any((l) => l.features.isEmpty))
      'atakPackage.emptyLayers',
  };
}

String _title(List<LayerBundle> layers) => switch (layers) {
  [] => 'Horyzontal',
  [final one] => one.layer.name,
  [final first, ...final rest] => '${first.layer.name} +${rest.length}',
};

/// A file name for the export: the layer name (or the point name for a
/// single CoT point), safe for every file system, Cyrillic kept.
String suggestedFileName(List<LayerBundle> layers, ExportFormat format) {
  var base = _title(layers);
  if (format == ExportFormat.cot) {
    final points = [
      for (final l in layers) ...l.features.where((f) => f.kind == FeatureKind.point),
    ];
    if (points.length == 1 && points.single.name.trim().isNotEmpty) base = points.single.name;
  }
  return '${safeFileName(base)}.${format.extension}';
}

/// Imports a file of any supported format, detected by content first and
/// by [fileName]'s extension second. Encrypted exports need [password]:
/// without one this throws [PasswordRequired], with a wrong one
/// [WrongPassword]. Other failures are [ImportException]s; skipped parts
/// are in [ImportResult.warnings].
Future<ImportResult> importFile(
  String fileName,
  Uint8List bytes, {
  String? password,
  DateTime? now,
}) async {
  if (bytes.length > importSizeLimit) {
    throw const ImportException(ImportException.tooLarge);
  }
  if (isEncryptedExport(bytes)) {
    if (password == null) throw const PasswordRequired();
    final clear = await decryptExport(bytes, password);
    if (isEncryptedExport(clear)) {
      throw const ImportException(ImportException.encryptedCorrupt, 'nested');
    }
    final inner = fileName.toLowerCase().endsWith(encryptedExtension)
        ? fileName.substring(0, fileName.length - encryptedExtension.length)
        : fileName;
    return importPlainFile(inner, clear, now: now);
  }
  return importPlainFile(fileName, bytes, now: now);
}

/// [importFile] for files that are not encrypted, synchronously (for an
/// isolate, or tests). Throws [PasswordRequired] on an encrypted file.
ImportResult importPlainFile(String fileName, Uint8List bytes, {DateTime? now}) {
  if (bytes.length > importSizeLimit) {
    throw const ImportException(ImportException.tooLarge);
  }
  if (isEncryptedExport(bytes)) throw const PasswordRequired();
  final ctx = ImportContext(fileName: fileName, now: now);
  final List<LayerBundle> layers;
  try {
    layers = _import(fileName, bytes, ctx);
  } on ImportException {
    rethrow;
  } on Object catch (e) {
    // Anything a hostile file provokes beyond our checks is still "broken
    // file", never a crash.
    throw ImportException(ImportException.malformed, '$e');
  }
  return ImportResult(layers, ctx.warnings);
}

List<LayerBundle> _import(String fileName, Uint8List bytes, ImportContext ctx) {
  final ext = fileExtension(fileName);
  final budget = SizeBudget();
  if (isZip(bytes)) {
    final zip = SafeZip.open(bytes, budget);
    if (isAtakPackage(zip)) return decodeAtakPackage(zip, ctx, budget);
    if (zip.entries.keys.any((k) => k.toLowerCase().endsWith('.kml'))) {
      return [for (final (_, b) in decodeKmzZip(zip, ctx)) b];
    }
    throw const ImportException(ImportException.unknownFormat, 'zip without kml or cot');
  }
  final text = decodeText(bytes);
  if (looksLikeHrz(text)) return decodeHrz(text, ctx);
  switch (sniffXmlRoot(text)) {
    case 'kml':
      return decodeKml(text, ctx);
    case 'gpx':
      return decodeGpx(text, ctx);
    case 'event' || 'events':
      return groupCot(parseCot(text, ctx), ctx);
    case null:
      break;
    default:
      // XML of another kind: trust the extension if it names one of ours.
      break;
  }
  return switch (ext) {
    'hrz' || 'json' => decodeHrz(text, ctx),
    'kml' => decodeKml(text, ctx),
    'gpx' => decodeGpx(text, ctx),
    'cot' => groupCot(parseCot(text, ctx), ctx),
    _ => throw ImportException(ImportException.unknownFormat, ext.isEmpty ? null : ext),
  };
}
