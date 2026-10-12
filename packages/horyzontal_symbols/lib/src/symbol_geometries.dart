// Ported from milsymbol src/ms/symbolgeometries.js, MIT (c) Måns Beckman.

import 'bbox.dart';
import 'js.dart';

/// Frame geometry: a draw instruction ([g], `null` for none) and its bounds.
class SymbolGeometry {
  const SymbolGeometry(this.g, this.bbox);

  /// Shared instruction, never mutated: the symbol parts copy what they need.
  final JsObject? g;
  final BBox bbox;
}

SymbolGeometry _g(JsObject g, num x1, num y1, num x2, num y2) =>
    SymbolGeometry(g, BBox(BBox.partial(x1: x1, y1: y1, x2: x2, y2: y2)));

JsObject _path(String d) => {'type': 'path', 'd': d};

const _groundUnknown =
    'M63,63 C63,20 137,20 137,63 C180,63 180,137 137,137 C137,180 63,180 63,137 C20,137 20,63 63,63 Z';

/// Frames by dimension + affiliation, plus `PositionMarker`.
final Map<String, SymbolGeometry> symbolGeometries = {
  'AirHostile': _g(_path('M 45,150 L45,70 100,20 155,70 155,150'), 45, 20, 45 + 110, 20 + 130),
  'AirFriend': _g(
    _path('M 155,150 C 155,50 115,30 100,30 85,30 45,50 45,150'),
    45,
    30,
    45 + 110,
    30 + 120,
  ),
  'AirNeutral': _g(_path('M 45,150 L 45,30,155,30,155,150'), 45, 30, 45 + 110, 30 + 120),
  'AirUnknown': _g(
    _path('M 65,150 c -55,0 -50,-90 0,-90 0,-50 70,-50 70,0 50,0 55,90 0,90'),
    25,
    20,
    25 + 150,
    20 + 130,
  ),
  'GroundHostile': _g(
    _path('M 100,28 L172,100 100,172 28,100 100,28 Z'),
    28,
    28,
    28 + 144,
    28 + 144,
  ),
  'GroundFriend': _g(_path('M25,50 l150,0 0,100 -150,0 z'), 25, 50, 25 + 150, 50 + 100),
  'GroundNeutral': _g(_path('M45,45 l110,0 0,110 -110,0 z'), 45, 45, 45 + 110, 45 + 110),
  'GroundUnknown': _g(_path(_groundUnknown), 30.75, 30.75, 30.75 + 138.5, 30.75 + 138.5),
  'LandDismountedIndividualHostile': _g(
    _path('M 100,28 L172,100 100,172 28,100 100,28 Z'),
    28,
    28,
    28 + 144,
    28 + 144,
  ),
  'LandDismountedIndividualFriend': _g(
    _path('m 100,45 55,25 0,60 -55,25 -55,-25 0,-60 z'),
    45,
    45,
    45 + 110,
    45 + 110,
  ),
  'LandDismountedIndividualNeutral': _g(
    _path('M45,45 l110,0 0,110 -110,0 z'),
    45,
    45,
    45 + 110,
    45 + 110,
  ),
  'LandDismountedIndividualUnknown': _g(
    _path(_groundUnknown),
    30.75,
    30.75,
    30.75 + 138.5,
    30.75 + 138.5,
  ),
  'SeaHostile': _g(_path('M100,28 L172,100 100,172 28,100 100,28 Z'), 28, 28, 28 + 144, 28 + 144),
  'SeaFriend': _g({'type': 'circle', 'cx': 100, 'cy': 100, 'r': 60}, 40, 40, 40 + 120, 40 + 120),
  'SeaNeutral': _g(_path('M45,45 l110,0 0,110 -110,0 z'), 45, 45, 45 + 110, 45 + 110),
  'SeaUnknown': _g(_path(_groundUnknown), 30.75, 30.75, 30.75 + 138.5, 30.75 + 138.5),
  'SubsurfaceHostile': _g(
    _path('M45,50 L45,130 100,180 155,130 155,50'),
    45,
    50,
    45 + 110,
    50 + 130,
  ),
  'SubsurfaceFriend': _g(
    _path('m 45,50 c 0,100 40,120 55,120 15,0 55,-20 55,-120'),
    45,
    50,
    45 + 110,
    50 + 120,
  ),
  'SubsurfaceNeutral': _g(_path('M45,50 L45,170 155,170 155,50'), 45, 50, 45 + 110, 50 + 120),
  'SubsurfaceUnknown': _g(
    _path('m 65,50 c -55,0 -50,90 0,90 0,50 70,50 70,0 50,0 55,-90 0,-90'),
    25,
    50,
    25 + 150,
    50 + 130,
  ),
  'PositionMarker': _g({'type': 'circle', 'cx': 100, 'cy': 100, 'r': 15}, 85, 85, 115, 115),
};
