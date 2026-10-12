import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

import '../../core/labels.dart';
import '../../core/settings.dart';
import '../../core/widgets/angle_input.dart';
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
  PlaneFrame? _frame;
  double? _distance, _angle;
  bool _distanceError = false, _km = false, _ground = false;
  AngleKind _kind = AngleKind.grid;
  late AngleFormat _inFormat = ref.read(settingsProvider).angleInput;
  late AngleFormat _outFormat = ref.read(settingsProvider).angleOutput;
  late GeoFormat _geoFormat = ref.read(settingsProvider).geoFormat;
  final _distanceText = TextEditingController();

  @override
  void dispose() {
    _distanceText.dispose();
    super.dispose();
  }

  void _parseDistance() {
    final t = _distanceText.text;
    final d = double.tryParse(t.replaceAll(',', '.'));
    setState(() {
      _distance = d == null ? null : d * (_km ? 1000 : 1);
      _distanceError = t.isNotEmpty && (d == null || d < 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = ref.watch(settingsProvider);
    final start = _start;
    final frame = _frame ?? (start == null ? null : planeFrameFor(start, settings.system));
    DirectSolution? result;
    if (start != null && frame != null && _distance != null && _angle != null) {
      result = solveDirect(
        start.wgs,
        _distance!,
        _angle!,
        _kind,
        _method,
        frame,
        groundDistance: _ground,
      );
    }
    final plane = _method == ProblemMethod.plane;

    return Scaffold(
      appBar: AppBar(title: Text(l.taskDirect)),
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
          PointInput(label: l.startPoint, onChanged: (v) => setState(() => _start = v)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _distanceText,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                  decoration: InputDecoration(
                    labelText: l.distance,
                    border: const OutlineInputBorder(),
                    errorText: _distanceError ? l.errDistance : null,
                  ),
                  onChanged: (_) => _parseDistance(),
                ),
              ),
              const SizedBox(width: 8),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(l.unitM)),
                  ButtonSegment(value: true, label: Text(l.unitKm)),
                ],
                selected: {_km},
                showSelectedIcon: false,
                onSelectionChanged: (s) {
                  _km = s.single;
                  _parseDistance();
                },
              ),
            ],
          ),
          if (plane)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.groundDistance),
              subtitle: Text(l.groundDistanceHint),
              value: _ground,
              onChanged: (v) => setState(() => _ground = v),
            ),
          const SizedBox(height: 12),
          AngleKindSelector(value: _kind, onChanged: (k) => setState(() => _kind = k)),
          const SizedBox(height: 12),
          AngleInput(
            label: angleKindName(l, _kind),
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
            AngleSetTiles(set: result.back, format: _outFormat, back: true),
            AngleContextTiles(at: result.atStart, format: _outFormat),
            const SizedBox(height: 16),
            Text(l.endPoint, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            GeoFormatSelector(value: _geoFormat, onChanged: (f) => setState(() => _geoFormat = f)),
            PointResults(wgs: result.end, geoFormat: _geoFormat),
          ],
        ],
      ),
    );
  }
}
