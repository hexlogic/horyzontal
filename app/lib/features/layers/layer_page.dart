import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/model.dart';
import '../../core/data/repository.dart';
import '../../core/labels.dart';
import '../exchange/export_sheet.dart';
import 'layer_picker.dart';

/// One layer: rename, colour, visibility, export, archive, delete.
class LayerPage extends ConsumerWidget {
  const LayerPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final repo = ref.read(repositoryProvider);
    final all = [
      ...ref.watch(layersProvider(false)).value ?? const <MapLayer>[],
      ...ref.watch(layersProvider(true)).value ?? const <MapLayer>[],
    ];
    final layer = all.where((x) => x.id == id).firstOrNull;
    if (layer == null) return Scaffold(appBar: AppBar());
    final features = ref.watch(layerFeaturesProvider(id)).value ?? const <MapFeature>[];

    return Scaffold(
      appBar: AppBar(title: Text(layer.name)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(l.renameLayer),
            onTap: () async {
              final name = await askLayerName(context, initial: layer.name);
              if (name != null) await repo.saveLayer(layer.copyWith(name: name));
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 10,
              children: [
                for (final c in layerColors)
                  InkResponse(
                    onTap: () => repo.saveLayer(layer.copyWith(color: c)),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(c),
                      child: c == layer.color ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                    ),
                  ),
              ],
            ),
          ),
          if (!layer.archived)
            SwitchListTile(
              secondary: const Icon(Icons.visibility_outlined),
              title: Text(l.showOnMap),
              value: layer.visible,
              onChanged: (v) => repo.setLayerVisible(layer.id, v),
            ),
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: Text(l.exportLayer),
            subtitle: Text(l.exportFormats),
            onTap: () => showExportSheet(context, ref, [layer]),
          ),
          ListTile(
            leading: const Icon(Icons.wifi_tethering),
            title: Text(l.sendWifi),
            onTap: () => context.go('/journal/transfer?layers=${layer.id}'),
          ),
          ListTile(
            leading: Icon(layer.archived ? Icons.unarchive_outlined : Icons.archive_outlined),
            title: Text(layer.archived ? l.unarchive : l.toArchive),
            onTap: () async {
              await repo.setLayerArchived(layer.id, !layer.archived);
              if (context.mounted) context.pop();
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
            title: Text(l.deleteLayer),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l.deleteLayerQuestion(layer.name)),
                  content: Text(l.deleteLayerText(features.length)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.delete)),
                  ],
                ),
              );
              if (ok != true) return;
              await repo.deleteLayer(layer.id);
              if (context.mounted) context.pop();
            },
          ),
          const Divider(),
          ListTile(title: Text(l.objectsCount(features.length), style: Theme.of(context).textTheme.titleSmall)),
          for (final f in features)
            ListTile(
              leading: Icon(featureKindIcon(f.kind)),
              title: Text(f.name.isEmpty ? l.unnamed : f.name),
              onTap: () => context.go('/journal/object/${f.id}'),
            ),
        ],
      ),
    );
  }
}
