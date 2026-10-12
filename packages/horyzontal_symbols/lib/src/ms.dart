// Ported from milsymbol src/ms.js and src/ms/outline.js, MIT (c) Måns Beckman.

import 'bbox.dart';
import 'color_mode.dart';
import 'colors.dart';
import 'js.dart';
import 'metadata.dart';
import 'numbersidc.dart';
import 'symbol.dart';
import 'symbolfunctions/affiliation_dimension.dart';
import 'symbolfunctions/basegeometry.dart';
import 'symbolfunctions/debug.dart';
import 'symbolfunctions/direction_arrow.dart';
import 'symbolfunctions/engagement_bar.dart';
import 'symbolfunctions/icon.dart';
import 'symbolfunctions/modifier.dart';
import 'symbolfunctions/stack_extension.dart';
import 'symbolfunctions/status_modifier.dart';
import 'symbolfunctions/text_fields.dart';

/// Adds icon parts (keyed draw instructions such as `GR.IC.ARMOUR`) to
/// [iconParts]; milsymbol's `iconParts` functions.
typedef IconPartsFunction = void Function(
  JsObject iconParts,
  SymbolMetadata metadata,
  SymbolColors colors,
  bool std2525,
  String monoColor,
  bool alternateMedal,
);

/// Fills the icon tables of a number SIDC symbol set: [sId] by the 6 digit
/// entity code, [sIdm1]/[sIdm2] by modifier code, [bbox] with special
/// bounding boxes; milsymbol's `icons` functions.
typedef SidcIconsFunction = void Function(
  JsObject sId,
  JsObject sIdm1,
  JsObject sIdm2,
  JsObject bbox,
  String symbolSet,
  JsObject icn,
  bool std2525,
  String? edition,
);

/// Adds label (text field) placements by entity code; milsymbol's `labels`
/// functions, used by control measures.
typedef LabelOverridesFunction = void Function(JsObject labels);

/// What a symbol part draws: [pre] goes below everything drawn so far,
/// [post] on top, [bbox] is merged into the symbol bounds.
class SymbolPartResult {
  SymbolPartResult(this.pre, this.post, this.bbox);
  final JsArray pre;
  final JsArray post;
  final BBox? bbox;
}

/// One step of building a symbol (frame, icon, modifiers, texts, ...).
typedef SymbolPart = SymbolPartResult Function(MilSymbol symbol, Ms ms);

/// A milsymbol module such as `numbersidc/sidc/landunit.js`: a group of
/// symbol sets with their icon parts, SIDC tables and label overrides.
class SymbolSetModule {
  const SymbolSetModule({
    required this.name,
    required this.symbolSets,
    this.type = 'number',
    this.iconParts,
    this.icons,
    this.labels,
  });

  /// Module name, the file name in milsymbol (`landunit`, `air`, ...).
  final String name;

  /// Symbol set codes (SIDC digits 5-6) the module draws.
  final List<String> symbolSets;

  /// `number` for 20/30 digit SIDCs (the only kind ported).
  final String type;
  final IconPartsFunction? iconParts;
  final SidcIconsFunction? icons;
  final LabelOverridesFunction? labels;
}

/// Dash arrays for frames that are not present.
class DashArrays {
  DashArrays(this.pending, this.anticipated, this.feintDummy);
  String pending, anticipated, feintDummy;
}

/// Icon tables of one symbol set for one combination of colors/standard.
class NumberIcons {
  NumberIcons(this.icons, this.m1, this.m2, this.bbox, this.iconParts);
  final JsObject icons, m1, m2, bbox, iconParts;
}

/// Global state of milsymbol (the JS `ms` object).
class Ms {
  Ms() {
    reset();
  }

  static const version = '3.0.4';
  static const svgNS = 'http://www.w3.org/2000/svg';

  late Map<String, ColorMode> colorModes;
  late DashArrays dashArrays;
  late num hqStaffLength;
  late bool std2525;
  late List<IconPartsFunction> iconParts;
  late List<SidcIconsFunction> numberIcons;
  late Map<String, List<LabelOverridesFunction>> labelOverrides;
  late Map<String, JsObject> labelCache;
  late List<SymbolPart> symbolParts;
  late List<SymbolSetModule> modules;
  final Map<String, NumberIcons> _iconCache = {};

