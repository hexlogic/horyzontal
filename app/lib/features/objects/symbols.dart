import 'package:horyzontal_symbols/horyzontal_symbols.dart';

var _standardSet = false;

MilSymbol? _symbol(String sidc, double size) {
  if (!_standardSet) {
    MilSymbol.setStandard('APP6');
    _standardSet = true;
  }
  try {
    return MilSymbol(sidc, SymbolOptions(size: size));
  } catch (_) {
    return null;
  }
}

/// APP-6 symbol as SVG (milsymbol port), or null when the code does not
/// render. [size] is milsymbol's size: roughly the frame height in pixels.
String? symbolSvg(String sidc, {double size = 30}) {
  final s = _symbol(sidc, size);
  return s == null || !s.isValid ? null : s.asSvg();
}

/// Whether [sidc] draws as a single point symbol (control measure lines and
/// areas do not).
bool isPointSymbol(String sidc) => _symbol(sidc, 30)?.isValid ?? false;

/// Shift that puts the symbol's anchor (frame centre, or the foot of a
/// headquarters staff) on the map point: image centre minus anchor, in the
/// image's pixels at [size].
(double, double) symbolAnchorOffset(String sidc, {double size = 30}) {
  final s = _symbol(sidc, size);
  if (s == null) return (0, 0);
  return (s.size.width / 2 - s.anchor.x, s.size.height / 2 - s.anchor.y);
}
