import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Heights along a line, with optional line-of-sight overlays. Dragging or
/// tapping moves a cursor over the samples.
class ElevationChart extends StatelessWidget {
  const ElevationChart({
    super.key,
    required this.distances,
    required this.terrain,
    this.ray,
    this.fresnel,
    this.blocked,
    this.cursor,
    this.onCursor,
    this.formatDistance,
  });

  /// Metres from the start, increasing.
  final List<double> distances;

  /// Ground height at each distance, null where unknown. For line of sight
  /// this already includes the Earth's curvature.
  final List<double?> terrain;

  /// Line of sight height at each distance.
  final List<double>? ray;

  /// First Fresnel zone radius around [ray].
  final List<double?>? fresnel;

  /// Samples where the ground blocks the ray.
  final List<bool>? blocked;

  final int? cursor;
  final ValueChanged<int>? onCursor;
  final String Function(double metres)? formatDistance;

  void _pick(Offset local, Size size) {
    final cb = onCursor;
    if (cb == null || distances.length < 2) return;
    final plot = _ChartPainter.plotRect(size);
    final t = ((local.dx - plot.left) / plot.width).clamp(0.0, 1.0);
    final d = t * distances.last;
    var best = 0;
    for (var i = 1; i < distances.length; i++) {
      if ((distances[i] - d).abs() < (distances[best] - d).abs()) best = i;
    }
    cb(best);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        return GestureDetector(
          onTapDown: (e) => _pick(e.localPosition, size),
          onHorizontalDragUpdate: (e) => _pick(e.localPosition, size),
          child: CustomPaint(
            size: size,
            painter: _ChartPainter(
              distances: distances,
              terrain: terrain,
              ray: ray,
              fresnel: fresnel,
              blocked: blocked,
              cursor: cursor,
              ground: theme.colorScheme.primary,
              rayColor: theme.colorScheme.tertiary,
              blockedColor: theme.colorScheme.error,
              grid: theme.colorScheme.outlineVariant,
              label: theme.textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSurfaceVariant),
              formatDistance: formatDistance ?? (m) => '${(m / 1000).toStringAsFixed(1)} км',
            ),
          ),
        );
      },
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.distances,
    required this.terrain,
    required this.ray,
    required this.fresnel,
    required this.blocked,
    required this.cursor,
    required this.ground,
    required this.rayColor,
    required this.blockedColor,
    required this.grid,
    required this.label,
    required this.formatDistance,
  });

  final List<double> distances;
  final List<double?> terrain;
  final List<double>? ray;
  final List<double?>? fresnel;
  final List<bool>? blocked;
  final int? cursor;
  final Color ground, rayColor, blockedColor, grid;
  final TextStyle label;
  final String Function(double) formatDistance;

  static Rect plotRect(Size s) => Rect.fromLTRB(44, 8, s.width - 8, s.height - 22);

  @override
  void paint(Canvas canvas, Size size) {
    if (distances.length < 2 || distances.last <= 0) return;
    final plot = plotRect(size);
    final values = <double>[
      for (final t in terrain) ?t,
      ...?ray,
      if (ray != null && fresnel != null)
        for (var i = 0; i < ray!.length; i++)
          if (fresnel![i] != null) ray![i] - fresnel![i]!,
    ];
    if (values.isEmpty) return;
    var lo = values.reduce(math.min), hi = values.reduce(math.max);
    final pad = math.max((hi - lo) * 0.08, 5.0);
    lo -= pad;
    hi += pad;
    final step = _niceStep((hi - lo) / 4);
    lo = (lo / step).floor() * step;
    hi = (hi / step).ceil() * step;

    double x(double d) => plot.left + d / distances.last * plot.width;
    double y(double h) => plot.bottom - (h - lo) / (hi - lo) * plot.height;

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var h = lo; h <= hi + step / 2; h += step) {
      canvas.drawLine(Offset(plot.left, y(h)), Offset(plot.right, y(h)), gridPaint);
      _text(canvas, h.toStringAsFixed(0), Offset(plot.left - 4, y(h)), alignRight: true);
    }
    final xStep = _niceStep(distances.last / 4);
    for (var d = 0.0; d <= distances.last + 1e-6; d += xStep) {
      canvas.drawLine(Offset(x(d), plot.top), Offset(x(d), plot.bottom), gridPaint);
      _text(canvas, formatDistance(d), Offset(x(d), plot.bottom + 10), center: true);
    }

    // Ground: filled area, broken where heights are unknown.
    final fill = Paint()..color = ground.withValues(alpha: 0.18);
    final line = Paint()
      ..color = ground
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    var run = <Offset>[];
    void flush() {
      if (run.length >= 2) {
        final area = Path()..moveTo(run.first.dx, plot.bottom);
        for (final p in run) {
          area.lineTo(p.dx, p.dy);
        }
        area
          ..lineTo(run.last.dx, plot.bottom)
          ..close();
        canvas.drawPath(area, fill);
        canvas.drawPath(Path()..addPolygon(run, false), line);
      }
      run = [];
    }

    for (var i = 0; i < distances.length; i++) {
      final t = terrain[i];
      if (t == null) {
        flush();
      } else {
        run.add(Offset(x(distances[i]), y(t)));
      }
    }
    flush();

    final b = blocked;
    if (b != null) {
      final bad = Paint()
        ..color = blockedColor
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      for (var i = 1; i < distances.length; i++) {
        final t0 = terrain[i - 1], t1 = terrain[i];
        if ((b[i] || b[i - 1]) && t0 != null && t1 != null) {
          canvas.drawLine(Offset(x(distances[i - 1]), y(t0)), Offset(x(distances[i]), y(t1)), bad);
        }
      }
    }

    final r = ray;
    if (r != null) {
      final f = fresnel;
      if (f != null) {
        final lower = <Offset>[
          for (var i = 0; i < r.length; i++) Offset(x(distances[i]), y(r[i] - (f[i] ?? 0))),
        ];
        final upper = <Offset>[
          for (var i = r.length - 1; i >= 0; i--) Offset(x(distances[i]), y(r[i] + (f[i] ?? 0))),
        ];
        canvas.drawPath(Path()..addPolygon([...lower, ...upper], true), Paint()..color = rayColor.withValues(alpha: 0.12));
      }
      canvas.drawLine(
        Offset(x(distances.first), y(r.first)),
        Offset(x(distances.last), y(r.last)),
        Paint()
          ..color = rayColor
          ..strokeWidth = 2,
      );
    }

    final c = cursor;
    if (c != null && c >= 0 && c < distances.length) {
      final cx = x(distances[c]);
      canvas.drawLine(
        Offset(cx, plot.top),
        Offset(cx, plot.bottom),
        Paint()
          ..color = label.color!
          ..strokeWidth = 1,
      );
      final t = terrain[c];
      if (t != null) canvas.drawCircle(Offset(cx, y(t)), 4, Paint()..color = ground);
    }
  }

  void _text(Canvas canvas, String s, Offset at, {bool alignRight = false, bool center = false}) {
    final tp = TextPainter(text: TextSpan(text: s, style: label), textDirection: TextDirection.ltr)..layout();
    final dx = alignRight ? at.dx - tp.width : (center ? at.dx - tp.width / 2 : at.dx);
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  static double _niceStep(double raw) {
    if (raw <= 0) return 1;
    final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final f = raw / mag;
    return (f < 1.5 ? 1 : f < 3.5 ? 2 : f < 7.5 ? 5 : 10) * mag;
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.cursor != cursor || old.terrain != terrain || old.ray != ray || old.blocked != blocked;
}
