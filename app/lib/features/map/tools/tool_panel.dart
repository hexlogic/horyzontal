import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

import '../../../core/labels.dart';
import '../../../core/settings.dart';
import '../../../core/widgets/copy_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../../tasks/problem_widgets.dart';
import '../../tasks/problems.dart';
import 'tool_readouts.dart';
import 'tool_state.dart';

String toolName(AppLocalizations l, MapTool t) => switch (t) {
  MapTool.ruler => l.toolRuler,
  MapTool.polyline => l.toolPolyline,
  MapTool.polygon => l.toolPolygon,
  MapTool.profile => l.toolProfile,
  MapTool.lineOfSight => l.toolLos,
};

IconData toolIcon(MapTool t) => switch (t) {
  MapTool.ruler => Icons.straighten,
  MapTool.polyline => Icons.timeline,
  MapTool.polygon => Icons.pentagon_outlined,
  MapTool.profile => Icons.area_chart_outlined,
  MapTool.lineOfSight => Icons.cell_tower,
};

/// Bottom card of the active map tool: live readouts against the crosshair
/// ([cursor]), a button that adds the crosshair as a vertex, undo, restart,
/// close, and the tool's own action ([onAction], e.g. save or build).
class ToolPanel extends ConsumerStatefulWidget {
  const ToolPanel({
    super.key,
    required this.cursor,
    required this.onAdd,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  final ValueListenable<Geodetic?> cursor;
  final VoidCallback onAdd;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  ConsumerState<ToolPanel> createState() => _ToolPanelState();
}

class _ToolPanelState extends ConsumerState<ToolPanel> {
  AngleKind _kind = AngleKind.grid;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final state = ref.watch(mapToolProvider);
    final tool = state.tool!;
    final ctl = ref.read(mapToolProvider.notifier);
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(16),
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(toolIcon(tool), size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(toolName(l, tool), style: theme.textTheme.titleSmall)),
                IconButton(
                  tooltip: l.undoPoint,
                  onPressed: state.vertices.isEmpty ? null : ctl.undo,
                  icon: const Icon(Icons.undo),
                ),
                IconButton(
                  tooltip: l.clearPoints,
                  onPressed: state.vertices.isEmpty ? null : ctl.clear,
                  icon: const Icon(Icons.restart_alt),
                ),
                IconButton(
                  tooltip: l.closeTool,
                  onPressed: ctl.close,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ValueListenableBuilder(
                valueListenable: widget.cursor,
                builder: (context, cursor, _) => _Readouts(
                  state: state,
                  cursor: cursor,
                  kind: _kind,
                  onCycleKind: () =>
                      setState(() => _kind = AngleKind.values[(_kind.index + 1) % 3]),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: widget.onAdd,
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: Text(l.addPoint),
                    ),
                  ),
                  if (widget.actionLabel != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: widget.onAction,
                        icon: Icon(widget.actionIcon),
                        label: Text(widget.actionLabel!, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Readouts extends ConsumerWidget {
  const _Readouts({
    required this.state,
    required this.cursor,
    required this.kind,
    required this.onCycleKind,
  });

  final ToolState state;
  final Geodetic? cursor;
  final AngleKind kind;
  final VoidCallback onCycleKind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final settings = ref.watch(settingsProvider);
    final v = state.vertices;
    final tool = state.tool!;
    String angle(double d) => formatAngle(d, settings.angleOutput);
    if (v.isEmpty) return _Line(text: l.toolHint, muted: true);

    switch (tool) {
      case MapTool.ruler:
      case MapTool.lineOfSight:
        final b = v.length == 2 ? v[1] : cursor;
        if (b == null) return const SizedBox.shrink();
        final frame = PlaneFrame.auto(v[0], settings.system);
        final r = rulerReadout(v[0], b, cursor, frame, fixed: v.length == 2);
        final heights = ref.watch(toolHeightsProvider).value;
        final dh =
            heights != null && heights.length == 2 && heights[0] != null && heights[1] != null
            ? heights[1]! - heights[0]!
            : null;
        final dev = r.deviation;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Pair(
              _Line(label: v.length == 2 ? l.distance : l.toCrosshair, text: formatDistance(l, r.distance)),
              dh == null ? null : _Line(label: l.heightDiff, text: formatSignedMetres(l, dh)),
            ),
            _Line(
              label: '${angleKindName(l, kind)} / ${l.backShort}',
              text: '${angle(r.forward.of(kind))} / ${angle(r.back.of(kind))}',
              onTap: onCycleKind,
              trailing: Icons.sync,
            ),
            if (tool == MapTool.ruler) ...[
              _Line(
                label: '${l.deltaXY} (${systemName(l, frame.system)})',
                text: 'ΔX ${formatSignedMetres(l, r.dx)}   ΔY ${formatSignedMetres(l, r.dy)}',
              ),
              if (dev != null && dev.distance > 0)
                _Line(
                  label: l.deviation,
                  text: [
                    dev.range >= 0
                        ? l.rangeOver(formatDistance(l, dev.range))
                        : l.rangeShort(formatDistance(l, -dev.range)),
                    dev.cross >= 0
                        ? l.deviationRight(formatDistance(l, dev.cross))
                        : l.deviationLeft(formatDistance(l, -dev.cross)),
                    formatAngle(dev.angle, settings.angleOutput, signed: true),
                  ].join(' · '),
                ),
            ],
          ],
        );
      case MapTool.polyline:
      case MapTool.polygon:
      case MapTool.profile:
        final r = pathReadout(v, cursor, closed: tool.closed);
        final next = r.next;
        final frame = PlaneFrame.auto(v.last, settings.system);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (tool == MapTool.polygon)
              _Pair(
                _Line(
                  label: l.area,
                  text: r.polygon != null
                      ? formatArea(l, r.polygon!.area)
                      : r.withNext != null
                      ? '→ ${formatArea(l, r.withNext!)}'
                      : '—',
                ),
                _Line(label: l.perimeter, text: formatDistance(l, r.metrics.length)),
              )
            else
              _Line(
                label: l.length,
                text: [
                  formatDistance(l, r.metrics.length),
                  if (r.withNext != null) '→ ${formatDistance(l, r.withNext!)}',
                ].join('   '),
              ),
            if (next != null)
              _Pair(
                _Line(
                  label: '${l.toCrosshair}, ${angleKindName(l, kind).toLowerCase()}',
                  text:
                      '${formatDistance(l, next.length)}   ${angle(angleContextAt(v.last, frame).fromTrue(next.azimuth1).of(kind))}',
                  onTap: onCycleKind,
                ),
                r.nextAngle == null ? null : _Line(label: l.vertexAngle, text: angle(r.nextAngle!)),
              ),
          ],
        );
    }
  }
}

class _Line extends StatelessWidget {
  const _Line({this.label, required this.text, this.muted = false, this.onTap, this.trailing});

  final String? label;
  final String text;
  final bool muted;
  final VoidCallback? onTap;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap ?? (muted ? null : () => copyToClipboard(context, text)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label != null)
                    Text(
                      label!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  Text(
                    text,
                    style: (muted ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)
                        ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              Icon(trailing, size: 16, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Two readouts side by side.
class _Pair extends StatelessWidget {
  const _Pair(this.a, this.b);
  final Widget a;
  final Widget? b;

  @override
  Widget build(BuildContext context) => b == null
      ? a
      : Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b!)],
        );
}
