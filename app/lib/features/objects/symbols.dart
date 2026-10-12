/// APP-6 rendering entry point. Wired to package:horyzontal_symbols once the
/// milsymbol port lands; until then no symbol is drawn and points fall back
/// to coloured dots.
String? symbolSvg(String sidc, {double size = 30}) => null;

/// Whether [sidc] draws as a single point symbol (control measure lines and
/// areas do not).
bool isPointSymbol(String sidc) => true;
