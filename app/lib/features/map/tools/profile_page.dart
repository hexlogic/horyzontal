import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

import '../../../core/labels.dart';
import '../../../core/settings.dart';
import '../../../core/widgets/copy_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../elevation.dart';
import 'elevation_chart.dart';

/// Heights sampled along a path.
class Profile {
  Profile(this.points, this.distances, this.heights);

  final List<Geodetic> points;
  final List<double> distances;
  final List<double?> heights;

  Iterable<double> get _known => heights.whereType<double>();
  bool get complete => heights.every((h) => h != null);
  bool get empty => _known.isEmpty;
  double get min => _known.reduce(math.min);
  double get max => _known.reduce(math.max);

  /// Total climb and descent along the path, metres.
  (double, double) get ascentDescent {
    var up = 0.0, down = 0.0;
    double? prev;
    for (final h in heights) {
      if (h == null) continue;
      if (prev != null && h > prev) up += h - prev;
      if (prev != null && h < prev) down += prev - h;
      prev = h;
    }
    return (up, down);
  }
}

/// Sample count for a path: about one per 20 m (the elevation grid is ~24 m
/// at z12 in Ukraine), between 64 and 1024.
int profileSamples(double length) => (length / 20).clamp(64, 1024).round();

Future<Profile> buildProfile(Dem dem, List<Geodetic> path) async {
  final pts = densify(path, profileSamples(cumulativeDistances(path).last));
  return Profile(pts, cumulativeDistances(pts), await dem.sample(pts));
}

/// Elevation profile along [path] with the ends' coordinates in a chosen
/// system and a cursor over the chart.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key, required this.path});
  final List<Geodetic> path;

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late final Future<Profile?> _profile = _load();
  late CoordinateSystem _system = ref.read(settingsProvider).system;
  int? _cursor;

  Future<Profile?> _load() async {
    final dem = await ref.read(demProvider.future);
    return dem == null ? null : buildProfile(dem, widget.path);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.toolProfile)),
      body: FutureBuilder(
        future: _profile,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          final p = snap.data;
          if (p == null || p.empty) return NoDemMessage(hasPacks: p != null);
          return _body(context, l, p);
        },
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l, Profile p) {
    final s = ref.watch(settingsProvider);
    final (up, down) = p.ascentDescent;
    final c = _cursor;
    String m(double v) => l.metres(v.toStringAsFixed(0));
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        SizedBox(
          height: 240,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ElevationChart(
              distances: p.distances,
              terrain: p.heights,
              cursor: c,
              onCursor: (i) => setState(() => _cursor = i),
              formatDistance: (d) => d >= 1000 ? l.kilometres((d / 1000).toStringAsFixed(d < 10000 ? 1 : 0)) : l.metres(d.toStringAsFixed(0)),
            ),
          ),
        ),
        if (c != null)
          CopyTile(
            label: l.atDistance(formatDistance(l, p.distances[c])),
            value: [
              if (p.heights[c] != null) m(p.heights[c]!),
              pointText(p.points[c], _system, s.geoFormat),
            ].join(' · '),
          ),
        CopyTile(label: l.length, value: formatDistance(l, p.distances.last)),
        CopyTile(label: l.heightRange, value: '${m(p.min)} / ${m(p.max)}'),
        CopyTile(label: l.ascentDescent, value: '+${m(up)} / −${m(down)}'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SystemSelector(value: _system, onChanged: (v) => setState(() => _system = v)),
        ),
        CopyTile(
          label: [l.startPoint, if (p.heights.first != null) m(p.heights.first!)].join(' · '),
          value: pointText(p.points.first, _system, s.geoFormat),
        ),
        CopyTile(
          label: [l.endPoint, if (p.heights.last != null) m(p.heights.last!)].join(' · '),
          value: pointText(p.points.last, _system, s.geoFormat),
        ),
        DemNotes(complete: p.complete),
      ],
    );
  }
}

String pointText(Geodetic g, CoordinateSystem system, GeoFormat geoFormat) {
  try {
    return formatPoint(g, system, geoFormat);
  } on RangeError {
    return formatPoint(g, CoordinateSystem.wgs84, geoFormat);
  }
}

class SystemSelector extends StatelessWidget {
  const SystemSelector({super.key, required this.value, required this.onChanged});

  final CoordinateSystem value;
  final ValueChanged<CoordinateSystem> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DropdownButtonFormField<CoordinateSystem>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: l.inputSystem, border: const OutlineInputBorder()),
      items: [
        for (final s in CoordinateSystem.values) DropdownMenuItem(value: s, child: Text(systemName(l, s))),
      ],
      onChanged: (s) {
        if (s != null) onChanged(s);
      },
    );
  }
}

/// The surface-model caveat, and a warning about gaps in the data.
class DemNotes extends StatelessWidget {
  const DemNotes({super.key, required this.complete});
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!complete)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(l.demGaps, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
            ),
          Text(l.demSurfaceNote, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class NoDemMessage extends StatelessWidget {
  const NoDemMessage({super.key, this.hasPacks = false});

  /// Elevation packs exist but none covers the line.
  final bool hasPacks;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.terrain_outlined, size: 48),
            const SizedBox(height: 12),
            Text(l.noDemPack, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l.noDemPackHint, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: () => context.go('/map/packs'), child: Text(l.offlinePacks)),
          ],
        ),
      ),
    );
  }
}
