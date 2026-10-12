// Ported from milsymbol src/symbolfunctions/modifier.js, MIT (c) Måns Beckman.

import '../bbox.dart';
import '../color_mode.dart';
import '../js.dart';
import '../ms.dart';
import '../symbol.dart';
import 'common.dart';

String _n(num v) => jsNumber(v);

JsObject _echelon(List<JsObject> g, BBox bbox) => {'g': g, 'bbox': bbox};

/// Headquarters staff, task force, installation, feint/dummy, echelon,
/// mobility and leadership amplifiers.
SymbolPartResult modifier(MilSymbol s, Ms ms) {
  final style = s.options;
  final metadata = s.metadata;
  final drawArray1 = <Object?>[];
  final drawArray2 = <Object?>[];
  final bbox = BBox(metadata.baseGeometry.bbox); // clone the bbox
  // `style.frameColor[affiliation]`: a non-empty string gives undefined in JS.
  final frameColorStyle = style.frameColor;
  final color = truthy(frameColorStyle is ColorMode ? true : frameColorStyle)
      ? (frameColorStyle is ColorMode ? frameColorStyle[metadata.affiliation] : null)
      : s.colors.iconColor[metadata.affiliation];
  final gbbox = BBox(); // bounding box for the added geometries
  Object? geom;
  final dimAff = '${metadata.dimension}${jsString(metadata.affiliation)}';

  void addOutline(Object? g) {
    if (style.outlineWidth > 0) {
      drawArray1.add(msOutline(g, style.outlineWidth, style.strokeWidth, outlineColorOf(s)));
    }
  }

  final hqStaffLength = toNumber(
    truthy(style.hqStaffLength) ? style.hqStaffLength : ms.hqStaffLength,
  );
  if (metadata.headquarters && hqStaffLength > 0) {
    //HEADQUARTERS
    num y = 100;
    if ([
      'AirFriend',
      'AirNeutral',
      'GroundFriend',
      'GroundNeutral',
      'SeaNeutral',
      'SubsurfaceNeutral',
    ].contains(dimAff)) {
      y = bbox.y2!;
    }
    // milsymbol compares `dimensionType + affiliationType` here, which are
    // never set, so the subsurface case never applies.
    geom = <String, Object?>{
      'type': 'path',
      'd': 'M${_n(bbox.x1!)},${_n(y)} L${_n(bbox.x1!)},${_n(bbox.y2! + hqStaffLength)}',
    };
    addOutline(geom);
    drawArray2.add(geom);
    gbbox.y2 = bbox.y2! + hqStaffLength;
  }
  if (metadata.taskForce) {
    //TASK FORCE
    final num width =
        const {
          'Corps/MEF': 110,
          'Army': 145,
          'Army Group/front': 180,
          'Region/Theater': 215,
        }[metadata.echelon] ??
        90;
    geom = <String, Object?>{
      'type': 'path',
      'd':
          'M${_n(100 - width / 2)},${_n(bbox.y1!)} L${_n(100 - width / 2)},${_n(bbox.y1! - 40)} '
          '${_n(100 + width / 2)},${_n(bbox.y1! - 40)} ${_n(100 + width / 2)},${_n(bbox.y1!)}',
    };
    addOutline(geom);
    drawArray2.add(geom);
    gbbox.x1 = _min(bbox.x1!, 100 - width / 2);
    gbbox.x2 = _max(bbox.x2!, 100 + width / 2);
    gbbox.y1 = bbox.y1! - 40;
  }
  if (metadata.installation) {
    //INSTALLATION
    num gapFiller = 0;
    if (['AirHostile', 'GroundHostile', 'SeaHostile'].contains(dimAff)) gapFiller = 14;
    if (['AirUnknown', 'GroundUnknown', 'SeaUnknown', 'AirFriend', 'SeaFriend'].contains(dimAff)) {
      gapFiller = 2;
    }
    final sw = style.strokeWidth;
    geom = <String, Object?>{
      'type': 'path',
      'fill': color,
      'd':
          'M85,${_n(bbox.y1! + gapFiller - sw / 2)} 85,${_n(bbox.y1! - 10)} '
          '115,${_n(bbox.y1! - 10)} 115,${_n(bbox.y1! + gapFiller - sw / 2)} '
          '100,${_n(bbox.y1! - sw)} Z',
    };
    addOutline(geom);
    drawArray2.add(geom);
    gbbox.merge(BBox.partial(y1: bbox.y1! - 10));
  }
  if (metadata.feintDummy) {
    //FEINT DUMMY
    final topPoint = bbox.y1! - 0 - bbox.width() / 2;
    geom = <String, Object?>{
      'type': 'path',
      'strokedasharray': ms.dashArrays.feintDummy,
      'd':
          'M100,${_n(topPoint)} L${_n(bbox.x1!)},${_n(bbox.y1! - 0)} '
          'M100,${_n(topPoint)} L${_n(bbox.x2!)},${_n(bbox.y1! - 0)}',
    };
    addOutline(geom);
    drawArray2.add(geom);
    gbbox.merge(BBox.partial(y1: topPoint));
  }
  //Unit Size
  if (truthy(metadata.echelon)) {
    final num installationPadding = metadata.installation ? 15 : 0;
    final y1 = bbox.y1!;
    JsObject circle(num cx, num r, [bool filled = true]) => {
      'type': 'circle',
      if (filled) 'fill': color,
      'cx': cx,
      'cy': y1 - 20,
      'r': r,
    };
    JsObject path(String d) => {'type': 'path', 'd': d};
    String bar(num x) => 'M${_n(x)},${_n(y1 - 10)}L${_n(x)},${_n(y1 - 35)}';
    String cross(num x, [String sep = '']) => 'M${_n(x)},${_n(y1 - 10)} l25,-25 m0,25 l-25,-25$sep';
    final echelonBox = BBox.partial(y1: y1 - 15 - 25 - installationPadding);
    BBox wide(num x1, num x2) =>
        BBox.partial(y1: y1 - 15 - 25 - installationPadding, x1: x1, x2: x2);
    final echelons = <String, JsObject>{
      'Team/Crew': _echelon([
        circle(100, 15, false),
        path('M80,${_n(y1 - 10)}L120,${_n(y1 - 30)}'),
      ], BBox.partial(y1: y1 - 40 - installationPadding)),
      'Squad': _echelon([circle(100, 7.5)], BBox.partial(y1: y1 - 20 - 7.5 - installationPadding)),
      'Section': _echelon([
        circle(115, 7.5),
        circle(85, 7.5),
      ], BBox.partial(y1: y1 - 20 - 7.5 - installationPadding)),
      'Platoon/detachment': _echelon([
        circle(100, 7.5),
        circle(70, 7.5),
        circle(130, 7.5),
      ], BBox.partial(y1: y1 - 20 - 7.5 - installationPadding)),
      'Company/battery/troop': _echelon([
        path(bar(100)),
      ], BBox.partial(y1: y1 - 40 - installationPadding)),
      'Battalion/squadron': _echelon([
        path(bar(90)),
        path(bar(110)),
      ], BBox.partial(y1: y1 - 40 - installationPadding)),
      'Regiment/group': _echelon([
        path(bar(100)),
        path(bar(120)),
        path(bar(80)),
      ], BBox.partial(y1: y1 - 40 - installationPadding)),
      'Brigade': _echelon([path(cross(87.5))], echelonBox),
      'Division': _echelon([path('${cross(70, '   ')}${cross(105)}')], wide(70, 130)),
      'Corps/MEF': _echelon([
        path('${cross(52.5, '    ')}${cross(87.5, '    ')}${cross(122.5)}'),
      ], wide(52.5, 147.5)),
      'Army': _echelon([
        path('${cross(35, '   ')}${cross(70, '   ')}${cross(105, '    ')}${cross(140)}'),
      ], wide(35, 165)),
      'Army Group/front': _echelon([
        path(
          '${cross(17.5, '    ')}${cross(52.5, '    ')}${cross(87.5, '    ')}'
          '${cross(122.5, '       ')}${cross(157.5)}',
        ),
      ], wide(17.5, 182.5)),
      'Region/Theater': _echelon([
        path(
          '${cross(0, '   ')}${cross(35, '   ')}${cross(70, '   ')}'
          '${cross(105, '    ')}${cross(140, '     ')}${cross(175)}',
        ),
      ], wide(0, 200)),
      'Command': _echelon([
        path(
          'M70,${_n(y1 - 22.5)} l25,0 m-12.5,12.5 l0,-25   '
          'M105,${_n(y1 - 22.5)} l25,0 m-12.5,12.5 l0,-25',
        ),
      ], wide(70, 130)),
    };
    final e = echelons[metadata.echelon];
    if (e != null) {
      geom = e['g'];
      addOutline(<String, Object?>{
        'type': 'translate',
        'x': 0,
        'y': -installationPadding,
        'draw': geom,
      });
      drawArray2.add(<String, Object?>{
        'type': 'translate',
        'x': 0,
        'y': -installationPadding,
        'draw': geom,
      });
      gbbox.merge(e['bbox'] as BBox);
    }
  }
  //This is for movability indicators.
  if (truthy(metadata.mobility)) {
    if (!style.frame) {
      bbox.y2 = s.bbox.y2;
    }
    final mobility = metadata.mobility;
    if (metadata.affiliation == 'Neutral') {
      if (mobility == 'Towed' ||
          mobility == 'Short towed array' ||
          mobility == 'Long towed Array') {
        bbox.y2 = bbox.y2! + 8;
      }
      if (mobility == 'Over snow (prime mover)' || mobility == 'Sled') {
        bbox.y2 = bbox.y2! + 18;
      }
      if (mobility == 'Barge') {
        bbox.y2 = bbox.y2! + 5;
      }
    }
    final y2 = bbox.y2!;
    JsObject c(num cx, num cy) => {'type': 'circle', 'cx': cx, 'cy': cy, 'r': 8};
    JsObject p(String d, {bool filled = false}) => {
      'type': 'path',
      if (filled) 'fill': color,
      'd': d,
    };
    final mobilities = <String, JsObject>{
      'Wheeled limited cross country': _echelon([
        p('M 53,1 l 94,0'),
        c(58, 8),
        c(142, 8),
      ], BBox.partial(y2: y2 + 8 * 2)),
      'Wheeled cross country': _echelon([
        p('M 53,1 l 94,0'),
        c(58, 8),
        c(142, 8),
        c(100, 8),
      ], BBox.partial(y2: y2 + 8 * 2)),
      'Tracked': _echelon([
        p('M 53,1 l 100,0 c15,0 15,15 0,15 l -100,0 c-15,0 -15,-15 0,-15'),
      ], BBox.partial(y2: y2 + 18, x1: 42, x2: 168)),
      'Wheeled and tracked combination': _echelon([
        c(58, 8),
        p('M 83,1 l 70,0 c15,0 15,15 0,15 l -70,0 c-15,0 -15,-15 0,-15'),
      ], BBox.partial(y2: y2 + 8 * 2, x2: 168)),
      'Towed': _echelon([p('M 63,1 l 74,0'), c(58, 3), c(142, 3)], BBox.partial(y2: y2 + 10)),
      'Rail': _echelon([
        p('M 53,1 l 96,0'),
        c(58, 8),
        c(73, 8),
        c(127, 8),
        c(142, 8),
      ], BBox.partial(y2: y2 + 8 * 2)),
      'Over snow (prime mover)': _echelon([p('M 50,-9 l10,10 90,0')], BBox.partial(y2: y2 + 9)),
      'Sled': _echelon([
        p('M 145,-12  c15,0 15,15 0,15 l -90,0 c-15,0 -15,-15 0,-15'),
      ], BBox.partial(y2: y2 + 15, x1: 42, x2: 168)),
      'Pack animals': _echelon([
        p('M 80,20 l 10,-20 10,20 10,-20 10,20'),
      ], BBox.partial(y2: y2 + 20)),
      'Barge': _echelon([p('M 50,1 l 100,0 c0,10 -100,10 -100,0')], BBox.partial(y2: y2 + 10)),
      'Amphibious': _echelon([
        p(
          'M 65,10 c 0,-10 10,-10 10,0 0,10 10,10 10,0\t0,-10 10,-10 10,0 0,10 10,10 10,0\t0,-10 10,-10 10,0 0,10 10,10 10,0\t0,-10 10,-10 10,0',
        ),
      ], BBox.partial(y2: y2 + 20)),
      'Short towed array': _echelon([
        p(
          'M 50,5 l 100,0 M50,0 l10,0 0,10 -10,0 z M150,0 l-10,0 0,10 10,0 z M100,0 l5,5 -5,5 -5,-5 z',
          filled: true,
        ),
      ], BBox.partial(y2: y2 + 10)),
      'Long towed Array': _echelon([
        p(
          'M 50,5 l 100,0 M50,0 l10,0 0,10 -10,0 z M150,0 l-10,0 0,10 10,0 z M105,0 l-10,0 0,10 10,0 z M75,0 l5,5 -5,5 -5,-5 z  M125,0 l5,5 -5,5 -5,-5 z',
          filled: true,
        ),
      ], BBox.partial(y2: y2 + 10)),
    };
    final e = mobilities[mobility];
    if (e != null) {
      geom = e['g'];
      addOutline(<String, Object?>{'type': 'translate', 'x': 0, 'y': y2, 'draw': geom});
      drawArray2.add(<String, Object?>{'type': 'translate', 'x': 0, 'y': y2, 'draw': geom});
      gbbox.merge(e['bbox'] as BBox);
    }
  }

  //Dismounted Leadership
  if (truthy(metadata.leadership)) {
    final leadership = metadata.affiliation == 'Friend'
        ? <String, Object?>{'type': 'path', 'd': 'm 45,60 55,-25 55,25'}
        : null;
    if (leadership != null) {
      drawArray1.add(leadership);
      gbbox.merge(BBox.partial(y1: bbox.y1! - 20));
    }
  }
  //Assign fill, stroke and stroke-width
  for (final list in [drawArray1, drawArray2]) {
    for (final d in list) {
      if (d is! Map<String, Object?>) continue;
      if (!d.containsKey('fill')) d['fill'] = false;
      if (!d.containsKey('stroke')) d['stroke'] = color;
      if (!d.containsKey('strokewidth')) d['strokewidth'] = style.strokeWidth;
    }
  }
  return SymbolPartResult(drawArray1, drawArray2, gbbox);
}

num _min(num a, num b) => a.isNaN || b.isNaN ? double.nan : (a <= b ? a : b);
num _max(num a, num b) => a.isNaN || b.isNaN ? double.nan : (a >= b ? a : b);
