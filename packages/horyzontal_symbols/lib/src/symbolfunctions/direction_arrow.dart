// Ported from milsymbol src/symbolfunctions/directionarrow.js, MIT (c) Måns Beckman.

import 'dart:math' as math;

import '../bbox.dart';
import '../js.dart';
import '../ms.dart';
import '../symbol.dart';
import 'common.dart';

/// Direction of movement arrow or speed leader (field Q).
SymbolPartResult directionarrow(MilSymbol s, Ms ms) {
  final style = s.options;
  final metadata = s.metadata;
  final drawArray1 = <Object?>[];
  final drawArray2 = <Object?>[];
  var bbox = metadata.baseGeometry.bbox;
  if (metadata.baseGeometry.g == null) {
    // in the case we don't have any frame
    bbox = s.bbox; //Set bbox to the current symbols bounds
  }
  final gbbox = BBox();
  final color = truthy(s.colors.iconColor[metadata.affiliation])
      ? s.colors.iconColor[metadata.affiliation]
      : s.colors.iconColor['Friend'];
  Object? arrow;
  final direction = style.direction;
  if (style.infoFields) {
    if (direction != null) {
      if (style.speedLeader == 0) {
        // Movement indicator
        const arrowLength = 95;
        arrow = <Object?>[
          <String, Object?>{
            'type': 'rotate',
            'degree': direction,
            'x': 100,
            'y': 100,
            'draw': <Object?>[
              <String, Object?>{
                'type': 'path',
                'fill': color,
                'stroke': color,
                'strokewidth': style.strokeWidth,
                'd': 'M100,100 l0,-${arrowLength - 20} -5,3 5,-15 5,15 -5,-3',
              },
            ],
          },
        ];
        final rad = (direction / 360) * math.pi * 2;
        gbbox.y1 = _min(100 - math.cos(rad) * arrowLength, 100);
        gbbox.y2 = _max(100 - math.cos(rad) * arrowLength, 100);
        gbbox.x1 = _min(100 + math.sin(rad) * arrowLength, 100);
        gbbox.x2 = _max(100 + math.sin(rad) * arrowLength, 100);

        if (metadata.baseDimension == 'Ground' || metadata.baseDimension == '') {
          if (!metadata.headquarters) {
            // For all symbols not headquarters
            arrow = <Object?>[
              <String, Object?>{'type': 'translate', 'x': 0, 'y': bbox.y2, 'draw': arrow},
              <String, Object?>{
                'type': 'path',
                'fill': color,
                'stroke': color,
                'strokewidth': style.strokeWidth,
                'd': 'M 100,${jsNumber(bbox.y2!)}l0,100',
              },
            ];
          } else {
            // For headquarters
            final hq = truthy(style.hqStaffLength) ? style.hqStaffLength : ms.hqStaffLength;
            arrow = <Object?>[
              <String, Object?>{
                'type': 'translate',
                'x': bbox.x1! - 100,
                'y': bbox.y2! - (100 - hq),
                'draw': arrow,
              },
            ];
            gbbox.x1 = gbbox.x1! + bbox.x1! - 100;
            gbbox.x2 = gbbox.x2! + bbox.x1! - 100;
          }
        }
        gbbox.y2 = gbbox.y2! + bbox.y2! + parseFloat(style.strokeWidth);
        drawArray2.add(arrow);
      } else {
        // This is speed leader
        final length = style.speedLeader * (100 / style.size);
        final rad = (direction * math.pi) / 180;
        final y = -length * math.cos(rad);
        final x = length * math.sin(rad);

        gbbox.x1 = _min(100, 100 + x);
        gbbox.x2 = _max(100, 100 + x);
        gbbox.y1 = _min(100, 100 + y);
        gbbox.y2 = _max(100, 100 + y);
        arrow = <String, Object?>{
          'type': 'path',
          'fill': color,
          'stroke': color,
          'strokewidth': style.strokeWidth,
          'd': 'M 100,100  l${jsNumber(x)},${jsNumber(y)}',
        };
        drawArray1.add(arrow);
      }
      //outline
      if (style.outlineWidth > 0) {
        drawArray1.insert(
          0,
          msOutline(arrow, style.outlineWidth, style.strokeWidth, outlineColorOf(s)),
        );
      }
    }
  }
  return SymbolPartResult(drawArray1, drawArray2, gbbox);
}

num _min(num a, num b) => a.isNaN || b.isNaN ? double.nan : (a <= b ? a : b);
num _max(num a, num b) => a.isNaN || b.isNaN ? double.nan : (a >= b ? a : b);
