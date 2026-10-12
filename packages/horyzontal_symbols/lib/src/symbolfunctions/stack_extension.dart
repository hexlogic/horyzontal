// Ported from milsymbol src/symbolfunctions/stack-extension.js, MIT (c) Måns Beckman.

import '../bbox.dart';
import '../ms.dart';
import '../symbol.dart';
import 'basegeometry.dart';

/// Stacked copies of the frame behind the symbol (`stack` option).
SymbolPartResult stack(MilSymbol s, Ms ms) {
  final metadata = s.metadata;
  final count = s.options.stack;
  //If unframed but with icon, then just return.
  if ((!metadata.frame && s.options.icon) ||
      metadata.baseGeometry.g?['type'] == null ||
      count == null) {
    return SymbolPartResult([], [], metadata.baseGeometry.bbox);
  }
  final (drawArray1, drawArray2) = frameParts(s, ms)!;
  final stackOutline = <Object?>[];
  final stack = <Object?>[];
  for (num i = count; i >= 1; i--) {
    stackOutline.add(<String, Object?>{
      'type': 'translate',
      'x': 15 * i,
      'y': 9 * i,
      'draw': drawArray1,
    });
    stack.add(<String, Object?>{'type': 'translate', 'x': 15 * i, 'y': 9 * i, 'draw': drawArray2});
  }
  final bbox = BBox(metadata.baseGeometry.bbox);
  bbox.x2 = bbox.x2! + 15 * count;
  bbox.y2 = bbox.y2! + 10 * count;

  return SymbolPartResult([stackOutline], [stack], bbox);
}
