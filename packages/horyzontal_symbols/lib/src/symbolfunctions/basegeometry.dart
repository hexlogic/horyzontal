// Ported from milsymbol src/symbolfunctions/basegeometry.js, MIT (c) Måns Beckman.

import '../js.dart';
import '../ms.dart';
import '../symbol.dart';
import 'common.dart';
import 'frame_modifiers.dart';

/// Copy of the frame geometry (only the shape keys, like milsymbol).
JsObject cloneBaseGeometry(MilSymbol s) {
  final g = s.metadata.baseGeometry.g!;
  final geom = <String, Object?>{'type': g['type']};
  switch (geom['type']) {
    case 'path':
      geom['d'] = g['d'];
    case 'circle':
      geom['cx'] = g['cx'];
      geom['cy'] = g['cy'];
      geom['r'] = g['r'];
  }
  return geom;
}

/// The frame and the frame shape modifiers, plus the outline under them.
/// Returns `null` when nothing should be drawn (milsymbol's early return).
(JsArray, JsArray)? frameParts(MilSymbol s, Ms ms) {
  final style = s.options;
  final metadata = s.metadata;
  final drawArray1 = <Object?>[];
  final drawArray2 = <Object?>[];
  final frameColor = s.colors.frameColor[metadata.affiliation];
  final g = metadata.baseGeometry.g;

  //Clone the base geometry
  var geom = cloneBaseGeometry(s);
  geom['fill'] = truthy(style.fillColor)
      ? style.fillColor
      : s.colors.fillColor[metadata.affiliation];
  geom['fillopacity'] = style.fillOpacity;
  geom['stroke'] = frameColor;
  geom['strokewidth'] = style.size >= 10 ? style.strokeWidth : 10;
  //outline
  if (style.frame && style.outlineWidth > 0) {
    JsObject outline;
    if (geom['type'] == 'path' && metadata.fill && !truthy(style.monoColor)) {
      outline = {'type': g!['type']};
      outline['d'] = '${jsString(g['d'])} Z'; //Making sure the path is closed
      outline['strokewidth'] = style.size >= 10 ? style.strokeWidth : 10;
    } else {
      outline = geom;
    }
    drawArray1.add(msOutline(outline, style.outlineWidth, style.strokeWidth, outlineColorOf(s)));
  }
  //Add a dashed outline to the frame if we are using monocolor and the status is not present.
  if ((style.monoColor != '' || !style.fill) && truthy(metadata.notpresent)) {
    geom['strokedasharray'] = metadata.notpresent;
  }
  drawArray2.add(geom);

  // Space Modifiers
  if (metadata.space) {
    drawArray2.add(byAffiliation(spaceModifier(frameColor), metadata.affiliation));
  }
  // Modifiers for activity.
  if (metadata.activity) {
    drawArray2.add(byAffiliation(activityModifier(frameColor), metadata.affiliation));
  }
  // Cyberspace Modifiers
  if (metadata.cyberspace) {
    drawArray2.add(byAffiliation(cyberspaceModifier(frameColor), metadata.affiliation));
  }
  //Add a dashed outline to the frame if the status is not present.
  if (style.fill && style.frame && truthy(metadata.notpresent) && !metadata.unframed) {
    //Clone the base geometry
    geom = cloneBaseGeometry(s);
    geom['fill'] = false;
    geom['stroke'] = s.colors.white[metadata.affiliation];
    geom['strokewidth'] = parseFloat(style.strokeWidth) + 1;
    geom['strokedasharray'] = metadata.notpresent;
    drawArray2.add(geom);
  }
  return (drawArray1, drawArray2);
}

/// Base geometry (the frame) of the symbol.
SymbolPartResult basegeometry(MilSymbol s, Ms ms) {
  final metadata = s.metadata;
  //If unframed but with icon, then just return.
  if ((!metadata.frame && s.options.icon) || metadata.baseGeometry.g?['type'] == null) {
    return SymbolPartResult([], [], metadata.baseGeometry.bbox);
  }
  final (pre, post) = frameParts(s, ms)!;
  return SymbolPartResult(pre, post, metadata.baseGeometry.bbox);
}
