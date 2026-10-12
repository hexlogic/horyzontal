// Ported from milsymbol src/symbolfunctions/basegeometry.js and
// stack-extension.js (their identical frame modifier tables), MIT (c) Måns Beckman.

import '../js.dart';

JsObject _p(Object? fill, String d) => {'type': 'path', 'stroke': false, 'fill': fill, 'd': d};

/// Space modifier on top of the frame.
Map<String, JsObject> spaceModifier(Object? frameColor) => {
  'Friend': _p(frameColor, 'M 100,30 C 90,30 80,35 68.65625,50 l 62.6875,0 C 120,35 110,30 100,30'),
  'Hostile': _p(frameColor, 'M67,50 L100,20 133,50 z'),
  'Neutral': _p(frameColor, 'M45,50 l0,-20 110,0 0,20 z'),
  'Unknown': _p(
    frameColor,
    'M 100 22.5 C 85 22.5 70 31.669211 66 50 L 134 50 C 130 31.669204 115 22.5 100 22.5 z',
  ),
};

/// Corner marks of activities.
Map<String, JsObject> activityModifier(Object? frameColor) => {
  'Friend': _p(
    frameColor,
    'm 160,135 0,15 15,0 0,-15 z m -135,0 15,0 0,15 -15,0 z m 135,-85 0,15 15,0 0,-15 z m -135,0 15,0 0,15 -15,0 z',
  ),
  'Hostile': _p(
    frameColor,
    'M 100 28 L 89.40625 38.59375 L 100 49.21875 L 110.59375 38.59375 L 100 28 z M 38.6875 89.3125 L 28.0625 99.9375 L 38.6875 110.53125 L 49.28125 99.9375 L 38.6875 89.3125 z M 161.40625 89.40625 L 150.78125 100 L 161.40625 110.59375 L 172 100 L 161.40625 89.40625 z M 99.9375 150.71875 L 89.3125 161.3125 L 99.9375 171.9375 L 110.53125 161.3125 L 99.9375 150.71875',
  ),
  'Neutral': _p(
    frameColor,
    'm 140,140 15,0 0,15 -15,0 z m -80,0 0,15 -15,0 0,-15 z m 80,-80 0,-15 15,0 0,15 z m -80,0 -15,0 0,-15 15,0 z',
  ),
  'Unknown': _p(
    frameColor,
    'M 107.96875 31.46875 L 92.03125 31.71875 L 92.03125 46.4375 L 107.71875 46.4375 L 107.96875 31.46875 z M 47.03125 92.5 L 31.09375 92.75 L 31.09375 107.5 L 46.78125 107.5 L 47.03125 92.5 z M 168.4375 92.5 L 152.5 92.75 L 152.5 107.5 L 168.1875 107.5 L 168.4375 92.5 z M 107.96875 153.5625 L 92.03125 153.8125 L 92.03125 168.53125 L 107.71875 168.53125 L 107.96875 153.5625 z',
  ),
};

/// Cyberspace mark.
Map<String, JsObject> cyberspaceModifier(Object? frameColor) => {
  'Friend': _p(frameColor, 'm 135,150 40,-40 0,40 z'),
  'Hostile': _p(frameColor, 'm 150,78 0,44 22,-22 z'),
  'Neutral': _p(frameColor, 'm 115,155 40,-40 0,40 z'),
  'Unknown': _p(frameColor, 'M 150 65.7 L 150 134 C 176 123 176 77.2 150 65.7 z'),
};
