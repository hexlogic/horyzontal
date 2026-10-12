// Ported from milsymbol src/symbolfunctions/icon.js, MIT (c) Måns Beckman.

import '../bbox.dart';
import '../js.dart';
import '../ms.dart';
import '../symbol.dart';
import 'common.dart';

/// Land equipment entities whose icon is not shrunk for sector modifiers.
const _equipmentNoScale = [
  130100,
  170000,
  170400,
  170600,
  170700,
  170800,
  170900,
  171100,
  200200,
  200300,
  200600,
  200700,
  200800,
  200900,
  201100,
  201301,
  201302,
  201400,
  210100,
  210200,
  210300,
  210400,
  210500,
  230200,
  250000,
];

/// Drawn for unknown icon codes: a question mark.
JsArray _undefinedIcon(Object? iconColor) => [
  <String, Object?>{
    'type': 'path',
    'stroke': false,
    'fill': iconColor,
    'd': 'm 94.8206,78.1372 c -0.4542,6.8983 0.6532,14.323 5.3424,19.6985 4.509,5.6933 11.309,9.3573 14.98,15.7283 3.164,6.353 -0.09,14.245 -5.903,17.822 -7.268,4.817 -18.6219,2.785 -22.7328,-5.249 -1.5511,-2.796 -2.3828,-5.931 -2.8815,-9.071 -3.5048,0.416 -7.0093,0.835 -10.5142,1.252 0.8239,8.555 5.2263,17.287 13.2544,21.111 7.8232,3.736 17.1891,3.783 25.3291,1.052 8.846,-3.103 15.737,-11.958 15.171,-21.537 0.05,-6.951 -4.272,-12.85 -9.134,-17.403 -4.526,-4.6949 -11.048,-8.3862 -12.401,-15.2748 -1.215,-2.3639 -0.889,-8.129 -0.889,-8.129 z m -0.6253,-20.5177 0,11.6509 11.6527,0 0,-11.6509 z',
  },
];

/// Cache key of the icon parts and tables. milsymbol's key
/// (`standard:...,colors:{...}`) plus everything else the icon part
/// functions read, so cached parts equal freshly built ones.
String _iconKey(MilSymbol s) {
  final m = s.metadata;
  final b = m.baseGeometry.bbox;
  return 'standard:${m.std2525 ? '2525' : 'APP6'},edition:${m.edition ?? ''},'
      '${m.dimension}${jsString(m.affiliation)}${m.notpresent}${m.numberSIDC},'
      'frame:${s.options.frame},metaFrame:${m.frame},alternateMedal:${s.options.alternateMedal},'
      'monoColor:${s.options.monoColor},bbox:${b.x1},${b.y1},${b.x2},${b.y2},'
      'colors:${s.colors.cacheKey()}';
}

/// Deep copy of draw instructions that keeps shared sub-objects shared.
Object? _clone(Object? v, Map<Object, Object> seen) {
  if (v is Map<String, Object?>) {
    final done = seen[v];
    if (done != null) return done;
    final c = <String, Object?>{};
    seen[v] = c;
    v.forEach((k, e) => c[k] = _clone(e, seen));
    return c;
  }
  if (v is List<Object?>) {
    final done = seen[v];
    if (done != null) return done;
    final c = <Object?>[];
    seen[v] = c;
    for (final e in v) {
      c.add(_clone(e, seen));
    }
    arrayProperties(v).forEach((k, e) => setArrayProperty(c, k, _clone(e, seen)));
    return c;
  }
  return v;
}

