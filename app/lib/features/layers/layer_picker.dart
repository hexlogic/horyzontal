import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/model.dart';
import '../../core/data/repository.dart';
import '../../core/labels.dart';

/// Asks for a layer (or a new one). Null when cancelled.
Future<MapLayer?> pickLayer(BuildContext context, WidgetRef ref, {String? title}) async {
  final l = context.l10n;
  final repo = ref.read(repositoryProvider);
  final layers = await repo.layers(includeArchived: false);
  if (!context.mounted) return null;
  final picked = await showDialog<Object>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(title ?? l.layer),
      children: [
        for (final layer in layers)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, layer),
            child: Row(children: [
              Icon(Icons.circle, size: 14, color: Color(layer.color)),
              const SizedBox(width: 12),
              Expanded(child: Text(layer.name)),
            ]),
          ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, 'new'),
          child: Row(children: [const Icon(Icons.add, size: 18), const SizedBox(width: 10), Text(l.newLayer)]),
        ),
      ],
    ),
  );
  if (picked is MapLayer) return picked;
  if (picked == 'new' && context.mounted) {
    final name = await askLayerName(context);
    if (name != null) return repo.createLayer(name);
  }
  return null;
}

Future<String?> askLayerName(BuildContext context, {String initial = ''}) async {
  final l = context.l10n;
  final c = TextEditingController(text: initial);
  final v = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(initial.isEmpty ? l.newLayer : l.renameLayer),
      content: TextField(
        controller: c,
        autofocus: true,
        decoration: InputDecoration(labelText: l.layerName),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, c.text), child: Text(l.save)),
      ],
    ),
  );
  final name = v?.trim();
  return name == null || name.isEmpty ? null : name;
}

const layerColors = [
  0xFF1565C0, 0xFFC62828, 0xFF2E7D32, 0xFFEF6C00, 0xFF6A1B9A, 0xFF00838F, 0xFF4E342E, 0xFF37474F,
];
