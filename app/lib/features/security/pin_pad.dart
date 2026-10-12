import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/labels.dart';
import 'pin_store.dart';

/// PIN entry: title, dots, message, numeric keypad. Calls [onComplete] once
/// six digits are in; the caller clears the pad through [PinPadState.clear].
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.title,
    required this.onComplete,
    this.message,
    this.messageIsError = false,
    this.enabled = true,
    this.onBiometric,
  });

  final String title;
  final String? message;
  final bool messageIsError, enabled;
  final ValueChanged<String> onComplete;
  final VoidCallback? onBiometric;

  @override
  State<PinPad> createState() => PinPadState();
}

class PinPadState extends State<PinPad> {
  String _pin = '';

  void clear() => setState(() => _pin = '');

  void _digit(String d) {
    if (!widget.enabled || _pin.length >= PinStore.length) return;
    HapticFeedback.selectionClick();
    setState(() => _pin += d);
    if (_pin.length == PinStore.length) widget.onComplete(_pin);
  }

  void _delete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    Widget key(Widget child, VoidCallback? onTap, {String? semantics}) => Semantics(
      button: true,
      label: semantics,
      child: SizedBox.square(
        dimension: 76,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
    Widget digit(String d) =>
        key(Text(d, style: theme.textTheme.headlineMedium), () => _digit(d), semantics: d);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < PinStore.length; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _pin.length ? colors.primary : null,
                  border: Border.all(color: colors.outline, width: 1.5),
                ),
              ),
          ],
        ),
        SizedBox(
          height: 48,
          child: Center(
            child: Text(
              widget.message ?? '',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: widget.messageIsError ? colors.error : null,
              ),
            ),
          ),
        ),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(mainAxisSize: MainAxisSize.min, children: [for (final d in row) digit(d)]),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.onBiometric == null
                ? const SizedBox.square(dimension: 76)
                : key(
                    const Icon(Icons.fingerprint, size: 32),
                    widget.onBiometric,
                    semantics: context.l10n.unlockBiometric,
                  ),
            digit('0'),
            key(const Icon(Icons.backspace_outlined), _delete, semantics: context.l10n.deleteDigit),
          ],
        ),
      ],
    );
  }
}
