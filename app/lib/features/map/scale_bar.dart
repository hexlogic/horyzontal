import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/labels.dart';
import 'geojson.dart';

/// Scale bar with a round length (1, 2 or 5 × 10^n m) of at most [maxWidth].
class ScaleBar extends StatelessWidget {
  const ScaleBar({super.key, required this.lat, required this.zoom, this.maxWidth = 110});

  final double lat, zoom, maxWidth;

  @override
  Widget build(BuildContext context) {
    final mpp = metresPerPixel(lat, zoom);
    final maxMetres = mpp * maxWidth;
    final pow10 = math.pow(10, (math.log(maxMetres) / math.ln10).floor()).toDouble();
    final step = [5, 2, 1].map((k) => k * pow10).firstWhere((v) => v <= maxMetres, orElse: () => pow10);
    final width = step / mpp;
    final l = context.l10n;
    final label = step >= 1000 ? l.kilometres('${(step / 1000).round()}') : l.metres('${step.round()}');
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: colors.onSurface, shadows: [
          Shadow(color: colors.surface, blurRadius: 3),
        ])),
        Container(
          width: width,
          height: 5,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: colors.onSurface, width: 1.5),
              right: BorderSide(color: colors.onSurface, width: 1.5),
              bottom: BorderSide(color: colors.onSurface, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
