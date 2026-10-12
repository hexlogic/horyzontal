import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

/// Compass card: ticks every 5°, labels at every major step of the chosen
/// angle format, cardinal letters. Drawn north-up; the page rotates it.
class CompassRosePainter extends CustomPainter {
  CompassRosePainter({required this.format, required this.colors, required this.cardinals});

  final AngleFormat format;
  final ColorScheme colors;

  /// N, E, S, W labels.
  final List<String> cardinals;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final ring = Paint()
      ..color = colors.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(c, r - 1, ring);

    final tick = Paint()..color = colors.onSurfaceVariant;
    for (var d = 0; d < 360; d += 5) {
      final major = d % 30 == 0;
      tick.strokeWidth = major ? 2.5 : 1;
      final len = major ? r * 0.09 : r * 0.05;
      final a = d * math.pi / 180;
      final dir = Offset(math.sin(a), -math.cos(a));
      canvas.drawLine(c + dir * (r - 4), c + dir * (r - 4 - len), tick);
    }

    // Numeric labels.
    final (step, units) = switch (format) {
      AngleFormat.mils6000 => (30.0, (double d) => '${(d / 6).round() ~/ 10}'),
      AngleFormat.mils6400 => (45.0, (double d) => '${(d * 6400 / 360).round() ~/ 100}'),
      _ => (30.0, (double d) => d.round().toString()),
    };
    for (var d = 0.0; d < 360; d += step) {
      if (d % 90 == 0) continue;
      _label(canvas, c, r * 0.72, d, units(d), colors.onSurfaceVariant, r * 0.075, FontWeight.w500);
    }
    for (var i = 0; i < 4; i++) {
      _label(
        canvas,
        c,
        r * 0.72,
        i * 90.0,
        cardinals[i],
        i == 0 ? colors.error : colors.onSurface,
        r * 0.12,
        FontWeight.w700,
      );
    }
  }

  void _label(
    Canvas canvas,
    Offset c,
    double radius,
    double deg,
    String text,
    Color color,
    double fontSize,
    FontWeight weight,
  ) {
    final a = deg * math.pi / 180;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final pos = c + Offset(math.sin(a), -math.cos(a)) * radius;
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(a);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(CompassRosePainter old) =>
      old.format != format || old.colors != colors || old.cardinals != cardinals;
}
