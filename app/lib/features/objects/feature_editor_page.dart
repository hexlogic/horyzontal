import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

import '../../core/data/ids.dart';
import '../../core/data/model.dart';
import '../../core/data/repository.dart';
import '../../core/labels.dart';
import '../../core/settings.dart';
import '../../core/widgets/point_input.dart';
import '../layers/layer_picker.dart';
import 'symbol_icons.dart';

/// Creates a point at [initial] or edits the object [id].
class FeatureEditorPage extends ConsumerStatefulWidget {
  const FeatureEditorPage({super.key, this.id, this.initial});

  final String? id;
  final Geodetic? initial;

  @override
  ConsumerState<FeatureEditorPage> createState() => _FeatureEditorPageState();
}

class _FeatureEditorPageState extends ConsumerState<FeatureEditorPage> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _author = TextEditingController();
  final _altitude = TextEditingController();
  final _radius = TextEditingController();
  MapFeature? _original;
  MapLayer? _layer;
  Geodetic? _position;
  String? _sidc;
  bool _loading = true;

  bool get _isPoint => _original == null || _original!.kind == FeatureKind.point;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(repositoryProvider);
    final l = context.l10n;
    if (widget.id != null) {
      final f = await repo.feature(widget.id!);
      if (f == null) return;
      _original = f;
      _name.text = f.name;
      _description.text = f.description;
      _author.text = f.author;
      _position = f.position;
      if (f.position.h != 0) _altitude.text = f.position.h.toStringAsFixed(0);
      if (f.radius != null) _radius.text = f.radius!.toStringAsFixed(0);
      _sidc = f.sidc;
      _layer = await repo.layer(f.layerId);
    } else {
      _position = widget.initial;
      _author.text = ref.read(settingsProvider).callsign;
      _layer = await repo.defaultLayer(l.defaultLayerName);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final c in [_name, _description, _author, _altitude, _radius]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickSymbol() async {
    final sidc = await context.push<String>(
      Uri(path: '/symbol', queryParameters: {if (_sidc != null) 'sidc': _sidc}).toString(),
    );
    if (sidc != null) setState(() => _sidc = sidc.isEmpty ? null : sidc);
  }

  Future<void> _pickPosition() async {
    PointValue? picked;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.coordinates),
        content: SingleChildScrollView(child: PointInput(onChanged: (v) => picked = v)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.l10n.save)),
        ],
      ),
    );
    if (ok == true && picked != null) setState(() => _position = picked!.wgs);
  }

  Future<void> _save() async {
    final repo = ref.read(repositoryProvider);
    final layer = _layer;
    final pos = _position;
    if (layer == null || (_isPoint && pos == null)) return;
    final alt = double.tryParse(_altitude.text.replaceAll(',', '.')) ?? 0;
    final radius = double.tryParse(_radius.text.replaceAll(',', '.'));
    final now = repo.now();
    final o = _original;
    final vertices = _isPoint ? [Geodetic(pos!.lat, pos.lon, alt)] : o!.vertices;
    final f = o == null
        ? MapFeature(
            id: newId(),
            layerId: layer.id,
            kind: FeatureKind.point,
            vertices: vertices,
            name: _name.text.trim(),
            description: _description.text.trim(),
            author: _author.text.trim(),
            sidc: _sidc,
            radius: radius != null && radius > 0 ? radius : null,
            createdAt: now,
            updatedAt: now,
          )
        : o.copyWith(
            layerId: layer.id,
            vertices: vertices,
            name: _name.text.trim(),
            description: _description.text.trim(),
            author: _author.text.trim(),
            sidc: () => _isPoint ? _sidc : o.sidc,
            radius: () => radius != null && radius > 0 ? radius : null,
          );
    await repo.saveFeature(f);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = ref.watch(settingsProvider);
    if (_loading) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    final numbers = [FilteringTextInputFormatter.allow(RegExp(r'[\d.,-]'))];
    return Scaffold(
      appBar: AppBar(
        title: Text(_original == null ? l.newPoint : l.edit),
        actions: [TextButton(onPressed: _save, child: Text(l.save))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isPoint)
            Card(
              child: ListTile(
                leading: SizedBox(
                  width: 56,
                  child: _sidc == null ? const Icon(Icons.shield_outlined, size: 36) : SymbolView(_sidc!, height: 48),
                ),
                title: Text(l.symbol),
                subtitle: Text(_sidc ?? l.symbolNone),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickSymbol,
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l.name, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            minLines: 2,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l.description, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.circle, color: Color(_layer?.color ?? 0xFF1565C0)),
            title: Text(l.layer),
            subtitle: Text(_layer?.name ?? ''),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final picked = await pickLayer(context, ref);
              if (picked != null) setState(() => _layer = picked);
            },
          ),
          if (_isPoint) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.place_outlined),
              title: Text(l.coordinates),
              subtitle: Text(_position == null ? '—' : formatPoint(_position!, s.system, s.geoFormat)),
              trailing: const Icon(Icons.edit_outlined),
              onTap: _pickPosition,
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _altitude,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    inputFormatters: numbers,
                    decoration: InputDecoration(labelText: l.altitudeM, border: const OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _radius,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: numbers,
                    decoration: InputDecoration(labelText: l.radiusM, border: const OutlineInputBorder()),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _author,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(labelText: l.callsign, border: const OutlineInputBorder()),
          ),
        ],
      ),
    );
  }
}
