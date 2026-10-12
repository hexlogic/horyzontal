// Ported from milsymbol src/ms/symbol.js, src/ms/symbol/setoptions.js,
// getsize.js and isvalid.js, MIT (c) Måns Beckman.

import 'assvg.dart';
import 'bbox.dart';
import 'color_mode.dart';
import 'colors.dart';
import 'js.dart';
import 'metadata.dart';
import 'ms.dart';
import 'options.dart';

/// Width and height in pixels.
class SymbolSize {
  const SymbolSize(this.width, this.height);
  final num width, height;

  @override
  bool operator ==(Object other) =>
      other is SymbolSize && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'SymbolSize($width, $height)';
}

/// A point in pixels from the top left corner of the SVG.
class SymbolPoint {
  const SymbolPoint(this.x, this.y);
  final num x, y;

  @override
  bool operator ==(Object other) => other is SymbolPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'SymbolPoint($x, $y)';
}

/// Detailed validity, `isValid(true)` in milsymbol.
class SymbolValidity {
  const SymbolValidity({
    required this.affiliation,
    required this.dimension,
    required this.dimensionUnknown,
    required this.drawInstructions,
    required this.icon,
    required this.mobility,
  });
  final String? affiliation;
  final String dimension;
  final bool dimensionUnknown;

  /// No missing parts in the draw instructions.
  final bool drawInstructions;

  /// The icon code was found.
  final bool icon;

  /// The echelon/mobility code was valid.
  final bool mobility;
}

/// A military symbol (APP-6 / MIL-STD-2525) from a number SIDC, the Dart
/// counterpart of milsymbol's `new ms.Symbol(sidc, options)`.
///
/// ```dart
/// final s = MilSymbol('10031000001211000000', const SymbolOptions(size: 35));
/// final svg = s.asSvg();
/// ```
class MilSymbol {
  /// Builds the symbol. [sidc] spaces are removed and `*` become `-`.
  MilSymbol(this.sidc, [SymbolOptions? options]) : options = options ?? const SymbolOptions() {
    _build();
  }

  /// milsymbol version this port follows.
  static const version = Ms.version;

  /// Default standard for symbols without [SymbolOptions.standard]:
  /// `2525` (default) or `APP6`. Returns false for other values.
  static bool setStandard(String standard) => ms.setStandard(standard);

  /// Default length of the headquarters staff in symbol units (100).
  static void setHqStaffLength(num length) => ms.hqStaffLength = length;

  /// Dash arrays of pending, anticipated (planned) and feint/dummy frames.
  static void setDashArrays(String pending, String anticipated, String feintDummy) {
    ms.dashArrays = DashArrays(pending, anticipated, feintDummy);
  }

  /// Registers or replaces a named color mode usable as [SymbolOptions.colorMode].
  static ColorMode setColorMode(String name, ColorMode mode) => ms.setColorMode(name, mode);

  /// A copy of a registered color mode (`Light`, `Medium`, `Dark`, `FrameColor`, ...).
  static ColorMode getColorMode(String name) => ms.getColorMode(name);

  /// Draws the icon octagon on every following symbol, for debugging.
  static void showOctagon() => ms.showOctagon();

  /// Restores milsymbol's defaults (standard, colors, dash arrays, modules).
  static void reset() => ms
    ..reset()
    ..registerDefaults();

  /// The normalized SIDC.
  String sidc;

  final SymbolOptions options;

  /// Parsed SIDC information.
  late final SymbolMetadata metadata;

  /// Colors by affiliation used for this symbol.
  late final SymbolColors colors;

  /// Bounds of the drawing in symbol units (octagon 50..150).
  BBox bbox = BBox();

  /// The drawing as milsymbol draw instructions (maps and lists).
  JsArray drawInstructions = [];

  /// Whether the icon (and modifier) codes were found.
  bool validIcon = true;

  late final num baseWidth, baseHeight;
  late final num width, height;

  /// Insertion point of the symbol (center of the frame, or foot of the
  /// headquarters staff), in pixels.
  late final SymbolPoint anchor;

  /// Center of the octagon, in pixels.
  late final SymbolPoint octagonAnchor;

  SymbolSize get size => SymbolSize(width, height);

  /// The symbol as an SVG document string.
  String asSvg() => asSVG(this);