  /// Maximum number of cached icon table entries.
  static const _cacheLimit = 128;

  void reset() {
    colorModes = {};
    defaultColorModes().forEach(setColorMode);
    dashArrays = DashArrays('4,4', '8,12', '8,8');
    hqStaffLength = 100;
    _iconCache.clear();
    iconParts = [];
    numberIcons = [];
    labelOverrides = {};
    labelCache = {};
    modules = [];
    std2525 = true;
    symbolParts = [];
    addSymbolPart(stack);
    addSymbolPart(basegeometry);
    addSymbolPart(icon);
    addSymbolPart(modifier);
    addSymbolPart(statusmodifier);
    addSymbolPart(engagementbar);
    addSymbolPart(affliationdimension);
    addSymbolPart(textfields);
    addSymbolPart(directionarrow);
  }

  ColorMode setColorMode(String mode, ColorMode colorMode) => colorModes[mode] = ColorMode(
    hostile: colorMode.hostile,
    friend: colorMode.friend,
    neutral: colorMode.neutral,
    unknown: colorMode.unknown,
    civilian: colorMode.civilian,
    suspect: colorMode.suspect,
  );

  /// A copy of a registered color mode.
  ColorMode getColorMode(String mode) {
    final c = colorModes[mode];
    if (c == null) throw ArgumentError.value(mode, 'mode', 'unknown color mode');
    return c.copy();
  }

  void addSymbolPart(SymbolPart part) {
    if (!symbolParts.contains(part)) symbolParts = [...symbolParts, part];
  }

  void addIconParts(IconPartsFunction parts) {
    if (!iconParts.contains(parts)) iconParts = [...iconParts, parts];
  }

  void addLabelOverrides(LabelOverridesFunction parts, String type) {
    labelCache = {};
    (labelOverrides[type] ??= []).add(parts);
  }

  void addSidcIcons(SidcIconsFunction parts, String type) {
    if (type == 'number' && !numberIcons.contains(parts)) numberIcons = [...numberIcons, parts];
  }

  /// `ms.addIcons`: registers modules in order. Later icon parts with the
  /// same key override earlier ones, as in milsymbol.
  void addIcons(List<SymbolSetModule> list) {
    _iconCache.clear();
    for (final m in list) {
      if (!modules.contains(m)) modules = [...modules, m];
      if (m.iconParts != null) addIconParts(m.iconParts!);
      if (m.labels != null) addLabelOverrides(m.labels!, m.type);
      if (m.icons != null) addSidcIcons(m.icons!, m.type);
    }
  }

  bool setStandard(String standard) {
    if (standard == '2525') {
      std2525 = true;
      return true;
    }
    if (standard == 'APP6') {
      std2525 = false;
      return true;
    }
    return false;
  }

  void showOctagon() => addSymbolPart(debug);

  /// Registers the ported number SIDC modules in milsymbol's order.
  void registerDefaults() => registerDefaultModules(this);

  /// `ms._getIconParts`: all registered icon parts for these colors.
  JsObject getIconParts(
    SymbolMetadata metadata,
    SymbolColors colors,
    bool std2525,
    String monoColor,
    bool alternateMedal,
  ) {
    final icn = <String, Object?>{};
    for (final f in iconParts) {
      f(icn, metadata, colors, std2525, monoColor, alternateMedal);
    }
    return icn;
  }

