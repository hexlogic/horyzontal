import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/data/model.dart';
import '../../core/labels.dart';
import 'point_qr.dart';

/// Full-screen-ish QR of one point for another phone to scan.
Future<void> showPointQr(BuildContext context, MapFeature f) => showDialog<void>(
      context: context,
      builder: (context) {
        final l = context.l10n;
        return AlertDialog(
          title: Text(f.name.isEmpty ? l.unnamed : f.name),
          content: SizedBox(
            width: 300,
            height: 300,
            child: QrImageView(
              data: PointQr.of(f).encode(),
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.close))],
        );
      },
    );
