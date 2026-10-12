import 'package:flutter/material.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

import '../labels.dart';

/// Angle field with its own input format picker. Reports degrees, or null
/// while the text does not parse.
class AngleInput extends StatefulWidget {
  const AngleInput({
    super.key,
    required this.label,
    required this.format,
    required this.onFormatChanged,
    required this.onChanged,
  });

  final String label;
  final AngleFormat format;
  final ValueChanged<AngleFormat> onFormatChanged;
  final ValueChanged<double?> onChanged;

  @override
  State<AngleInput> createState() => _AngleInputState();
}

class _AngleInputState extends State<AngleInput> {
  final _text = TextEditingController();
  bool _error = false;

  @override
  void didUpdateWidget(AngleInput old) {
    super.didUpdateWidget(old);
    if (old.format != widget.format) _parse();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _parse() {
    if (_text.text.trim().isEmpty) {
      setState(() => _error = false);
      widget.onChanged(null);
      return;
    }
    try {
      final d = parseAngle(_text.text, widget.format);
      setState(() => _error = false);
      widget.onChanged(d);
    } on FormatException {
      setState(() => _error = true);
      widget.onChanged(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: _text,
            onChanged: (_) => _parse(),
            keyboardType: widget.format.isMils
                ? const TextInputType.numberWithOptions(signed: true)
                : TextInputType.text,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: formatAngle(93, widget.format),
              border: const OutlineInputBorder(),
              errorText: _error ? l.errAngle : null,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<AngleFormat>(
            initialValue: widget.format,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l.inputFormat,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final f in AngleFormat.values)
                DropdownMenuItem(
                  value: f,
                  child: Text(_short(f), overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (f) {
              if (f != null) widget.onFormatChanged(f);
            },
          ),
        ),
      ],
    );
  }

  static String _short(AngleFormat f) => switch (f) {
    AngleFormat.deg360 => '360°',
    AngleFormat.mils6000 => '60-00',
    AngleFormat.mils6400 => '64-00',
    AngleFormat.dms => 'Г°М′С″',
  };
}