/// The icon of the symbol with its sector 1 and 2 modifiers.
SymbolPartResult icon(MilSymbol s, Ms ms) {
  final style = s.options;
  final metadata = s.metadata;
  final drawArray1 = <Object?>[];
  final drawArray2 = <Object?>[];
  var gbbox = BBox(BBox.partial(x1: 50, x2: 150, y1: 50, y2: 150));

  if (style.icon) {
    final affiliation = metadata.affiliation;
    final iconColor = s.colors.iconColor[affiliation];

    if (metadata.numberSIDC) {
      //Number based SIDCs.
      final symbolSet = substring(s.sidc, 4, 6);
      final tables = ms.numberIconsFor(
        _iconKey(s),
        symbolSet,
        metadata,
        s.colors,
        metadata.std2525,
        style.monoColor,
        style.alternateMedal,
        metadata.edition,
      );
      var icons = tables.icons;
      var m1 = tables.m1;
      var m2 = tables.m2;
      var iconParts = tables.iconParts;
      final specialbbox = tables.bbox;
      final functionid = metadata.functionid;
      final entity = substr(functionid, 0, 6);
      final mainSIDC = toNumber(entity);

      //Handle special cases of dismounted individual where weapons should be scaled
      final scaled =
          (symbolSet == '27' && mainSIDC >= 110301 && mainSIDC <= 110403) ||
          (symbolSet == '15' && !_equipmentNoScale.contains(mainSIDC));
      if (scaled) {
        // milsymbol scales the cached instructions in place, which changes
        // later symbols. Scale a copy of everything this symbol draws from the
        // tables instead (one identity map, so shared parts stay shared).
        final seen = <Object, Object>{};
        final base = '${substr(functionid, 0, 4)}00';
        icons = {entity: _clone(icons[entity], seen), base: _clone(icons[base], seen)};
        final k1 = substr(metadata.modifier1, 0, 1) == '0'
            ? substr(functionid, 6, 2)
            : metadata.modifier1;
        final k2 = substr(metadata.modifier2, 0, 1) == '0'
            ? substr(functionid, 8, 2)
            : metadata.modifier2;
        m1 = {k1: _clone(m1[k1], seen)};
        m2 = {k2: _clone(m2[k2], seen)};
        iconParts = {for (final k in Ms.directParts) k: _clone(iconParts[k], seen)};
      }

      // Put all this togheter and return the Icon. ============================================
      var mainIcon = icons[entity]; //Main symbol
      if (mainIcon == null && ge(substr(functionid, 4, 2), 95)) {
        //We have some special entity subtype and will try to find original symbol.
        mainIcon = icons['${substr(functionid, 0, 4)}00'];
      }
      if (mainIcon == null) {
        if (!(entity == '000000' || entity == '')) {
          drawArray2.add(_undefinedIcon(iconColor));
          s.validIcon = false;
        }
      } else {
        if (scaled) {
          final mod1 = metadata.modifier1, mod2 = metadata.modifier2;
          if (mod1 != '000' && mod2 != '000') {
            mainIcon = [msScale(0.45, mainIcon, true)];
          }
          if (mod1 == '000' && mod2 != '000') {
            mainIcon = [msTranslate(0, -10, msScale(0.7, mainIcon, true))];
          }
          if (mod1 != '000' && mod2 == '000') {
            mainIcon = [msTranslate(0, 10, msScale(0.7, mainIcon, true))];
          }
          if (mod1 == '000' && mod2 == '000') {
            // This is to make sure we reset the stroke width if the symbol shouldn't be scaled.
            mainIcon = [msScale(1, mainIcon, true)];
          }
        }
        // End special case, just add to draw array
        drawArray2.add(mainIcon);
      }
      if (specialbbox.containsKey(entity)) {
        gbbox = BBox.fromJs(specialbbox[entity]);
      }
      final sub = substr(functionid, 4, 2);
      if (sub == '95') drawArray2.add(iconParts['GR.IC.FF.HEADQUARTERS OR HEADQUARTERS ELEMENT']);
      if (sub == '96') drawArray2.add(iconParts['GR.IC.FF.DIVISION AND BELOW SUPPORT']);
      if (sub == '97') drawArray2.add(iconParts['GR.IC.FF.CORPS SUPPORT']);
      if (sub == '98') drawArray2.add(iconParts['GR.IC.FF.THEATRE SUPPORT']);
      //Modifier 1
      if (substr(metadata.modifier1, 0, 1) == '0') {
        if (substr(functionid, 6, 2) != '00') {
          final modifier1 = m1[substr(functionid, 6, 2)];
          if (modifier1 == null) {
            s.validIcon = false;
          } else {
            drawArray2.add(modifier1);
          }
        }
      } else {
        final modifier1 = m1[metadata.modifier1];
        if (modifier1 == null) {
          s.validIcon = false;
        } else {
          drawArray2.add(modifier1);
        }
      }

      //Modifier 2
      if (substr(metadata.modifier2, 0, 1) == '0') {
        if (substr(functionid, 8, 2) != '00') {
          final modifier2 = m2[substr(functionid, 8, 2)];
          if (modifier2 == null) {
            s.validIcon = false;
          } else {
            drawArray2.add(modifier2);
          }
        }
      } else {
        final modifier2 = m2[metadata.modifier2];
        if (modifier2 == null) {
          s.validIcon = false;
        } else {
          drawArray2.add(modifier2);
        }
      }
    } else {
      // Letter based SIDCs are not ported. milsymbol without letter modules
      // fails here; the port draws the unknown icon instead.
      final code = substr(s.sidc, 4, 6);
      if (!(code == '------' || code == '')) {
        drawArray2.add(_undefinedIcon(iconColor));
        s.validIcon = false;
      }
    }
  }
  //outline
  if (!(style.frame && metadata.fill) || truthy(style.monoColor) || metadata.controlMeasure) {
    if (style.outlineWidth > 0) {
      drawArray1.add(
        msOutline(drawArray2, style.outlineWidth, style.strokeWidth, outlineColorOf(s)),
      );
    }
  }
  return SymbolPartResult(drawArray1, drawArray2, gbbox);
}
