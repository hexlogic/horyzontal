import '../../../core/data/model.dart';

/// A layer with its objects, the unit of export and import.
class LayerBundle {
  LayerBundle(this.layer, this.features);

  final MapLayer layer;
  final List<MapFeature> features;
}

/// Something an import skipped or changed. [code] is one of [ImportWarning]'s
/// constants; [detail] is free text for logs (a placemark name, an entry
/// path), not meant for translation.
class ImportWarning {
  const ImportWarning(this.code, [this.detail]);

  final String code;
  final String? detail;

  /// A placemark, waypoint or event had no usable geometry.
  static const invalidFeature = 'feature.invalid';

  /// A coordinate was outside |lat| ≤ 90, |lon| ≤ 180 or not a number.
  static const badCoordinate = 'feature.badCoordinate';

  /// A KML geometry the app cannot hold (Model, gx:Track, gx:MultiTrack).
  static const unsupportedGeometry = 'kml.unsupportedGeometry';
  static const trackIgnored = 'kml.trackIgnored';

  /// Polygon holes (innerBoundaryIs) were dropped.
  static const innerBoundaryDropped = 'kml.innerBoundaryDropped';

  /// NetworkLink, GroundOverlay, ScreenOverlay, PhotoOverlay.
  static const overlayIgnored = 'kml.overlayIgnored';

  /// An archive entry that is not a format we read.
  static const entrySkipped = 'archive.entrySkipped';

  /// An archive entry that could not be read.
  static const entryFailed = 'archive.entryFailed';

  /// The manifest names an entry the archive lacks.
  static const entryMissing = 'archive.entryMissing';

  /// A CoT event that is not a point and not a known ATAK shape.
  static const cotUnsupported = 'cot.unsupported';

  /// A CoT event could not be parsed.
  static const cotInvalid = 'cot.invalid';

  /// A feature kind or field in an .hrz file this version does not know.
  static const hrzUnknownKind = 'hrz.unknownKind';

  /// Two objects with the same id; the later one replaced the earlier one.
  static const duplicateId = 'feature.duplicateId';

  @override
  String toString() => detail == null ? code : '$code: $detail';

  @override
  bool operator ==(Object other) =>
      other is ImportWarning && other.code == code && other.detail == detail;

  @override
  int get hashCode => Object.hash(code, detail);
}

class ImportResult {
  ImportResult(this.layers, this.warnings);

  final List<LayerBundle> layers;
  final List<ImportWarning> warnings;

  int get featureCount => layers.fold(0, (n, l) => n + l.features.length);
}

/// The file could not be imported at all. [code] is one of the constants
/// below; [detail] is for logs.
class ImportException implements Exception {
  const ImportException(this.code, [this.detail]);

  final String code;
  final String? detail;

  /// Neither the content nor the extension is a format we read.
  static const unknownFormat = 'format.unknown';

  /// The file claims a format but is broken (bad XML, bad JSON, bad zip).
  static const malformed = 'format.malformed';

  /// An .hrz file from a newer app version.
  static const unsupportedVersion = 'format.unsupportedVersion';

  /// More than [importSizeLimit] bytes, compressed or not.
  static const tooLarge = 'format.tooLarge';

  /// XML with entity declarations (we never expand them).
  static const xmlEntities = 'xml.entities';

  static const passwordRequired = 'encrypted.passwordRequired';
  static const wrongPassword = 'encrypted.wrongPassword';

  /// An encrypted container this version cannot read or that is truncated.
  static const encryptedCorrupt = 'encrypted.corrupt';

  @override
  String toString() => 'ImportException($code${detail == null ? '' : ': $detail'})';
}

/// The file is an encrypted export: ask for the password and call
/// `importFile(..., password: ...)` again.
class PasswordRequired extends ImportException {
  const PasswordRequired() : super(ImportException.passwordRequired);
}

/// The password does not open the file (or the file was tampered with; GCM
/// cannot tell the two apart).
class WrongPassword extends ImportException {
  const WrongPassword() : super(ImportException.wrongPassword);
}

/// Refuse inputs, and archives whose entries add up to, more than this.
const importSizeLimit = 50 * 1024 * 1024;

/// Refuse archives with more entries than this.
const archiveEntryLimit = 10000;
