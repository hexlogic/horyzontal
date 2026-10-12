import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/data/ids.dart';
import '../../core/data/model.dart';
import '../../core/data/repository.dart';
import '../../core/labels.dart';
import '../layers/layer_picker.dart';
import 'point_qr.dart';

/// Scans a point QR and saves it into a layer the user picks.
class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  final _scanner = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  bool _busy = false;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final text = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
    if (text == null) return;
    final qr = PointQr.decode(text);
    final l = context.l10n;
    if (qr == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.qrNotAPoint)));
      return;
    }
    _busy = true;
    await _scanner.stop();
    if (!mounted) return;
    final layer = await pickLayer(context, ref, title: l.saveToLayer);
    if (layer == null) {
      _busy = false;
      await _scanner.start();
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
          MobileScanner(controller: _scanner, onDetect: _onDetect),
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
