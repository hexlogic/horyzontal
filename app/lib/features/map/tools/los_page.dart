import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

import '../../../core/labels.dart';
import '../../../core/settings.dart';
import '../../../core/widgets/copy_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../elevation.dart';
import 'elevation_chart.dart';
import 'profile_page.dart';

/// Line of sight between antennas on masts at [a] and [b], over the ground
/// from the elevation packs with the Earth's curvature and refraction.
class LosPage extends ConsumerStatefulWidget {
  const LosPage({super.key, required this.a, required this.b});
  final Geodetic a, b;

  @override
  ConsumerState<LosPage> createState() => _LosPageState();
}

class _LosPageState extends ConsumerState<LosPage> {
  late final Future<Profile?> _profile = _load();
  late LosParams _params = ref.read(settingsProvider).los;
  late CoordinateSystem _system = ref.read(settingsProvider).system;
  int? _cursor;

  Future<Profile?> _load() async {
    final dem = await ref.read(demProvider.future);
    return dem == null ? null : buildProfile(dem, [widget.a, widget.b]);
  }

  void _set(LosParams p) {
    setState(() => _params = p);
    ref.read(settingsProvider.notifier).update((s) => s.copyWith(los: p));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.toolLos)),
      body: FutureBuilder(
        future: _profile,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          final p = snap.data;
          if (p == null || p.heights.first == null || p.heights.last == null) {
            return NoDemMessage(hasPacks: p != null);
          }
          return _body(context, l, p);
        },
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l, Profile p) {
    final s = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final mid = p.points[p.points.length ~/ 2];
    final f = _params.frequencyMhz;
    final r = lineOfSight(
      distances: p.distances,
      terrain: p.heights,
      mastA: _params.mastA,
      mastB: _params.mastB,
      k: _params.k,
      frequencyHz: f == null ? null : f * 1e6,
      radius: gaussianRadius(mid.lat),
    )!;
    String m(double v) => l.metres(v.toStringAsFixed(v.abs() < 10 ? 1 : 0));
    final good = theme.colorScheme.primary, bad = theme.colorScheme.error;
    final c = _cursor;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        ListTile(
          leading: Icon(r.visible ? Icons.visibility : Icons.visibility_off, color: r.visible ? good : bad),
          title: Text(
            r.visible ? l.losVisible : l.losBlocked(formatDistance(l, r.firstObstruction!)),
            style: theme.textTheme.titleMedium?.copyWith(color: r.visible ? good : bad),
          ),
          subtitle: r.worstIndex >= 0 ? Text('${l.minClearance}: ${m(r.minClearance)}') : null,
        ),
        if (r.minFresnelRatio != null)
          ListTile(
            dense: true,
            leading: Icon(Icons.wifi_tethering, color: r.fresnelClear ? good : bad),
            title: Text(
              r.fresnelClear
                  ? l.fresnelClear
                  : l.fresnelBlocked((r.minFresnelRatio! * 100).clamp(-999, 999).toStringAsFixed(0)),
            ),
          ),
        SizedBox(
          height: 240,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ElevationChart(
              distances: p.distances,
              terrain: [for (final x in r.samples) x.obstacle],
              ray: [for (final x in r.samples) x.ray],
              fresnel: f == null ? null : [for (final x in r.samples) x.fresnel],
              blocked: [for (final x in r.samples) (x.clearance ?? 1) < 0],
              cursor: c,
              onCursor: (i) => setState(() => _cursor = i),
              formatDistance: (d) => d >= 1000 ? l.kilometres((d / 1000).toStringAsFixed(d < 10000 ? 1 : 0)) : l.metres(d.toStringAsFixed(0)),
            ),
          ),
        ),
        if (c != null && r.samples[c].clearance != null)
          CopyTile(
            label: l.atDistance(formatDistance(l, p.distances[c])),
            value: '${m(p.heights[c]!)} · ${l.minClearance.toLowerCase()}: ${m(r.samples[c].clearance!)}',
            dense: true,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: _NumberField(
                  label: l.mastA,
                  value: _params.mastA,
                  onChanged: (v) => _set(LosParams(mastA: v ?? 0, mastB: _params.mastB, k: _params.k, frequencyMhz: f)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumberField(
                  label: l.mastB,
                  value: _params.mastB,
                  onChanged: (v) => _set(LosParams(mastA: _params.mastA, mastB: v ?? 0, k: _params.k, frequencyMhz: f)),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: DropdownButtonFormField<double>(
            initialValue: const [0.0, refractionOptical, refractionRadio].contains(_params.k) ? _params.k : refractionOptical,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.refraction, border: const OutlineInputBorder()),
            items: [
              DropdownMenuItem(value: 0.0, child: Text(l.refractionNone)),
              DropdownMenuItem(value: refractionOptical, child: Text(l.refractionOptical)),
              DropdownMenuItem(value: refractionRadio, child: Text(l.refractionRadio)),
            ],
            onChanged: (k) => _set(LosParams(mastA: _params.mastA, mastB: _params.mastB, k: k!, frequencyMhz: f)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: _NumberField(
            label: l.frequencyMhz,
            value: f,
            onChanged: (v) => _set(
              LosParams(
                mastA: _params.mastA,
                mastB: _params.mastB,
                k: _params.k,
                frequencyMhz: v != null && v > 0 ? v : null,
              ),
            ),
          ),
        ),
        CopyTile(label: l.distance, value: formatDistance(l, p.distances.last)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SystemSelector(value: _system, onChanged: (v) => setState(() => _system = v)),
        ),
        CopyTile(
          label: '${l.pointA} · ${m(p.heights.first!)} + ${m(_params.mastA)}',
          value: pointText(widget.a, _system, s.geoFormat),
        ),
        CopyTile(
          label: '${l.pointB} · ${m(p.heights.last!)} + ${m(_params.mastB)}',
          value: pointText(widget.b, _system, s.geoFormat),
        ),
        DemNotes(complete: r.complete),
      ],
    );
  }
}

class _NumberField extends StatefulWidget {
  const _NumberField({required this.label, required this.value, required this.onChanged});

  final String label;
  final double? value;
  final ValueChanged<double?> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final _text = TextEditingController(text: _show(widget.value));

  static String _show(double? v) => v == null ? '' : (v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v');

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _text,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
    decoration: InputDecoration(labelText: widget.label, border: const OutlineInputBorder()),
    onChanged: (t) => widget.onChanged(double.tryParse(t.replaceAll(',', '.'))),
  );
}
