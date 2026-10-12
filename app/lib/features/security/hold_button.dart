import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A button that fires only after being held for [duration], with a fill
/// showing progress. Used for the emergency wipe, so a stray tap does
/// nothing.
class HoldButton extends StatefulWidget {
  const HoldButton({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.duration = const Duration(seconds: 3),
  });

  final String label;
  final VoidCallback onConfirmed;
  final Duration duration;

  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.duration)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        widget.onConfirmed();
      }
    });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTapDown: (_) => _c.forward(from: 0),
      onTapUp: (_) => _c.isCompleted ? null : _c.reverse(),
      onTapCancel: () => _c.isCompleted ? null : _c.reverse(),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colors.error, width: 2),
            gradient: LinearGradient(
              colors: [colors.error, colors.error, colors.errorContainer, colors.errorContainer],
              stops: [0, _c.value, _c.value, 1],
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              color: _c.value > 0.5 ? colors.onError : colors.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
