import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

import '../../core/labels.dart';
import '../../core/settings.dart';
import '../../core/widgets/copy_tile.dart';
import '../../core/widgets/point_input.dart';
import 'problem_widgets.dart';
import 'problems.dart';

/// ОГЗ: two points give the distance and angles between them.
class InversePage extends ConsumerStatefulWidget {
  const InversePage({super.key});

  @override
  ConsumerState<InversePage> createState() => _InversePageState();
}

class _InversePageState extends ConsumerState<InversePage> {
  ProblemMethod _method = ProblemMethod.plane;
  PointValue? _a, _b;
  PlaneFrame? _frame;
  late AngleFormat _outFormat = ref.read(settingsProvider).angleOutput;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = ref.watch(settingsProvider);
    final a = _a, b = _b;
    final frame = _frame ?? (a == null ? null : planeFrameFor(a, settings.system));
    final result = a != null && b != null && frame != null
        ? solveInverse(a.wgs, b.wgs, _method, frame)
        : null;
    final plane = _method == ProblemMethod.plane;

    return Scaffold(
      appBar: AppBar(title: Text(l.taskInverse)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MethodSelector(value: _method, onChanged: (m) => setState(() => _method = m)),
          FrameSelector(
            method: _method,
            frame: frame,
            auto: _frame == null,
            onChanged: (f) => setState(() => _frame = f),
          ),
          PointInput(label: l.point1, onChanged: (v) => setState(() => _a = v)),
          const SizedBox(height: 16),
          PointInput(label: l.point2, onChanged: (v) => setState(() => _b = v)),
          if (result != null) ...[
            const SizedBox(height: 16),
            OutputFormatSelector(
              value: _outFormat,
              onChanged: (f) => setState(() => _outFormat = f),
            ),
            CopyTile(
              label: l.distance,
              value: formatDistance(l, plane ? result.gridDistance : result.ellipsoidDistance),
            ),
            AngleSetTiles(set: result.forward, format: _outFormat),
            AngleSetTiles(set: result.back, format: _outFormat, back: true),
            AngleContextTiles(at: result.atA, format: _outFormat),
            CopyTile(label: l.gridDistance, value: formatDistance(l, result.gridDistance), dense: true),
            CopyTile(
              label: l.ellipsoidDistance,
              value: formatDistance(l, result.ellipsoidDistance),
              dense: true,
            ),
            if (result.ellipsoidDistance > 0)
              CopyTile(label: l.scaleFactor, value: result.scale.toStringAsFixed(6), dense: true),
          ],
        ],
      ),
    );
  }
}
