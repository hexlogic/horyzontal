import 'package:flutter/material.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

import '../../core/labels.dart';
import 'problems.dart';

class MethodSelector extends StatelessWidget {
  const MethodSelector({super.key, required this.value, required this.onChanged});

  final ProblemMethod value;
  final ValueChanged<ProblemMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SegmentedButton<ProblemMethod>(
      segments: [
        ButtonSegment(
          value: ProblemMethod.plane,
          label: Text(l.methodPlane),
          icon: const Icon(Icons.grid_on),
        ),
        ButtonSegment(
          value: ProblemMethod.ellipsoid,
          label: Text(l.methodEllipsoid),
          icon: const Icon(Icons.public),
        ),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.single),
    );
  }
}

/// One line explaining where the problem is solved.
class FrameNote extends StatelessWidget {
  const FrameNote({super.key, required this.method, this.frame});

  final ProblemMethod method;
  final PlaneFrame? frame;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = frame;
    final text = method == ProblemMethod.ellipsoid
        ? l.ellipsoidNote
        : f == null
        ? ''
        : l.planeGrid(systemName(l, f.system), l.zoneValue(f.zone));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class OutputFormatSelector extends StatelessWidget {
  const OutputFormatSelector({super.key, required this.value, required this.onChanged});

  final AngleFormat value;
  final ValueChanged<AngleFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DropdownButtonFormField<AngleFormat>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: l.outputFormat, border: const OutlineInputBorder()),
      items: [
        for (final f in AngleFormat.values)
          DropdownMenuItem(value: f, child: Text(angleFormatName(l, f))),
      ],
      onChanged: (f) {
        if (f != null) onChanged(f);
      },
    );
  }
}
