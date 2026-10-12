// Ported from milsymbol src/symbolfunctions/affliationdimension.js, MIT (c) Måns Beckman.

import '../bbox.dart';
import '../js.dart';
import '../ms.dart';
import '../symbol.dart';
import 'common.dart';

JsObject _letter(String text, num x, num y, Object? fill, String fontFamily) => {
  'type': 'text',
  'text': text,
  'x': x,
  'y': y,
  'fill': fill,
  'fontfamily': fontFamily,
  'fontsize': 35,
  'fontweight': 'bold',
  'textanchor': 'start',
  'alignmentBaseline': 'middle',
};

/// Question mark of unknown dimension and the exercise/simulation letters.
SymbolPartResult affliationdimension(MilSymbol s, Ms ms) {
  final style = s.options;
  final metadata = s.metadata;
  final drawArray1 = <Object?>[];
  final drawArray2 = <Object?>[];
  var bbox = metadata.baseGeometry.bbox;
  final frameColor = s.colors.frameColor[metadata.affiliation];
  //Draws the a question mark for some unknown or other dimension symbols
  if (metadata.dimensionUnknown && truthy(frameColor)) {
    drawArray2.add(<String, Object?>{
      'type': 'text',
      'text': '?',
      'x': 100,
      'y': 127,
      'fill': frameColor,
      'fontfamily': style.fontfamily,
      'fontsize': 80,
      'fontweight': 'bold',
      'textanchor': 'middle',
    });
  }
  //If we don't have a geometry we shouldn't add anything.
  if (metadata.baseGeometry.g != null && truthy(frameColor)) {
    num spacing = 10;
    if (metadata.affiliation == 'Unknown' ||
        (metadata.affiliation == 'Hostile' && metadata.dimension != 'Subsurface')) {
      spacing = -10;
    }
    if (metadata.context == 'Exercise') {
      if (!(metadata.joker || metadata.faker)) {
        drawArray2.add(_letter('X', bbox.x2! + spacing, 50, frameColor, style.fontfamily));
      }
      if (metadata.joker) {
        drawArray2.add(_letter('J', bbox.x2! + spacing, 40, frameColor, style.fontfamily));
      }
      if (metadata.faker) {
        drawArray2.add(_letter('K', bbox.x2! + spacing, 40, frameColor, style.fontfamily));
      }
      bbox = BBox.partial(x2: bbox.x2! + spacing + 22, y1: 40 - 25);
    }
    if (metadata.context == 'Simulation') {
      drawArray2.add(_letter('S', bbox.x2! + spacing, 40, frameColor, style.fontfamily));
      bbox = BBox(BBox.partial(x2: bbox.x2! + spacing + 22, y1: 40 - 25));
    }
  }
  //outline
  if (style.outlineWidth > 0) {
    drawArray1.add(msOutline(drawArray2, style.outlineWidth, style.strokeWidth, outlineColorOf(s)));
  }
  return SymbolPartResult(drawArray1, drawArray2, bbox);
}
