import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/model.dart';
import '../../core/data/repository.dart';
import '../../core/labels.dart';
import '../exchange/import_flow.dart';
import '../objects/feature_text.dart';
import '../objects/symbol_icons.dart';

/// All objects of non-archived layers, newest change first, filtered by kind
/// (several at once) and searched by name.
class JournalPage extends ConsumerStatefulWidget {
  const JournalPage({super.key});

  @override
  ConsumerState<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends ConsumerState<JournalPage> {
  final _kinds = <FeatureKind>{};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final all = ref.watch(allFeaturesProvider).value ?? const <MapFeature>[];
    final layers = {for (final x in ref.watch(layersProvider(false)).value ?? const <MapLayer>[]) x.id: x};
    final q = _query.trim().toLowerCase();
    final shown = [
      for (final f in all)
        if ((_kinds.isEmpty || _kinds.contains(f.kind)) && (q.isEmpty || f.name.toLowerCase().contains(q))) f,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l.tabJournal),
        actions: [
          IconButton(
            tooltip: l.layers,
            icon: const Icon(Icons.layers_outlined),
            onPressed: () => context.go('/journal/layers'),
          ),
          PopupMenuButton<String>(
            onSelected: (v) => switch (v) {
              'scan' => context.go('/journal/scan'),
              'import' => importFromPicker(context, ref),
              'receive' => context.go('/journal/transfer?receive=1'),
              _ => null,
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'scan', child: ListTile(leading: const Icon(Icons.qr_code_scanner), title: Text(l.scanQr))),
              PopupMenuItem(value: 'import', child: ListTile(leading: const Icon(Icons.file_open_outlined), title: Text(l.importFile))),
              PopupMenuItem(value: 'receive', child: ListTile(leading: const Icon(Icons.wifi_tethering), title: Text(l.receiveWifi))),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SearchBar(
                  hintText: l.searchByName,
                  leading: const Icon(Icons.search),
                  elevation: const WidgetStatePropertyAll(0),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    for (final k in FeatureKind.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          avatar: Icon(featureKindIcon(k), size: 18),
                          label: Text(featureKindNamePlural(l, k)),
                          selected: _kinds.contains(k),
                          onSelected: (v) => setState(() => v ? _kinds.add(k) : _kinds.remove(k)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: shown.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(all.isEmpty ? l.journalEmpty : l.nothingFound, textAlign: TextAlign.center),
              ),
            )
          : ListView.builder(
              itemCount: shown.length,
              itemBuilder: (context, i) {
                final f = shown[i];
                final layer = layers[f.layerId];
                return ListTile(
                  leading: SizedBox(
                    width: 44,
                    child: f.sidc != null
                        ? SymbolView(f.sidc!, height: 36)
                        : Icon(featureKindIcon(f.kind), color: Color(f.color ?? layer?.color ?? 0xFF1565C0)),
                  ),
                  title: Text(f.name.isEmpty ? l.unnamed : f.name),
                  subtitle: Text([
                    if (layer != null) layer.name,
                    formatDateTime(f.updatedAt),
                    if (f.author.isNotEmpty) f.author,
                  ].join(' · ')),
                  onTap: () => context.go('/journal/object/${f.id}'),
                );
              },
            ),
    );
  }
}
