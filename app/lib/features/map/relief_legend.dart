import 'package:flutter/material.dart';

import '../../core/labels.dart';
import 'relief.dart';

/// Colour scale of the elevation tint. The stops are spaced evenly, not by
/// height, so the dense low range stays readable.
class ReliefLegend extends StatelessWidget {
  const ReliefLegend({super.key});

  static const _labelled = [0, 200, 400, 2100];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final small = theme.textTheme.labelSmall!.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    const width = 180.0;
    final step = width / (reliefStops.length - 1);
    return Tooltip(
      message: context.l10n.demSurfaceNote,
      triggerMode: TooltipTriggerMode.tap,
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.9),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.l10n.reliefLegend, style: small),
              const SizedBox(height: 4),
              Container(
                width: width,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(colors: [for (final (_, c) in reliefStops) c]),
                ),
              ),
              SizedBox(
                width: width + 24,
                height: 14,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final (i, (h, _)) in reliefStops.indexed)
                      if (_labelled.contains(h))
                        Positioned(
                          left: i * step - (i == 0 ? 0 : 12),
                          child: Text(h.toStringAsFixed(0), style: small),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