  /// `data:` URL of the SVG.
  String toDataUrl() => 'data:image/svg+xml;utf8,${Uri.encodeComponent(asSvg())}';

  /// Whether milsymbol considers the SIDC valid.
  bool get isValid {
    final v = validity();
    return !(metadata.affiliation == 'undefined' ||
            (metadata.dimension == 'undefined' && !metadata.controlMeasure)) &&
        v.drawInstructions &&
        validIcon &&
        v.mobility;
  }

  SymbolValidity validity() => SymbolValidity(
    affiliation: metadata.affiliation,
    dimension: metadata.dimension,
    dimensionUnknown: metadata.dimensionUnknown,
    drawInstructions: !jsonContainsNull(drawInstructions),
    icon: validIcon,
    mobility: metadata.mobility != null,
  );

  void _build() {
    final style = options;
    metadata = getMetadata(this);
    colors = getColors(this);
    drawInstructions = [];
    bbox = BBox();

    //Processing all parts of the symbol, adding them to the drawinstruction and updating the boundingbox
    for (final part in ms.symbolParts) {
      final m = part(this, ms);
      final notEmpty = m.pre.isNotEmpty || m.post.isNotEmpty;
      Object? pre = m.pre;
      Object? post = m.post;
      if (m.pre.isNotEmpty) {
        while (jsLength(pre) == 1) {
          pre = (pre as List<Object?>)[0];
          if (pre == null) {
            throw JsTypeError("Cannot read properties of undefined (reading 'length')");
          }
        }
        if (jsLength(pre) != 0) {
          drawInstructions = concat([pre, drawInstructions]);
        }
      }
      if (m.post.isNotEmpty) {
        while (jsLength(post) == 1) {
          post = (post as List<Object?>)[0];
          if (post == null) break;
        }
        if (post == null || jsLength(post) != 0) {
          drawInstructions = concat([drawInstructions, post]);
        }
      }
      if (m.bbox != null && notEmpty) {
        bbox.merge(m.bbox!);
      }
    }

    if (truthy(style.padding)) {
      bbox.x1 = bbox.x1! - style.padding;
      bbox.x2 = bbox.x2! + style.padding;
      bbox.y1 = bbox.y1! - style.padding;
      bbox.y2 = bbox.y2! + style.padding;
    }

    final strokeWidth = parseFloat(style.strokeWidth);
    final outlineWidth = parseFloat(style.outlineWidth);
    var ax = 100 as num, ay = 100 as num;
    octagonAnchor = SymbolPoint(
      ((ax - bbox.x1! + strokeWidth + outlineWidth) * style.size) / 100,
      ((ay - bbox.y1! + strokeWidth + outlineWidth) * style.size) / 100,
    );
    //If it is a headquarters the anchor should be at the end of the staf
    if (metadata.headquarters) {
      final hqStaffLength = truthy(style.hqStaffLength) ? style.hqStaffLength : ms.hqStaffLength;
      ax = metadata.baseGeometry.bbox.x1!;
      ay = metadata.baseGeometry.bbox.y2! + hqStaffLength;
    }

    if (style.square) {
      final maxx = _max(ax - bbox.x1!, bbox.x2! - ax);
      final maxy = _max(ay - bbox.y1!, bbox.y2! - ay);
      final max = _max(maxx, maxy);
      bbox.x1 = ax - max;
      bbox.y1 = ay - max;
      bbox.x2 = ax + max;
      bbox.y2 = ay + max;
    }

    baseWidth = bbox.width() + style.strokeWidth * 2 + style.outlineWidth * 2;
    baseHeight = bbox.height() + style.strokeWidth * 2 + style.outlineWidth * 2;

    width = (baseWidth * style.size) / 100;
    height = (baseHeight * style.size) / 100;

    anchor = SymbolPoint(
      ((ax - bbox.x1! + strokeWidth + outlineWidth) * style.size) / 100,
      ((ay - bbox.y1! + strokeWidth + outlineWidth) * style.size) / 100,
    );
  }
}

/// `Math.max` for two values (NaN propagates).
num _max(num a, num b) => a.isNaN || b.isNaN ? double.nan : (a >= b ? a : b);

/// Color of [mode] for [affiliation] when [value] is a [ColorMode], else [value].
Object? colorFor(Object value, String? affiliation) =>
    value is ColorMode ? value[affiliation] : value;
