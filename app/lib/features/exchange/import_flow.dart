import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/model.dart';
import '../../core/data/repository.dart';
import '../../core/labels.dart';
import '../../l10n/app_localizations.dart';
import '../map/packs.dart';
import 'formats/formats.dart';

/// Writes imported layers without duplicating what is already there: a
/// layer with a known id (.hrz) is updated in place, and a layer from KML,
/// GPX or CoT whose objects are already known (same ids: the same file
/// imported again) merges into the layer holding them.
Future<int> saveImported(Repository repo, List<LayerBundle> bundles) async {
  var count = 0;
  for (final b in bundles) {
    var layerId = b.layer.id;
    if (await repo.layer(layerId) == null) {
      String? known;
      for (final f in b.features) {
        known = (await repo.feature(f.id))?.layerId;
        if (known != null) break;
      }
      if (known != null) {
        layerId = known;
      } else {
        await repo.createLayer(b.layer.name, color: b.layer.color, id: layerId);
      }
    }
    for (final f in b.features) {
      await repo.saveFeature(f.copyWith(layerId: layerId), touch: false);
      count++;
    }
  }
  return count;
}

/// Picks a file from Files / the file manager and imports it.
Future<void> importFromPicker(BuildContext context, WidgetRef ref) async {
  final picked = await FilePicker.pickFile();
  final path = picked?.path;
  if (path == null || !context.mounted) return;
  await importPath(context, ref, path);
}

/// Imports a file the user opened or shared with the app: map packs go to
/// the packs folder, everything else through the layer formats. The user
/// always sees what is inside before anything is saved.
Future<void> importPath(BuildContext context, WidgetRef ref, String path) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final name = path.split('/').last;
  if (name.toLowerCase().endsWith('.pmtiles')) {
    final pack = await ref.read(packStoreProvider).import(path);
    ref.invalidate(packsProvider);
    messenger.showSnackBar(SnackBar(content: Text(pack == null ? l.importFailed(name) : l.packImported(name))));
    return;
  }
  final Uint8List bytes;
  try {
    final file = File(path);
    if (await file.length() > 64 * 1024 * 1024) throw const FormatException('too large');
    bytes = await file.readAsBytes();
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l.importFailed(name))));
    return;
  }
  if (!context.mounted) return;
  ImportResult result;
  try {
    result = await importFile(name, bytes);
  } on PasswordRequired {
    if (!context.mounted) return;
    final password = await askPassword(context, l.importPassword);
    if (password == null || !context.mounted) return;
    try {
      result = await importFile(name, bytes, password: password);
    } on WrongPassword {
      messenger.showSnackBar(SnackBar(content: Text(l.wrongPassword)));
      return;
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.importFailed(name))));
      return;
    }
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l.importFailed(name))));
    return;
  }
  if (!context.mounted) return;
  if (await confirmImport(context, result.layers, warnings: result.warnings.length) != true) return;
  final n = await saveImported(ref.read(repositoryProvider), result.layers);
  messenger.showSnackBar(SnackBar(content: Text(l.imported(n))));
  if (context.mounted) context.go('/journal');
}

Future<bool?> confirmImport(BuildContext context, List<LayerBundle> layers, {int warnings = 0}) {
  final l = context.l10n;
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.importQuestion),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final b in layers)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.layers_outlined, color: Color(b.layer.color)),
              title: Text(b.layer.name),
              subtitle: Text(_counts(l, b.features)),
            ),
          if (warnings > 0) Text(l.importWarnings(warnings), style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.importAction)),
      ],
    ),
  );
}

String _counts(AppLocalizations l, List<MapFeature> fs) {
  final points = fs.where((f) => f.kind == FeatureKind.point).length;
  final lines = fs.where((f) => f.kind == FeatureKind.polyline).length;
  final polys = fs.where((f) => f.kind == FeatureKind.polygon).length;
  return '${l.kindPoints}: $points · ${l.kindPolylines}: $lines · ${l.kindPolygons}: $polys';
}

Future<String?> askPassword(BuildContext context, String title, {bool confirm = false}) async {
  final l = context.l10n;
  final c = TextEditingController();
  final v = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        autofocus: true,
        obscureText: true,
        enableSuggestions: false,
        autocorrect: false,
        decoration: InputDecoration(labelText: l.password, helperText: confirm ? l.passwordHint : null),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, c.text), child: Text(MaterialLocalizations.of(context).okButtonLabel)),
      ],
    ),
  );
  return v == null || v.isEmpty ? null : v;
}

/// Files handed over by the OS (share sheet, "Open in"): native code copies
/// them to the cache and sends the paths here.
const incomingChannel = EventChannel('horyzontal/incoming');
