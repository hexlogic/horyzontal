import 'package:flutter/material.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

import '../../core/labels.dart';
import '../../core/widgets/copy_tile.dart';
import '../../l10n/app_localizations.dart';
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

String angleKindName(AppLocalizations l, AngleKind k) => switch (k) {
  AngleKind.grid => l.gridBearing,
  AngleKind.trueAzimuth => l.trueAzimuth,
  AngleKind.magnetic => l.magneticAzimuth,
};

String backAngleKindName(AppLocalizations l, AngleKind k) => switch (k) {
  AngleKind.grid => l.backGridBearing,
  AngleKind.trueAzimuth => l.backTrueAzimuth,
  AngleKind.magnetic => l.backMagneticAzimuth,
};

/// The grid plane problems and grid bearings use; tap to pick another grid
/// or zone. [frame] is what is in effect, [auto] whether it was chosen
/// automatically.
class FrameSelector extends StatelessWidget {
  const FrameSelector({
    super.key,
    required this.method,
    required this.frame,
    required this.auto,
    required this.onChanged,
  });

  final ProblemMethod method;
  final PlaneFrame? frame;
  final bool auto;

  /// Null goes back to the automatic choice.
  final ValueChanged<PlaneFrame?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = frame;
    final small = Theme.of(context).textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (method == ProblemMethod.ellipsoid)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l.ellipsoidNote, style: small),
          ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          leading: const Icon(Icons.grid_4x4),
          title: Text(l.planeFrame),
          subtitle: Text(
            f == null
                ? '—'
                : '${systemName(l, f.system)}, ${l.zoneValue(f.zone)}${auto ? ' · ${l.frameAutoNote}' : ''}',
          ),
          trailing: const Icon(Icons.edit_outlined, size: 20),
          onTap: f == null ? null : () => _pick(context, f),
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context, PlaneFrame current) async {
    final result = await showDialog<(PlaneFrame?,)>(
      context: context,
      builder: (_) => _FrameDialog(current: current),
    );
    if (result != null) onChanged(result.$1);
  }
}

class _FrameDialog extends StatefulWidget {
  const _FrameDialog({required this.current});
  final PlaneFrame current;

  @override
  State<_FrameDialog> createState() => _FrameDialogState();
}

class _FrameDialogState extends State<_FrameDialog> {
  static const _systems = [
    CoordinateSystem.sk42Gk,
    CoordinateSystem.usk2000Gk,
    CoordinateSystem.usk2000Tm3,
    CoordinateSystem.utm,
  ];
  late CoordinateSystem _system = widget.current.system;
  late final _zone = TextEditingController(text: '${widget.current.zone}');

  @override
  void dispose() {
    _zone.dispose();
    super.dispose();
  }

  (int, int) get _zoneRange => switch (_system) {
    CoordinateSystem.utm => (1, 60),
    CoordinateSystem.usk2000Tm3 => (7, 13),
    _ => (1, 60),
  };

  int? get _zoneValue {
    final z = int.tryParse(_zone.text);
    final (lo, hi) = _zoneRange;
    return z != null && z >= lo && z <= hi ? z : null;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final zone = _zoneValue;
    return AlertDialog(
      title: Text(l.planeFrame),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<CoordinateSystem>(
            initialValue: _system,
            isExpanded: true,
            items: [
              for (final s in _systems) DropdownMenuItem(value: s, child: Text(systemName(l, s))),
            ],
            onChanged: (s) => setState(() => _system = s!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _zone,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l.zone,
              border: const OutlineInputBorder(),
              errorText: _zone.text.isNotEmpty && zone == null ? l.errMissingZone : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, (null,)), child: Text(l.frameAuto)),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          onPressed: zone == null
              ? null
              : () => Navigator.pop(context, (PlaneFrame(_system, zone),)),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class AngleKindSelector extends StatelessWidget {
  const AngleKindSelector({super.key, required this.value, required this.onChanged});

  final AngleKind value;
  final ValueChanged<AngleKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DropdownButtonFormField<AngleKind>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: l.angleKind, border: const OutlineInputBorder()),
      items: [
        for (final k in AngleKind.values)
          DropdownMenuItem(value: k, child: Text(angleKindName(l, k))),
      ],
      onChanged: (k) {
        if (k != null) onChanged(k);
      },
    );
  }
}

/// A direction in all three kinds.
class AngleSetTiles extends StatelessWidget {
  const AngleSetTiles({super.key, required this.set, required this.format, this.back = false});

  final AngleSet set;
  final AngleFormat format;
  final bool back;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      children: [
        for (final k in AngleKind.values)
          CopyTile(
            label: back ? backAngleKindName(l, k) : angleKindName(l, k),
            value: formatAngle(set.of(k), format),
          ),
      ],
    );
  }
}

/// Convergence, declination and direction correction at a point.
class AngleContextTiles extends StatelessWidget {
  const AngleContextTiles({super.key, required this.at, required this.format});

  final AngleContext at;
  final AngleFormat format;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String a(double d) => formatAngle(d, format, signed: true);
    return Column(
      children: [
        CopyTile(label: l.convergence, value: a(at.convergence), dense: true),
        CopyTile(label: l.declination, value: a(at.declination), dense: true),
        CopyTile(label: l.directionCorrection, value: a(at.directionCorrection), dense: true),
      ],
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

class GeoFormatSelector extends StatelessWidget {
  const GeoFormatSelector({super.key, required this.value, required this.onChanged});

  final GeoFormat value;
  final ValueChanged<GeoFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DropdownButtonFormField<GeoFormat>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: l.geoFormat, border: const OutlineInputBorder()),
      items: [
        for (final f in GeoFormat.values)
          DropdownMenuItem(value: f, child: Text(geoFormatName(l, f))),
      ],
      onChanged: (f) {
        if (f != null) onChanged(f);
      },
    );
  }
}
