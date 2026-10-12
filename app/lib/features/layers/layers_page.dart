import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/model.dart';
import '../../core/data/repository.dart';
import '../../core/labels.dart';
import '../objects/feature_text.dart';
import 'layer_picker.dart';

/// Layers, most recently changed first. Swipe hides or shows a layer on the
/// map; the archive keeps old layers out of the way.
class LayersPage extends ConsumerStatefulWidget {
  const LayersPage({super.key});

  @override
  ConsumerState<LayersPage> createState() => _LayersPageState();
}

class _LayersPageState extends ConsumerState<LayersPage> {
  bool _archive = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final layers = ref.watch(layersProvider(_archive)).value ?? const <MapLayer>[];
    final counts = <String, int>{};
    for (final f in ref.watch(allFeaturesProvider).value ?? const <MapFeature>[]) {
      counts[f.layerId] = (counts[f.layerId] ?? 0) + 1;
    }
    final repo = ref.read(repositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_archive ? l.archive : l.layers),
        actions: [
          IconButton(
            tooltip: _archive ? l.layers : l.archive,
            icon: Icon(_archive ? Icons.layers_outlined : Icons.inventory_2_outlined),
            onPressed: () => setState(() => _archive = !_archive),
          ),
        ],
      ),
      floatingActionButton: _archive
          ? null
          : FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: Text(l.newLayer),
              onPressed: () async {
                final name = await askLayerName(context);
                if (name != null) await repo.createLayer(name);
              },
            ),
      body: layers.isEmpty
          ? Center(child: Text(_archive ? l.archiveEmpty : l.noLayers))
          : ListView(
              children: [
                if (!_archive)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(l.swipeToHide, style: Theme.of(context).textTheme.bodySmall),
                  ),
                for (final layer in layers)
                  Dismissible(
                    key: ValueKey('${layer.id}-${layer.visible}'),
                    direction: _archive ? DismissDirection.none : DismissDirection.horizontal,
                    confirmDismiss: (_) async {
                      await repo.setLayerVisible(layer.id, !layer.visible);
                      return false;
                    },
                    background: Container(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Icon(layer.visible ? Icons.visibility_off : Icons.visibility),
                    ),
                    secondaryBackground: Container(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Icon(layer.visible ? Icons.visibility_off : Icons.visibility),
                    ),
                    child: ListTile(
                      leading: Icon(
                        layer.visible ? Icons.circle : Icons.circle_outlined,
                        color: Color(layer.color),
                      ),
                      title: Text(layer.name),
                      subtitle: Text(
                        '${l.objectsCount(counts[layer.id] ?? 0)} · ${formatDateTime(layer.updatedAt)}'
                        '${layer.visible ? '' : ' · ${l.hidden}'}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/journal/layers/${layer.id}'),
                    ),
                  ),
              ],
            ),
    );
  }
}
