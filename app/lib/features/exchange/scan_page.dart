import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/ids.dart';
import '../../core/data/model.dart';
import '../../core/data/repository.dart';
import '../../core/labels.dart';
import '../layers/layer_picker.dart';
import 'point_qr.dart';
import 'qr_scanner_view.dart';

/// Scans a point QR and saves it into a layer the user picks.
class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  bool _busy = false;

  Future<void> _onCode(String text) async {
    if (_busy) return;
    final qr = PointQr.decode(text);
    final l = context.l10n;
    if (qr == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.qrNotAPoint)));
      return;
    }
    setState(() => _busy = true);
    final layer = await pickLayer(context, ref, title: l.saveToLayer);
    if (layer == null) {
      if (mounted) setState(() => _busy = false);
      return;
    }
    final repo = ref.read(repositoryProvider);
    final existing = qr.id == null ? null : await repo.feature(qr.id!);
    final now = repo.now();
    final f = MapFeature(
      id: existing?.id ?? qr.id ?? newId(),
      layerId: layer.id,
      kind: FeatureKind.point,
      vertices: [qr.position],
      name: qr.name,
      description: qr.description,
      author: qr.callsign,
      sidc: qr.sidc,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await repo.saveFeature(f);
    if (!mounted) return;
    context.go('/journal/object/${f.id}');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.scanQr)),
      body: Stack(
        children: [
          QrScannerView(onCode: _onCode, paused: _busy),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(l.scanQrHint))),
            ),
          ),
        ],
      ),
    );
  }
}
