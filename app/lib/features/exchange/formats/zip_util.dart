import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'bundle.dart';

bool isZip(Uint8List b) =>
    b.length >= 4 && b[0] == 0x50 && b[1] == 0x4B && b[2] == 0x03 && b[3] == 0x04;

/// Byte budget shared by every archive opened during one import, nested
/// ones included: refuses more than [importSizeLimit] decompressed bytes.
class SizeBudget {
  SizeBudget([this.remaining = importSizeLimit]);

  int remaining;

  void take(int n) {
    if (n < 0 || n > remaining) {
      throw const ImportException(ImportException.tooLarge, 'archive content over the limit');
    }
    remaining -= n;
  }
}

/// A zip opened defensively: the entry count and the declared sizes are
/// checked before anything is decompressed, and archive 4 never decodes an
/// entry past its declared size, so a zip bomb fails before it inflates.
class SafeZip {
  SafeZip._(this.entries);

  /// Files by normalised path (`/` separators, no leading `/`), in archive
  /// order. Directories and macOS resource forks are left out.
  final Map<String, ArchiveFile> entries;

  factory SafeZip.open(Uint8List bytes, SizeBudget budget) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } on Object catch (e) {
      throw ImportException(ImportException.malformed, 'zip: $e');
    }
    if (archive.isEmpty) {
      throw const ImportException(ImportException.malformed, 'empty or corrupt zip');
    }
    if (archive.length > archiveEntryLimit) {
      throw ImportException(ImportException.tooLarge, '${archive.length} entries');
    }
    var total = 0;
    final entries = <String, ArchiveFile>{};
    for (final f in archive) {
      if (!f.isFile) continue;
      final path = normalisePath(f.name);
      if (path.isEmpty || path.startsWith('__MACOSX/') || path.split('/').last.startsWith('._')) {
        continue;
      }
      total += f.size;
      if (f.size < 0 || total > budget.remaining) {
        throw const ImportException(ImportException.tooLarge, 'archive content over the limit');
      }
      entries[path] = f;
    }
    budget.take(total);
    return SafeZip._(entries);
  }

  /// The entry's bytes; throws on a corrupt entry.
  Uint8List read(String path) {
    final f = entries[path];
    if (f == null) throw ImportException(ImportException.malformed, 'missing $path');
    final Uint8List? data;
    try {
      data = f.readBytes();
    } on Object catch (e) {
      throw ImportException(ImportException.malformed, '$path: $e');
    }
    if (data == null || data.length > f.size) {
      throw ImportException(ImportException.malformed, path);
    }
    return data;
  }

  /// Finds [path] ignoring case.
  String? find(String path) {
    final p = normalisePath(path).toLowerCase();
    for (final k in entries.keys) {
      if (k.toLowerCase() == p) return k;
    }
    return null;
  }
}

String normalisePath(String p) {
  final parts = p.replaceAll('\\', '/').split('/').where((s) => s.isNotEmpty && s != '.');
  return parts.join('/');
}

/// Builds a zip; entry names are UTF-8 (flagged as such).
Uint8List buildZip(Map<String, List<int>> files, {DateTime? time}) {
  final archive = Archive();
  final t = time ?? DateTime.now();
  for (final MapEntry(:key, :value) in files.entries) {
    final f = ArchiveFile.bytes(key, value);
    f.lastModTime = t.millisecondsSinceEpoch ~/ 1000;
    archive.add(f);
  }
  return ZipEncoder().encodeBytes(archive);
}
