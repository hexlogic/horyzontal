import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/labels.dart';
import '../../l10n/app_localizations.dart';
import '../map/packs_page.dart' show formatBytes;
import 'map_source.dart';
import 'source_store.dart';
import 'sources_repository.dart';

/// `{z}/{x}/{y}` and the other template tokens, kept out of the ARB file
/// where braces are placeholders.
const templateTokens = (xyz: '{z}/{x}/{y}', sub: '{s}', tms: '{-y}', wms: '{bbox-epsg-3857}');

String importProblemText(AppLocalizations l, ImportProblem p, String name) => switch (p) {
  ImportProblem.vector => l.importVector(name),
  ImportProblem.elevation => l.importElevation(name),
  ImportProblem.unreadable => l.importUnreadable(name),
};

/// Copies a raster MBTiles or PMTiles in as a new map source. Throws
/// [SourceImportException].
Future<MapSource> importSourceFile(WidgetRef ref, String path, {String? fileName}) async {
  final store = ref.read(sourceStoreProvider), repo = ref.read(sourcesRepositoryProvider);
  final (file, info) = await store.import(path);
  final base = (fileName ?? path.split('/').last).replaceAll(RegExp(r'\.\w+$'), '');
  final s = repo.create(
    name: info.name?.trim().isNotEmpty == true ? info.name!.trim() : base,
    kind: MapSourceKind.file,
    file: file,
    minZoom: info.minZoom,
    maxZoom: info.maxZoom,
    attribution: info.attribution ?? '',
  );
  await repo.save(s);
  ref.invalidate(sourceFilesProvider);
  return s;
}

/// The user's map sources: URL templates and imported files.
class SourcesPage extends ConsumerWidget {
  const SourcesPage({super.key, required this.base});

  /// Route of this page, for the editor below it.
  final String base;

  Future<void> _importFiles(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final picked = await FilePicker.pickFiles();
    for (final f in picked) {
      if (f.path == null) continue;
      try {
        await importSourceFile(ref, f.path!, fileName: f.name);
      } on SourceImportException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(importProblemText(l, e.problem, f.name))));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final sources = ref.watch(sourcesProvider).value ?? const <MapSource>[];
    final files = ref.watch(sourceFilesProvider).value ?? const {};
    final repo = ref.read(sourcesRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.mapSources),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_open_outlined),
            tooltip: l.sourceAddFile,
            onPressed: () => _importFiles(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_link),
        label: Text(l.sourceAddUrl),
        onPressed: () => context.push('$base/edit'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l.sourcesNote, style: Theme.of(context).textTheme.bodySmall),
          ),
          if (sources.isEmpty)
            Padding(padding: const EdgeInsets.all(16), child: Text(l.sourcesEmpty, textAlign: TextAlign.center)),
          for (final s in sources)
            ListTile(
              leading: Icon(s.kind == MapSourceKind.url ? Icons.cloud_outlined : Icons.insert_drive_file_outlined),
              title: Text(s.name),
              subtitle: Text(_subtitle(l, s, files)),
              trailing: Switch(value: s.enabled, onChanged: (v) => repo.setEnabled(s.id, v)),
              onTap: () => context.push('$base/edit?id=${s.id}'),
            ),
        ],
      ),
    );
  }

  static String _subtitle(AppLocalizations l, MapSource s, Map<String, (int, DateTime)> files) {
    if (s.kind == MapSourceKind.file) {
      return l.sourceFileInfo(s.minZoom, s.maxZoom, formatBytes(l, files[s.file]?.$1 ?? 0));
    }
    final host = sourceHosts(s).firstOrNull ?? '';
    final dl = files[s.downloadFile];
    return dl == null ? host : '$host · ${l.sourceDownloaded(formatBytes(l, dl.$1))}';
  }
}
