// Ported from milsymbol src/symbolfunctions/engagmentbar.js, MIT (c) Måns Beckman.

import '../bbox.dart';
import '../js.dart';
import '../ms.dart';
import '../symbol.dart';
import 'common.dart';

const _engagementColors = {
  'TARGET': 'rgb(255, 0, 0)',
  'NON-TARGET': 'rgb(255, 255, 255)',
  'EXPIRED': 'rgb(255, 120, 0)',
};

/// Engagement bar (field AO) above the symbol.
SymbolPartResult engagementbar(MilSymbol s, Ms ms) {
  final style = s.options;
  final metadata = s.metadata;
  final drawArray1 = <Object?>[];
  final drawArray2 = <Object?>[];
  final bbox = s.bbox;
  var x1 = bbox.x1!;
  var x2 = bbox.x2!;
  var y1 = bbox.y1!;
  final y2 = bbox.y2!;

  if (style.engagementBar != '') {
    y1 -= 6;
    final fontFamily = style.fontfamily;
    final fontColor = truthy(s.colors.iconColor[metadata.affiliation])
        ? s.colors.iconColor[metadata.affiliation]
        : s.colors.iconColor['Friend'];

    drawArray2.add(<String, Object?>{
      'type': 'text',
      'text': style.engagementBar,
      'x': 100,
      'y': bbox.y1! - 11,
      'textanchor': 'middle',
      'fontsize': 22,
      'fontfamily': fontFamily,
      'fontweight': 'bold',
      'fill': fontColor,
      'stroke': false,
    });

    Object? color = false;
    if (metadata.fill && style.monoColor == '') {
      final c = _engagementColors[style.engagementType.toUpperCase()];
      color = c ?? s.colors.fillColor[metadata.affiliation];
    }
    // Bar width
    final width = _max(bbox.width(), style.engagementBar.length * 16);
    x1 = _min(x1, 100 - width / 2);
    x2 = _max(x2, 100 + width / 2);

    //Add the bar to the geometry
    drawArray2.insert(0, <String, Object?>{
      'type': 'path',
      'strokewidth': style.strokeWidth,
      'fill': color,
      'stroke': s.colors.frameColor[metadata.affiliation],
      'd':
          'M${jsNumber(100 - width / 2)},${jsNumber(y1)} l${jsNumber(width)},0 0,-25 '
          '-${jsNumber(width)},0 z',
    });

    //Add the hight of the codition bar to the geometry bounds
    y1 -= 25;
    //outline
    if (style.outlineWidth > 0) {
      final Object? outline = metadata.fill && style.monoColor == '' ? drawArray2[0] : drawArray2;
      drawArray1.add(msOutline(outline, style.outlineWidth, style.strokeWidth, outlineColorOf(s)));
    }
  }

  //A bounding box only needs the values that might change
  return SymbolPartResult(drawArray1, drawArray2, BBox.partial(x1: x1, x2: x2, y1: y1, y2: y2));
}

num _min(num a, num b) => a.isNaN || b.isNaN ? double.nan : (a <= b ? a : b);
num _max(num a, num b) => a.isNaN || b.isNaN ? double.nan : (a >= b ? a : b);
