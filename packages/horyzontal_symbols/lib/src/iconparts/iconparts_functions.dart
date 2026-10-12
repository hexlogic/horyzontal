// Ported from milsymbol src/iconparts/iconparts-functions.js, MIT (c) Måns Beckman.

import '../js.dart';

/// Sets the default fill/stroke/stroke width of icon instructions (only
/// the top level of each instruction, not inside `draw`, as in milsymbol).
void defaultProperties(Object? instructions, Object? iconColor) {
  if (instructions is List<Object?>) {
    for (final i in instructions) {
      defaultProperties(i, iconColor);
    }
    return;
  }
  if (instructions is! Map<String, Object?>) return;
  instructions['icon'] = true;
  if (instructions['type'] == 'text') {
    if (!instructions.containsKey('fontfamily')) instructions['fontfamily'] = 'Arial';
    if (!instructions.containsKey('fontweight')) instructions['fontweight'] = 'bold';
    if (!instructions.containsKey('textanchor')) instructions['textanchor'] = 'middle';
    if (!instructions.containsKey('stroke')) instructions['stroke'] = false;
  }
  if (!instructions.containsKey('fill')) instructions['fill'] = iconColor;
  if (!instructions.containsKey('stroke')) instructions['stroke'] = iconColor;
  if (!instructions.containsKey('strokewidth')) instructions['strokewidth'] = 3;
}

/// The loop that ends every milsymbol icon-parts file: applies
/// [defaultProperties] and copies [icn] into [iconParts] (later files
/// override earlier keys).
void registerIconParts(JsObject iconParts, JsObject icn, Object? iconColor) {
  for (final e in icn.entries) {
    defaultProperties(e.value, iconColor);
    iconParts[e.key] = e.value;
  }
}

/// Text icon in the middle of the frame.
JsObject text(String str) {
  num size = 45;
  if (str.length == 1) size = 45;
  if (str.length == 3) size = 39;
  if (str.length >= 4) size = 33;
  return {
    'type': 'text',
    'stroke': false,
    'textanchor': 'middle',
    'alignmentBaseline': 'middle',
    'x': 100,
    'y': 103,
    'fontsize': size,
    'text': str,
  };
}

/// Text sector 1 modifier (top of the frame).
JsObject textm1(String str) {
  num size = 28;
  if (str.length == 3) size = 25;
  if (str.length >= 4) size = 22;
  return {
    'type': 'text',
    'stroke': false,
    'textanchor': 'middle',
    'alignmentBaseline': 'middle',
    'x': 100,
    'y': 71,
    'fontsize': size,
    'text': str,
  };
}

/// Text sector 2 modifier (bottom of the frame).
JsObject textm2(String str) {
  num size = 28;
  if (str.length == 3) size = 25;
  if (str.length >= 4) size = 20;
  return {
    'type': 'text',
    'stroke': false,
    'textanchor': 'middle',
    'alignmentBaseline': 'middle',
    'x': 100,
    'y': 134,
    'fontsize': size,
    'text': str,
  };
}
