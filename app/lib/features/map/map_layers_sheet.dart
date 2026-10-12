import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/repository.dart';
import '../../core/labels.dart';
import '../../core/settings.dart';
import '../sources/map_source.dart';
import '../sources/sources_repository.dart';
import 'packs.dart';

/// Base map choice and quick layer visibility.
Future<void> showMapLayersSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => const _MapLayersSheet(),
    );

class _MapLayersSheet extends ConsumerWidget {
  const _MapLayersSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(settingsProvider);
    final layers = ref.watch(layersProvider(false)).value ?? const [];
    final packs = ref.watch(packsProvider).value ?? const <PackFile>[];
    final repo = ref.read(repositoryProvider);
    final hasDem = packs.any((p) => p.kind == PackKind.dem);
    final sources = ref.watch(sourcesProvider).value ?? const <MapSource>[];
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (context, scroll) => ListView(
        controller: scroll,
        children: [
          ListTile(title: Text(l.baseMap, style: Theme.of(context).textTheme.titleMedium)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: true,
                  label: Text(l.mapOnline),
                  icon: const Icon(Icons.cloud_outlined),
                  enabled: !s.offlineOnly,
                ),
                ButtonSegment(value: false, label: Text(l.mapOffline), icon: const Icon(Icons.cloud_off)),
              ],
              selected: {s.onlineMap && !s.offlineOnly},
              onSelectionChanged: (v) =>
                  ref.read(settingsProvider.notifier).update((s) => s.copyWith(onlineMap: v.single)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.download_for_offline_outlined),
            title: Text(l.offlinePacks),
            subtitle: Text(l.packsInstalled(packs.where((p) => p.kind == PackKind.basemap).length)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.pop();
              context.go('/map/packs');
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.terrain_outlined),
            title: Text(l.reliefTint),
            subtitle: Text(hasDem ? l.demSurfaceNote : l.reliefTintNoPacks),
            value: s.reliefTint && hasDem,
            onChanged: hasDem
                ? (v) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(reliefTint: v))
                : null,
          ),
          const Divider(),
          ListTile(
            title: Text(l.mapSources, style: Theme.of(context).textTheme.titleMedium),
            trailing: TextButton(
              onPressed: () {
                context.pop();
                context.go('/map/sources');
              },
              child: Text(l.manageLayers),
            ),
          ),
          for (final src in sources) _SourceTile(source: src),
          const Divider(),
          ListTile(
            title: Text(l.layers, style: Theme.of(context).textTheme.titleMedium),
            trailing: TextButton(
              onPressed: () {
                context.pop();
                context.go('/journal/layers');
              },
              child: Text(l.manageLayers),
            ),
          ),
          for (final layer in layers)
            SwitchListTile(
              secondary: Icon(Icons.circle, color: Color(layer.color)),
              title: Text(layer.name),
              value: layer.visible,
              onChanged: (v) => repo.setLayerVisible(layer.id, v),
            ),
        ],
      ),
    );
  }
}

/// A user source: on/off and how opaque, applied when the slider is let go.
class _SourceTile extends ConsumerStatefulWidget {
  const _SourceTile({required this.source});
  final MapSource source;

  @override
  ConsumerState<_SourceTile> createState() => _SourceTileState();
}

class _SourceTileState extends ConsumerState<_SourceTile> {
  late double _opacity = widget.source.opacity;

  @override
  Widget build(BuildContext context) {
    final s = widget.source;
    final repo = ref.read(sourcesRepositoryProvider);
    return Column(
      children: [
        SwitchListTile(
          secondary: Icon(s.kind == MapSourceKind.url ? Icons.cloud_outlined : Icons.insert_drive_file_outlined),
          title: Text(s.name),
          value: s.enabled,
          onChanged: (v) => repo.setEnabled(s.id, v),
        ),
        if (s.enabled)
          Padding(
            padding: const EdgeInsets.only(left: 56, right: 8),
            child: Slider(
              value: _opacity,
              min: 0.1,
              label: '${(_opacity * 100).round()} %',
              divisions: 9,
              semanticFormatterCallback: (v) => '${context.l10n.sourceOpacity} ${(v * 100).round()} %',
              onChanged: (v) => setState(() => _opacity = v),
              onChangeEnd: (v) => repo.setOpacity(s.id, v),
            ),
          ),
      ],
    );
  }
}
