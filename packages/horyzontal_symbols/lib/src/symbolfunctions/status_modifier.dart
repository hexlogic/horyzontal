// Ported from milsymbol src/symbolfunctions/statusmodifier.js, MIT (c) Måns Beckman.

import '../bbox.dart';
import '../js.dart';
import '../ms.dart';
import '../symbol.dart';
import 'common.dart';

const _conditionColors = {
  'FullyCapable': 'rgb(0,255,0)',
  'Damaged': 'rgb(255,255,0)',
  'Destroyed': 'rgb(255,0,0)',
  'FullToCapacity': 'rgb(0, 180, 240)',
};

/// Condition bar or damaged/destroyed slashes.
SymbolPartResult statusmodifier(MilSymbol s, Ms ms) {
  final style = s.options;
  final metadata = s.metadata;
  final drawArray1 = <Object?>[];
  final drawArray2 = <Object?>[];
  final bbox = metadata.baseGeometry.bbox;
  var y1 = bbox.y1!;
  var y2 = bbox.y2!;

  if (truthy(metadata.condition)) {
    if (metadata.fill && style.monoColor == '' && !style.simpleStatusModifier) {
      //If it is unframed and equipment use the bottom of the icon
      if (!metadata.frame && truthy(metadata.iconBottom)) {
        y2 = metadata.iconBottom!;
      }
      // If we have headquartersElement add space for the text
      if (truthy(style.headquartersElement)) {
        y2 += 35;
      }
      //If we have a mobility indicator we need to make space for it.
      y2 += truthy(metadata.mobility) ? 25 : 5;
      //Add the bar to the geometry
      drawArray2.add(<String, Object?>{
        'type': 'path',
        'strokewidth': style.strokeWidth,
        'fill': _conditionColors[metadata.condition],
        'stroke': s.colors.frameColor[metadata.affiliation],
        'd':
            'M${jsNumber(bbox.x1!)},${jsNumber(y2)} l${jsNumber(bbox.width())},0 0,25 '
            '-${jsNumber(bbox.width())},0 z',
      });
      //Add the hight of the codition bar to the geometry bounds
      y2 += 25;
      //outline
      if (style.outlineWidth > 0) {
        drawArray1.add(
          msOutline(drawArray2, style.outlineWidth, style.strokeWidth, outlineColorOf(s)),
        );
      }
    } else {
      if (metadata.condition == 'Damaged' || metadata.condition == 'Destroyed') {
        drawArray2.add(<String, Object?>{
          'type': 'path',
          'd': 'M150,20 L50,180',
          'strokewidth': style.strokeWidth * 2,
          'stroke': s.colors.frameColor[metadata.affiliation],
        });
        //Add space for the modifier to the geometry bounds
        y1 = 20;
        y2 = 180;
      }
      if (metadata.condition == 'Destroyed') {
        drawArray2.add(<String, Object?>{
          'type': 'path',
          'd': 'M50,20 L150,180',
          'strokewidth': style.strokeWidth * 2,
          'stroke': s.colors.frameColor[metadata.affiliation],
        });
      }
      //outline
      if (style.outlineWidth > 0) {
        drawArray1.add(
          msOutline(drawArray2, style.outlineWidth, style.strokeWidth, outlineColorOf(s)),
        );
      }
    }
  }

  //A bounding box only needs the values that might change
  return SymbolPartResult(drawArray1, drawArray2, BBox.partial(y1: y1, y2: y2));
}
