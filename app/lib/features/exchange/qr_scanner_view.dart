import 'package:camera/camera.dart' show availableCameras;
import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart';

import '../../core/labels.dart';

/// Camera QR scanner on zxing-cpp: no Google ML Kit, nothing leaves the
/// device. [onCode] gets each new text once; while [paused] codes are
/// ignored.
class QrScannerView extends StatefulWidget {
  const QrScannerView({super.key, required this.onCode, this.paused = false});

  final ValueChanged<String> onCode;
  final bool paused;

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  Exception? _error;
  bool _noCamera = false;
  String? _last;
  DateTime _lastAt = DateTime(0);

  @override
  void initState() {
    super.initState();
    // The reader waits forever on a device without a camera (a simulator).
    availableCameras().then((c) {
      if (c.isEmpty && mounted) setState(() => _noCamera = true);
    }, onError: (Object e) {
      if (mounted) setState(() => _error = e is Exception ? e : Exception('$e'));
    });
  }

  void _onScan(Code code) {
    final text = code.text;
    if (widget.paused || !code.isValid || text == null || text.isEmpty) return;
    // The same code stays in view for a while: report it again only after a pause.
    final now = DateTime.now();
    if (text == _last && now.difference(_lastAt) < const Duration(seconds: 3)) return;
    _last = text;
    _lastAt = now;
    widget.onCode(text);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (_error != null || _noCamera) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_outlined, size: 48),
              const SizedBox(height: 12),
              Text(l.cameraUnavailable, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    return ReaderWidget(
      codeFormat: Format.qrCode,
      tryHarder: true,
      tryInverted: true,
      showGallery: false,
      showToggleCamera: false,
      cropPercent: 0.7,
      scanDelay: const Duration(milliseconds: 300),
      scanDelaySuccess: const Duration(milliseconds: 1000),
      onScan: _onScan,
      onControllerCreated: (_, error) {
        if (error != null && mounted) setState(() => _error = error);
      },
    );
  }
}
