import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';

import '../labels.dart';
import '../sensors.dart';
import '../settings.dart';

/// A parsed point: WGS 84 position plus how it was entered.
class PointValue {
  const PointValue(this.wgs, this.system, {this.zone});
  final Geodetic wgs;
  final CoordinateSystem system;

  /// Grid zone the coordinates were given in (may be a neighbouring zone).
  final int? zone;
}

/// Coordinate system picker, text field with live parsing, paste and "my
/// location" buttons. Reports null while the text does not parse.
class PointInput extends ConsumerStatefulWidget {
  const PointInput({super.key, required this.onChanged, this.label});

  final ValueChanged<PointValue?> onChanged;
  final String? label;

  @override
  ConsumerState<PointInput> createState() => _PointInputState();
}

class _PointInputState extends ConsumerState<PointInput> {
  final _text = TextEditingController();
  final _zone = TextEditingController();
  late CoordinateSystem _system = ref.read(settingsProvider).system;
  CoordinateError? _error;
  bool _locating = false;

  @override
  void dispose() {
    _text.dispose();
    _zone.dispose();
    super.dispose();
  }

  void _parse() {
    final text = _text.text;
    if (text.trim().isEmpty) {
      setState(() => _error = null);
      widget.onChanged(null);
      return;
    }
    try {
      final zone = int.tryParse(_zone.text);
      final wgs = parseCoordinates(text, _system, zone: zone);
      int? gridZone;
      if (_system.isGrid) gridZone = parseGrid(text, _system, zone: zone).zone;
      if (_system == CoordinateSystem.utm) gridZone = parseUtm(text).zone;
      setState(() => _error = null);
      widget.onChanged(PointValue(wgs, _system, zone: gridZone));
    } on CoordinateParseException catch (e) {
      setState(() => _error = e.error);
      widget.onChanged(null);
    } on RangeError {
      setState(() => _error = CoordinateError.outOfRange);
      widget.onChanged(null);
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final t = data?.text?.trim();
    if (t == null || t.isEmpty) return;
    _text.text = t;
    _parse();
  }

  Future<void> _myLocation() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _locating = true);
    try {
      final p = await currentPosition();
      if (!mounted) return;
      final geoFormat = ref.read(settingsProvider).geoFormat;
      _text.text = formatPoint(Geodetic(p.latitude, p.longitude), _system, geoFormat);
      if (_system.needsZone) _zone.text = '';
      _parse();
    } on LocationUnavailable {
      messenger.showSnackBar(SnackBar(content: Text(l.errLocation)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.errLocation)));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(widget.label!, style: Theme.of(context).textTheme.titleSmall),
          ),
        DropdownButtonFormField<CoordinateSystem>(
          initialValue: _system,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.inputSystem, border: const OutlineInputBorder()),
          items: [
            for (final s in CoordinateSystem.values)
              DropdownMenuItem(value: s, child: Text(systemName(l, s))),
          ],
          onChanged: (s) {
            if (s == null) return;
            setState(() => _system = s);
            _parse();
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _text,
          onChanged: (_) => _parse(),
          keyboardType: TextInputType.text,
          autocorrect: false,
          enableSuggestions: false,
          minLines: 1,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: l.coordinates,
            hintText: systemHint(l, _system),
            border: const OutlineInputBorder(),
            errorText: _error == null ? null : coordinateErrorText(l, _error!),
            suffixIcon: _text.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: l.clear,
                    onPressed: () {
                      _text.clear();
                      _parse();
                    },
                  ),
          ),
        ),
        if (_system.needsZone) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _zone,
            onChanged: (_) => _parse(),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l.zone,
              hintText: '7–13',
              border: const OutlineInputBorder(),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              onPressed: _paste,
              icon: const Icon(Icons.content_paste),
              label: Text(l.paste),
            ),
            TextButton.icon(
              onPressed: _locating ? null : _myLocation,
              icon: _locating
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(l.myLocation),
            ),
          ],
        ),
      ],
    );
  }
}