  /// `ms._getIcons.number` with milsymbol's icon cache. The key covers
  /// everything the icon parts and tables read, and includes the symbol set:
  /// milsymbol's tables scale shared icon parts in place, so parts are built
  /// per symbol set to keep results independent of rendering order.
  NumberIcons numberIconsFor(
    String key,
    String symbolSet,
    SymbolMetadata metadata,
    SymbolColors colors,
    bool std2525,
    String monoColor,
    bool alternateMedal,
    String? edition,
  ) {
    final k = '$key,symbolSet:$symbolSet';
    final cached = _iconCache[k];
    if (cached != null) return cached;
    final parts = getIconParts(metadata, colors, std2525, monoColor, alternateMedal);
    final sId = <String, Object?>{};
    final m1 = <String, Object?>{};
    final m2 = <String, Object?>{};
    final bbox = <String, Object?>{};
    for (final f in numberIcons) {
      f(sId, m1, m2, bbox, symbolSet, parts, std2525, edition);
    }
    if (_iconCache.length >= _cacheLimit) _iconCache.clear();
    return _iconCache[k] = NumberIcons(sId, m1, m2, bbox, parts);
  }
}

/// The global milsymbol state, with the ported number SIDC modules registered.
final ms = Ms()..registerDefaults();

/// `ms._scale`: scales [instruction] around the octagon center. With
/// [nonScalingStroke] the stroke width is compensated; like milsymbol this
/// marks the given instructions in place.
JsObject msScale(num factor, Object? instruction, [bool nonScalingStroke = false]) {
  void recurse(Object? instruction) {
    if (instruction is List<Object?>) {
      for (final d in instruction) {
        if (d is Map<String, Object?>) {
          d['non_scaling_stroke'] = 1 / factor;
          if (d.containsKey('draw')) recurse(d['draw']);
        } else if (d is List<Object?>) {
          // A JS array accepts the property too (invisible except to for...in).
          setArrayProperty(d, 'non_scaling_stroke', 1 / factor);
          for (final e in d) {
            recurse(e);
          }
        } else if (d == null) {
          throw JsTypeError("Cannot set properties of undefined (setting 'non_scaling_stroke')");
        }
      }
    } else if (instruction is Map<String, Object?>) {
      instruction['non_scaling_stroke'] = 1 / factor;
    } else if (instruction == null) {
      throw JsTypeError("Cannot set properties of undefined (setting 'non_scaling_stroke')");
    }
  }

  if (nonScalingStroke) recurse(instruction);
  return {
    'type': 'translate',
    'x': 100 - factor * 100,
    'y': 100 - factor * 100,
    'draw': [
      {
        'type': 'scale',
        'factor': factor,
        'draw': [instruction],
      },
    ],
  };
}

/// `ms._translate`.
JsObject msTranslate(num x, num y, Object? instruction) => {
  'type': 'translate',
  'x': x,
  'y': y,
  'draw': [instruction],
};

/// `ms.outline`: a copy of [geom] drawn as a wide stroke in [color], used
/// as a halo below the symbol.
Object? msOutline(Object? geom, num outline, num stroke, Object? color) {
  Object? process(Object? geom) {
    if (geom is List<Object?>) {
      return [for (final g in forInValues(geom)) process(g)];
    }
    final clone = <String, Object?>{};
    if (geom is Map<String, Object?>) {
      for (final e in geom.entries) {
        if (e.key != 'fill' && e.key != 'fillopacity') clone[e.key] = e.value;
      }
    } else if (geom == null) {
      throw JsTypeError("Cannot read properties of undefined (reading 'type')");
    }
    final type = geom is Map<String, Object?> ? geom['type'] : null;
    if (type == 'translate' || type == 'rotate' || type == 'scale') {
      final draw = (geom as Map<String, Object?>)['draw'];
      clone['draw'] = [
        if (draw is List<Object?>)
          for (final d in forInValues(draw)) process(d)
        else if (draw is Map<String, Object?>)
          for (final d in draw.values) process(d),
      ];
    } else {
      final sw = clone['strokewidth'];
      clone['strokewidth'] = clone['stroke'] != false
          ? toNumber(truthy(sw) ? sw : stroke) + 2 * outline
          : 2 * outline;
      clone['stroke'] = color;
      clone['fill'] = false;
      clone['linecap'] = 'round';
    }
    return clone;
  }

  return process(geom);
}

/// Thrown where milsymbol itself would throw a JS TypeError.
class JsTypeError extends Error {
  JsTypeError(this.message);
  final String message;
  @override
  String toString() => 'TypeError: $message';
}
