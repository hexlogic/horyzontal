// Ported from milsymbol src/symbolfunctions/debug.js, MIT (c) Måns Beckman.

import '../bbox.dart';
import '../ms.dart';
import '../symbol.dart';

/// Draws the icon octagon, for debugging (`ms.showOctagon()`).
SymbolPartResult debug(MilSymbol symbol, Ms ms) {
  final drawArray1 = <Object?>[];
  final drawArray2 = <Object?>[];
  final gbbox = BBox();
  drawArray2.add(<String, Object?>{
    'type': 'path',
    'fill': false,
    'stroke': 'rgb(0,0,255)',
    'strokewidth': 1,
    'd': 'm 120,60 0,80 m -40,-80 0,80 m -20,-20 80,0 m 0,-40 -80,0 M 100,50 135.35534,64.64466 150,100 135.35534,135.35534 100,150.00002 64.644661,135.35534 50,100 64.644661,64.64466 z',
  });
  return SymbolPartResult(drawArray1, drawArray2, gbbox);
}
