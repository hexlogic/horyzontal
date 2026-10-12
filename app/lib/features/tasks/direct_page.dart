import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

import '../../core/labels.dart';
import '../../core/settings.dart';
import '../../core/widgets/angle_input.dart';
import '../../core/widgets/copy_tile.dart';
import '../../core/widgets/point_input.dart';
import '../../core/widgets/point_results.dart';
import 'problem_widgets.dart';
import 'problems.dart';

/// ПГЗ: start point, distance and angle give the end point.
class DirectPage extends ConsumerStatefulWidget {
  const DirectPage({super.key});

  @override
  ConsumerState<DirectPage> createState() => _DirectPageState();
}

class _DirectPageState extends ConsumerState<DirectPage> {
  ProblemMethod _method = ProblemMethod.plane;
  PointValue? _start;
  double? _distance, _angle;
  bool _distanceError = false;
  late AngleFormat _inFormat = ref.read(settingsProvider).angleInput;
  late AngleFormat _outFormat = ref.read(settingsProvider).angleOutput;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = ref.watch(settingsProvider);
    final start = _start;
    final frame = start == null ? null : PlaneFrame.forPoint(start, settings.system);
    DirectSolution? result;
    if (start != null && frame != null && _distance != null && _angle != null) {
      result = solveDirect(start.wgs, _distance!, _angle!, _method, frame);
    }
    final plane = _method == ProblemMethod.plane;

    return Scaffold(
      appBar: AppBar(title: Text(l.taskDirect)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MethodSelector(value: _method, onChanged: (m) => setState(() => _method = m)),
          FrameNote(method: _method, frame: frame),
          PointInput(label: l.startPoint, onChanged: (v) => setState(() => _start = v)),
          const SizedBox(height: 12),
          TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
            decoration: InputDecoration(
              labelText: l.distanceM,
              border: const OutlineInputBorder(),
              errorText: _distanceError ? l.errDistance : null,
            ),
            onChanged: (t) {
              final d = double.tryParse(t.replaceAll(',', '.'));
              setState(() {
                _distance = d;
                _distanceError = t.isNotEmpty && (d == null || d < 0);
              });
            },
          ),
          const SizedBox(height: 12),
          AngleInput(
            label: plane ? l.gridBearing : l.azimuth,
            format: _inFormat,
            onFormatChanged: (f) => setState(() => _inFormat = f),
            onChanged: (v) => setState(() => _angle = v),
          ),
          if (result != null) ...[
            const SizedBox(height: 16),
            OutputFormatSelector(
              value: _outFormat,
              onChanged: (f) => setState(() => _outFormat = f),
            ),
            CopyTile(
              label: plane ? l.backGridBearing : l.backAzimuth,
              value: formatAngle(result.backAngle, _outFormat),
            ),
            const SizedBox(height: 8),
            Text(l.endPoint, style: Theme.of(context).textTheme.titleSmall),
            PointResults(wgs: result.end),
          ],
        ],
      ),
    );
  }
}
