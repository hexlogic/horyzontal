import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/data/model.dart';
import '../../core/data/repository.dart';
import '../../core/labels.dart';
import '../../l10n/app_localizations.dart';
import '../settings/about_page.dart';
import 'formats/formats.dart';
import 'import_flow.dart';

/// Export of layers to a file shared through the system sheet (Signal,
/// Telegram, AirDrop, Files...). .hrz can be encrypted with a password.
Future<void> showExportSheet(BuildContext context, WidgetRef ref, List<MapLayer> layers) async {
  final l = context.l10n;
  final format = await showModalBottomSheet<ExportFormat>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: Text(l.exportLayer, style: Theme.of(context).textTheme.titleMedium)),
          for (final f in ExportFormat.values)
            ListTile(
              title: Text(_formatName(l, f)),
              subtitle: Text(_formatHint(l, f)),
              onTap: () => Navigator.pop(context, f),
            ),
        ],
      ),
    ),
  );
  if (format == null || !context.mounted) return;
  String? password;
  if (format == ExportFormat.hrz) {
    final encrypt = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.encryptQuestion),
        content: Text(l.encryptText),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.noEncryption)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.encrypt)),
        ],
      ),
    );
    if (encrypt == null || !context.mounted) return;
    if (encrypt) {
      password = await askPassword(context, l.exportPassword, confirm: true);
      if (password == null) return;
    }
  }
  final repo = ref.read(repositoryProvider);
  final bundles = [
    for (final layer in layers) LayerBundle(layer, await repo.featuresOf(layer.id)),
  ];
  var bytes = exportLayers(bundles, format, appVersion: appVersion);
  var name = suggestedFileName(bundles, format);
  if (password != null) {
    bytes = await encryptExport(bytes, password);
    name = name.replaceAll(RegExp(r'\.hrz$'), '.hrze');
  }
  final dir = Directory('${(await getTemporaryDirectory()).path}/export');
  await dir.create(recursive: true);
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(bytes, flush: true);
  if (!context.mounted) return;
  final box = context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(ShareParams(
    files: [XFile(file.path)],
    sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
  ));
}

String _formatName(AppLocalizations l, ExportFormat f) => switch (f) {
      ExportFormat.hrz => l.formatHrz,
      ExportFormat.kml => 'KML',
      ExportFormat.kmz => 'KMZ',
      ExportFormat.gpx => 'GPX',
      ExportFormat.cot => 'CoT (ATAK)',
      ExportFormat.atakPackage => l.formatAtakPackage,
    };

String _formatHint(AppLocalizations l, ExportFormat f) => switch (f) {
      ExportFormat.hrz => l.formatHrzHint,
      ExportFormat.kml || ExportFormat.kmz => l.formatKmlHint,
      ExportFormat.gpx => l.formatGpxHint,
      ExportFormat.cot => l.formatCotHint,
      ExportFormat.atakPackage => l.formatAtakHint,
    };
