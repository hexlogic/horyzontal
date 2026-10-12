// Ported from milsymbol src/symbolfunctions/textfields.js, MIT (c) Måns Beckman.

import 'dart:math' as math;

import '../bbox.dart';
import '../js.dart';
import '../ms.dart';
import '../symbol.dart';
import 'common.dart';
import 'string_width.dart';

/// Text amplifiers around the symbol, or label overrides of control measures.
SymbolPartResult textfields(MilSymbol s, Ms ms) {
  final style = s.options;
  final metadata = s.metadata;
  final drawArray1 = <Object?>[];
  final drawArray2 = <Object?>[];
  final bbox = metadata.baseGeometry.bbox;
  num flag = truthy(style['country_flag']) ? 70 : 0;
  flag =
      truthy(style['full_frame_flag']) &&
          metadata.affiliation == 'Friend' &&
          metadata.dimension == 'Ground'
      ? 0
      : flag;
  flag += looseEquals(style['signature'], '!') ? 30 : 0;
  final num stack = truthy(style.stack) ? style.stack! * 15 : 0;
  final infoColor = colorFor(style.infoColor, metadata.affiliation);
  final fontColor = truthy(infoColor)
      ? infoColor
      : (truthy(s.colors.iconColor[metadata.affiliation])
            ? s.colors.iconColor[metadata.affiliation]
            : s.colors.iconColor['Friend']);
  final fontFamily = style.fontfamily;
  final fontSize = style.infoSize;

  final infoBackground = colorFor(style.infoBackground, metadata.affiliation);
  // milsymbol reads infoBackground here too.
  final infoBackgroundFrame = colorFor(style.infoBackground, metadata.affiliation);

  final gbbox = BBox();
  const spaceTextIcon = 20; //The distance between the Icon and the labels

  num w(String str, [num extra = 0]) => strWidth(str, fontSize, spaceTextIcon + extra);

  //Text fields overrides
  JsArray labelOverride(Object? label) {
    const spaceTextIcon = 0;
    final texts = <Object?>[];
    if (label is! Map<String, Object?>) return texts;
    for (final i in label.keys) {
      if (style.hasOption(i) && !looseEquals(style[i], '')) {
        final value = jsString(style[i]);
        final entry = label[i];
        final n = entry is List<Object?> ? entry.length : 1;
        for (var j = 0; j < (n == 0 ? 1 : n); j++) {
          final lbl = (entry is List<Object?> ? entry[j] : entry) as Map<String, Object?>;
          final x = lbl['x'] as num, y = lbl['y'] as num, fs = lbl['fontsize'] as num;
          final labelbox = BBox.partial(y2: y, y1: y - fs);
          if (lbl['textanchor'] == 'start') {
            labelbox.x1 = x;
            labelbox.x2 = x + strWidth(value, fs, spaceTextIcon);
          }
          if (lbl['textanchor'] == 'middle') {
            final tw = strWidth(value, fs, spaceTextIcon);
            labelbox.x1 = x - tw / 2;
            labelbox.x2 = x + tw / 2;
          }
          if (lbl['textanchor'] == 'end') {
            labelbox.x1 = x - strWidth(value, fs, spaceTextIcon);
            labelbox.x2 = x;
          }
          gbbox.merge(labelbox);
          final text = <String, Object?>{
            'type': 'text',
            'fontfamily': fontFamily,
            'fill': fontColor,
          };
          for (final k in [
            'alignmentBaseline',
            'fill',
            'stroke',
            'textanchor',
            'fontsize',
            'fontweight',
          ]) {
            if (lbl.containsKey(k)) text[k] = lbl[k];
          }
          text['x'] = lbl['x'];
          text['y'] = lbl['y'];
          text['text'] = style[i];
          texts.add(text);
        }
      }
    }
    return texts;
  }

  // Print text in right position
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
      'fontweight': 'bold',
      'fontfamily': fontFamily,
      'fill': fontColor,
    };
  }

  if (metadata.numberSIDC) {
    //Number based SIDCs.
    final cache = ms.labelCache['number'] ??= () {
      final c = <String, Object?>{};
      for (final f in ms.labelOverrides['number'] ?? const []) {
        f(c);
      }
      return c;
    }();
    final genericSIDC = substr(metadata.functionid, 0, 6);
    if (metadata.controlMeasure && cache.containsKey(genericSIDC)) {
      drawArray2.add(labelOverride(cache[genericSIDC]));
      //outline
      if (style.outlineWidth > 0) {
        drawArray1.add(
          msOutline(drawArray2, style.outlineWidth, style.strokeWidth, outlineColorOf(s)),
        );
      }
      return SymbolPartResult(drawArray1, drawArray2, gbbox);
    }
  }
  // Letter based SIDCs have no label overrides in this port.

  //Check that we have some texts to print
  final textFields =
      style.quantity != '' ||
      style.reinforcedReduced != '' ||
      style.staffComments != '' ||
      style.additionalInformation != '' ||
      style.evaluationRating != '' ||
      style.combatEffectiveness != '' ||
      style.signatureEquipment != '' ||
      style.higherFormation != '' ||
      style.hostile != '' ||
      style.iffSif != '' ||
      style.sigint != '' ||
      style.uniqueDesignation != '' ||
      style.type != '' ||
      style.dtg != '' ||
      style.altitudeDepth != '' ||
      style.location != '' ||
      style.speed != '' ||
      style.specialHeadquarters != '' ||
      style.platformType != '' ||
      style.equipmentTeardownTime != '' ||
      style.commonIdentifier != '' ||
      style.auxiliaryEquipmentIndicator != '' ||
      style.headquartersElement != '' ||
      style.installationComposition != '' ||
      style.guardedUnit != '' ||
      style.specialDesignator != '';
  if (style.infoFields && textFields) {
    if (style.specialHeadquarters != '') {
      drawArray2.add(text(style.specialHeadquarters));
    }
    if (style.quantity != '' && !metadata.dismounted) {
      //geometry
      drawArray2.add(<String, Object?>{
        'type': 'text',
        'text': style.quantity,
        'x': 100,
        'y': bbox.y1! - 10,
        'textanchor': 'middle',
        'fontsize': fontSize,
        'fontfamily': fontFamily,
        'fill': fontColor,
        'stroke': false,
      });
      gbbox.y1 = bbox.y1! - 10 - fontSize;
    }
    if (style.headquartersElement != '') {
      //geometry
      drawArray2.add(<String, Object?>{
        'type': 'text',
        'text': style.headquartersElement,
        'x': 100,
        'y': bbox.y2! + 35,
        'textanchor': 'middle',
        'fontsize': 35,
        'fontfamily': fontFamily,
        'fontweight': 'bold',
        'fill': fontColor,
        'stroke': false,
      });
      gbbox.y2 = bbox.y2! + 35;
    }

    //Text information on left and right sIde.
    final g = <String, String>{
      'L1': '',
      'L2': '',
      'L3': '',
      'L4': '',
      'L5': '',
      'R1': '',
      'R2': '',
      'R3': '',
      'R4': '',
      'R5': '',
    };
    String join(List<String> parts) => parts.where((p) => p != '').join('/');
    final numeric = !jsIsNaN(s.sidc);
    //Air & Space (They should be different but we skip that at the moment) TODO
    if (numeric && metadata.baseDimension == 'Air') {
      g['R1'] = style.uniqueDesignation;
      g['R2'] = style.iffSif;
      g['R3'] = style.type;
      if (style.speed != '' || style.altitudeDepth != '') {
        g['R4'] = join([style.speed, style.altitudeDepth]);
      }
      if (style.staffComments != '' || style.additionalInformation != '') {
        g['R5'] = join([style.staffComments, style.additionalInformation]);
      }
    }
    //Land or letterbased SIDC
    if (!numeric || metadata.baseDimension == 'Ground') {
      g['L1'] = style.dtg;
      if (style.altitudeDepth != '' || style.location != '') {
        g['L2'] = join([style.altitudeDepth, style.location]);
      }
      g['L4'] = style.uniqueDesignation;
      g['L5'] = style.speed;
      g['R2'] = style.staffComments;
      g['R4'] = style.higherFormation;
      if (style.evaluationRating != '' ||
          style.combatEffectiveness != '' ||
          style.signatureEquipment != '' ||
          style.hostile != '' ||
          style.iffSif != '') {
        g['R5'] = join([
          style.evaluationRating,
          style.combatEffectiveness,
          style.signatureEquipment,
          style.hostile,
          style.iffSif,
        ]);
      }
      if (!numeric || metadata.unit) {
        if (style.type != '' || style.platformType != '' || style.equipmentTeardownTime != '') {
          g['L3'] = join([style.type, style.platformType, style.equipmentTeardownTime]);
        }
        g['R1'] = style.reinforcedReduced;
        if (metadata.activity) g['R1'] = style.country;
        if (style.additionalInformation != '' || style.commonIdentifier != '') {
          g['R3'] = join([style.additionalInformation, style.commonIdentifier]);
        }
      } else {
        if (style.type != '' ||
            style.platformType != '' ||
            style.commonIdentifier != '' ||
            style.installationComposition != '') {
          g['L3'] = join([
            style.type,
            style.platformType,
            style.commonIdentifier,
            style.installationComposition,
          ]);
        }
        g['R1'] = style.country;
        if (style.additionalInformation != '' || style.equipmentTeardownTime != '') {
          g['R3'] = join([style.additionalInformation, style.equipmentTeardownTime]);
        }
      }
    }
    // Dismounted individual
    if (metadata.dismounted) {
      if (style.quantity != '') {
        //geometry
        drawArray2.add(<String, Object?>{
          'type': 'text',
          'text': style.quantity,
          'x': 100,
          'y': bbox.y2! + fontSize,
          'textanchor': 'middle',
          'fontsize': fontSize,
          'fontfamily': fontFamily,
          'fill': fontColor,
          'stroke': false,
        });
        gbbox.y2 = bbox.y2! + fontSize;
      }

      g['L1'] = style.dtg;
      if (style.altitudeDepth != '' || style.location != '') {
        g['L2'] = join([style.altitudeDepth, style.location]);
      }
      if (style.type != '' || style.platformType != '' || style.commonIdentifier != '') {
        g['L3'] = join([style.type, style.platformType, style.commonIdentifier]);
      }
      g['L4'] = style.uniqueDesignation;
      g['L5'] = style.speed;
      g['R1'] = style.country;
      g['R2'] = style.staffComments;
      if (style.additionalInformation != '') {
        g['R3'] = join([style.additionalInformation]);
      }
      g['R4'] = style.higherFormation;
      if (style.evaluationRating != '' ||
          style.combatEffectiveness != '' ||
          style.signatureEquipment != '' ||
          style.hostile != '' ||
          style.iffSif != '') {
        g['R5'] = join([
          style.evaluationRating,
          style.combatEffectiveness,
          style.signatureEquipment,
          style.hostile,
          style.iffSif,
        ]);
      }
    }

    //Sea numberbased SIDC
    if (numeric && metadata.baseDimension == 'Sea') {
      if (style.guardedUnit != '' || style.specialDesignator != '') {
        g['L1'] = join([style.guardedUnit, style.specialDesignator]);
      }
      g['R1'] = style.uniqueDesignation;
      g['R2'] = style.type;
      g['R3'] = style.iffSif;
      if (style.staffComments != '' || style.additionalInformation != '') {
        g['R4'] = join([style.staffComments, style.additionalInformation]);
      }
      if (style.location != '' || style.speed != '') {
        g['R5'] = join([style.location, style.speed]);
      }
    }
    //Sub numberbased SIDC
    if (numeric && metadata.baseDimension == 'Subsurface') {
      g['L1'] = style.specialDesignator;
      g['R1'] = style.uniqueDesignation;
      g['R2'] = style.type;
      g['R3'] = style.altitudeDepth;
      g['R4'] = style.staffComments;
      g['R5'] = style.additionalInformation;
    }

    final baseWidth = metadata.baseGeometry.bbox.width();
    final num hqSide = style.specialHeadquarters != ''
        ? (w(style.specialHeadquarters) - baseWidth) / 2
        : 0;
    final num quantitySide = style.quantity != '' ? (w(style.quantity) - baseWidth) / 2 : 0;
    //Add space on left side
    gbbox.x1 =
        bbox.x1! -
        _maxOf([
          hqSide,
          quantitySide,
          w(g['L1']!),
          w(g['L2']!),
          w(g['L3']!),
          w(g['L4']!),
          w(g['L5']!),
        ]);

    //Space on right side
    gbbox.x2 =
        bbox.x2! +
        _maxOf([
          hqSide,
          quantitySide,
          w(g['R1']!, stack),
          w(g['R2']!, stack),
          w(g['R3']!, stack),
          w(g['R4']!, stack + flag * 1.5),
          w(g['R5']!, stack + flag * 1.5),
        ]);

    //Extra space above for field 1
    if (g['L1'] != '' || g['R1'] != '') {
      gbbox.y1 = _minOf([gbbox.y1!, 100 - 2.5 * fontSize]);
    }
    //Extra space above for field 2
    if (g['L2'] != '' || g['R2'] != '') {
      gbbox.y1 = _minOf([gbbox.y1!, 100 - 1.5 * fontSize]);
    }
    //Extra space below for field 4
    if (g['L4'] != '' || g['R4'] != '') {
      gbbox.y2 = _maxOf([gbbox.y2!, 100 + 1.7 * fontSize]);
    }
    //Extra space below for field 5
    if (g['L5'] != '' || g['R5'] != '') {
      gbbox.y2 = _maxOf([gbbox.y2!, 100 + 2.7 * fontSize]);
    }

    // Background boxes behind text
    if (truthy(style.infoBackground)) {
      var leftBox = BBox.partial(x1: 100, y1: 1000, y2: 0);
      var rightBox = BBox.partial(x2: 100, y1: 1000, y2: 0);
      const half = spaceTextIcon / 2;
      for (final (key, top, bottom) in [
        ('L1', -2.5, -1.5),
        ('L2', -1.5, -0.5),
        ('L3', -0.5, 0.5),
        ('L4', 0.5, 1.5),
        ('L5', 1.5, 2.5),
      ]) {
        if (g[key] != '') {
          leftBox = BBox.partial(
            x1: _minOf([leftBox.x1!, bbox.x1! - w(g[key]!)]),
            x2: bbox.x1! - half,
            y1: _minOf([leftBox.y1!, 100 + top * fontSize]),
            y2: _maxOf([leftBox.y2!, 100 + bottom * fontSize + half]),
          );
        }
      }
      if (leftBox.x2 != null) {
        gbbox.x1 = gbbox.x1! - fontSize / 2;
        final l = leftBox;
        drawArray2.add(<String, Object?>{
          'type': 'path',
          'd':
              'M ${jsNumber(l.x1! - fontSize / 2)},${jsNumber(l.y1! + fontSize / 2)} '
              '${jsNumber(l.x1!)},${jsNumber(l.y1!)} ${jsNumber(l.x2!)},${jsNumber(l.y1!)} '
              '${jsNumber(l.x2!)},${jsNumber(l.y2!)} ${jsNumber(l.x1! - fontSize / 2)},'
              '${jsNumber(l.y2!)}z',
          'fill': infoBackground,
          'stroke': truthy(infoBackgroundFrame) ? infoBackgroundFrame : false,
        });
      }
      for (final (key, top, bottom) in [
        ('R1', -2.5, -1.5),
        ('R2', -1.5, -0.5),
        ('R3', -0.5, 0.5),
        ('R4', 0.5, 1.5),
        ('R5', 1.5, 2.5),
      ]) {
        if (g[key] != '') {
          rightBox = BBox.partial(
            x1: bbox.x2! + half,
            x2: _maxOf([rightBox.x2!, bbox.x2! + w(g[key]!)]),
            y1: _minOf([rightBox.y1!, 100 + top * fontSize]),
            y2: _maxOf([rightBox.y2!, 100 + bottom * fontSize + half]),
          );
        }
      }
      if (rightBox.x1 != null) {
        gbbox.x2 = gbbox.x2! + fontSize / 2;
        final r = rightBox;
        drawArray2.add(<String, Object?>{
          'type': 'path',
          'd':
              'M ${jsNumber(r.x1!)},${jsNumber(r.y1!)} ${jsNumber(r.x2! + fontSize / 2)},'
              '${jsNumber(r.y1!)} ${jsNumber(r.x2! + fontSize / 2)},'
              '${jsNumber(r.y2! - fontSize / 2)} ${jsNumber(r.x2!)},${jsNumber(r.y2!)} '
              '${jsNumber(r.x1!)},${jsNumber(r.y2!)}z',
          'fill': infoBackground,
          'stroke': truthy(infoBackgroundFrame) ? infoBackgroundFrame : false,
        });
      }
    }
    //geometries
    JsObject field(String str, num x, num y, String anchor) => {
      'type': 'text',
      'text': str,
      'x': x,
      'y': y,
      'textanchor': anchor,
      'fontsize': fontSize,
      'fontfamily': fontFamily,
      'fill': fontColor,
      'stroke': false,
    };
    final lx = bbox.x1! - spaceTextIcon;
    if (g['L1'] != '') drawArray2.add(field(g['L1']!, lx, 100 - 1.5 * fontSize, 'end'));
    if (g['L2'] != '') drawArray2.add(field(g['L2']!, lx, 100 - 0.5 * fontSize, 'end'));
    if (g['L3'] != '') drawArray2.add(field(g['L3']!, lx, 100 + 0.5 * fontSize, 'end'));
    if (g['L4'] != '') drawArray2.add(field(g['L4']!, lx, 100 + 1.5 * fontSize, 'end'));
    if (g['L5'] != '') drawArray2.add(field(g['L5']!, lx, 100 + 2.5 * fontSize, 'end'));

    final rx = bbox.x2! + spaceTextIcon + stack;
    final rfx = flag + bbox.x2! + spaceTextIcon + stack;
    if (g['R1'] != '') drawArray2.add(field(g['R1']!, rx, 100 - 1.5 * fontSize, 'start'));
    if (g['R2'] != '') drawArray2.add(field(g['R2']!, rx, 100 - 0.5 * fontSize, 'start'));
    if (g['R3'] != '') drawArray2.add(field(g['R3']!, rx, 100 + 0.5 * fontSize, 'start'));
    if (g['R4'] != '') drawArray2.add(field(g['R4']!, rfx, 100 + 1.5 * fontSize, 'start'));
    if (g['R5'] != '') drawArray2.add(field(g['R5']!, rfx, 100 + 2.5 * fontSize, 'start'));

    //outline
    final iow = style.infoOutlineWidth;
    if ((iow != null && iow > 0) || (iow == null && style.outlineWidth > 0)) {
      drawArray1.add(
        msOutline(
          drawArray2,
          iow ?? style.outlineWidth,
          style.strokeWidth,
          truthy(style.infoOutlineColor) ? style.infoOutlineColor : outlineColorOf(s),
        ),
      );
    }
  }
  return SymbolPartResult(drawArray1, drawArray2, gbbox);
}

num _maxOf(List<num> v) => v.any((e) => e.isNaN) ? double.nan : v.reduce(math.max);
num _minOf(List<num> v) => v.any((e) => e.isNaN) ? double.nan : v.reduce(math.min);
