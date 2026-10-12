// Ported from milsymbol src/ms/bbox.js, MIT (c) Måns Beckman.

import 'js.dart';

/// Bounding box in symbol units (the octagon spans 50..150).
///
/// Fields are nullable because milsymbol also passes partial boxes (for
/// example only `y1`) to [merge]; [BBox.new] fills the missing sides with 100.
class BBox {
  /// A full box, missing sides of [box] default to 100.
  BBox([BBox? box])
    : x1 = box?.x1 ?? 100,
      y1 = box?.y1 ?? 100,
      x2 = box?.x2 ?? 100,
      y2 = box?.y2 ?? 100;

  /// A box with only the given sides, like the JS literals `{y1: ...}`.
  BBox.partial({this.x1, this.y1, this.x2, this.y2});

  /// A full box from a JS-style literal such as the special bounding boxes
  /// of the SIDC tables.
  factory BBox.fromJs(Object? o) {
    final m = o is Map<String, Object?> ? o : const <String, Object?>{};
    return BBox(BBox.partial(x1: _n(m['x1']), y1: _n(m['y1']), x2: _n(m['x2']), y2: _n(m['y2'])));
  }

  num? x1, y1, x2, y2;

  static num? _n(Object? v) => v == null ? null : (v is num ? v : toNumber(v));

  num width() => x2! - x1!;
  num height() => y2! - y1!;

  /// Grows this box to include [box]; missing sides of [box] are ignored.
  BBox merge(BBox box) {
    final bx1 = box.x1, by1 = box.y1, bx2 = box.x2, by2 = box.y2;
    if (bx1 != null && bx1 <= x1!) x1 = bx1;
    if (by1 != null && by1 <= y1!) y1 = by1;
    if (bx2 != null && bx2 >= x2!) x2 = bx2;
    if (by2 != null && by2 >= y2!) y2 = by2;
    return this;
  }

  Map<String, Object?> toJson() => {'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2};

  @override
  String toString() => 'BBox($x1, $y1, $x2, $y2)';
}
