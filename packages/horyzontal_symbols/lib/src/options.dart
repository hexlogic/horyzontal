// Ported from milsymbol src/ms/symbol.js (option and style defaults), MIT (c) Måns Beckman.

import 'color_mode.dart';
import 'js.dart';

/// Options of a symbol: text amplifiers and style, with milsymbol's names
/// and defaults.
///
/// Fields typed [Object] accept either a CSS color string or a [ColorMode]
/// (one color per affiliation), exactly like the JS options.
class SymbolOptions {
  const SymbolOptions({
    // Text amplifiers, field IDs of APP-6/2525 in brackets.
    this.quantity = '', // C
    this.reinforcedReduced = '', // F
    this.staffComments = '', // G
    this.additionalInformation = '', // H
    this.evaluationRating = '', // J
    this.combatEffectiveness = '', // K
    this.signatureEquipment = '', // L
    this.higherFormation = '', // M
    this.hostile = '', // N
    this.iffSif = '', // P
    this.direction, // Q, degrees
    this.sigint = '', // R2
    this.uniqueDesignation = '', // T
    this.type = '', // V
    this.dtg = '', // W
    this.altitudeDepth = '', // X
    this.location = '', // Y
    this.speed = '', // Z
    this.speedLeader = 0,
    this.specialHeadquarters = '', // AA
    this.country = '', // AC
    this.platformType = '', // AD
    this.equipmentTeardownTime = '', // AE
    this.commonIdentifier = '', // AF
    this.auxiliaryEquipmentIndicator = '', // AG
    this.headquartersElement = '', // AH
    this.installationComposition = '', // AI
    this.engagementBar = '', // AO
    this.engagementType = '', // TARGET, NON-TARGET or EXPIRED
    this.guardedUnit = '', // AQ
    this.specialDesignator = '', // AR
    this.stack,
    this.extra = const {},
    // Style.
    this.alternateMedal = false,
    this.civilianColor = true,
    this.colorMode = 'Light',
    this.fill = true,
    this.fillColor = '',
    this.fillOpacity = 1,
    this.fontfamily = 'Arial',
    this.frame = true,
    this.frameColor = '',
    this.hqStaffLength = 0,
    this.icon = true,
    this.iconColor = '',
    this.infoBackground = '',
    this.infoBackgroundFrame = '',
    this.infoColor = '',
    this.infoFields = true,
    this.infoOutlineColor = 'rgb(239, 239, 239)',
    this.infoOutlineWidth,
    this.infoSize = 40,
    this.monoColor = '',
    this.outlineColor = 'rgb(239, 239, 239)',
    this.outlineWidth = 0,
    this.padding = 0,
    this.simpleStatusModifier = false,
    this.size = 100,
    this.square = false,
    this.standard = '',
    this.strokeWidth = 4,
    this.styleFill = false,
  });

  /// From a JS-style options object, as passed to `new ms.Symbol(sidc, options)`.
  /// Unknown keys go to [extra]. `sidc`/`SIDC` keys are ignored, the SIDC is
  /// a separate argument of the symbol.
  factory SymbolOptions.fromJson(Map<String, Object?> json) {
    String s(String k) {
      final v = json[k];
      return v == null ? '' : jsString(v);
    }

    num n(String k, num d) {
      final v = json[k];
      return v == null ? d : (v is num ? v : toNumber(v));
    }

    bool b(String k, bool d) {
      final v = json[k];
      return v == null ? d : truthy(v);
    }

    Object c(String k, Object d) {
      final v = json[k];
      if (v == null) return d;
      if (v is Map<String, Object?>) return ColorMode.fromJson(v);
      return jsString(v);
    }

    final extra = <String, Object?>{
      for (final e in json.entries)
        if (!_knownKeys.contains(e.key)) e.key: e.value,
    };
    final dir = json['direction'];
    final iow = json['infoOutlineWidth'];
    final stack = json['stack'];
    return SymbolOptions(
      quantity: s('quantity'),
      reinforcedReduced: s('reinforcedReduced'),
      staffComments: s('staffComments'),
      additionalInformation: s('additionalInformation'),
      evaluationRating: s('evaluationRating'),
      combatEffectiveness: s('combatEffectiveness'),
      signatureEquipment: s('signatureEquipment'),
      higherFormation: s('higherFormation'),
      hostile: s('hostile'),
      iffSif: s('iffSif'),
      direction: dir == null || dir == '' ? null : (dir is num ? dir : toNumber(dir)),
      sigint: s('sigint'),
      uniqueDesignation: s('uniqueDesignation'),
      type: s('type'),
      dtg: s('dtg'),
      altitudeDepth: s('altitudeDepth'),
      location: s('location'),
      speed: s('speed'),
      speedLeader: n('speedLeader', 0),
      specialHeadquarters: s('specialHeadquarters'),
      country: s('country'),
      platformType: s('platformType'),
      equipmentTeardownTime: s('equipmentTeardownTime'),
      commonIdentifier: s('commonIdentifier'),
      auxiliaryEquipmentIndicator: s('auxiliaryEquipmentIndicator'),
      headquartersElement: s('headquartersElement'),
      installationComposition: s('installationComposition'),
      engagementBar: s('engagementBar'),
      engagementType: s('engagementType'),
      guardedUnit: s('guardedUnit'),
      specialDesignator: s('specialDesignator'),
      stack: stack == null ? null : (stack is num ? stack : toNumber(stack)),
      extra: extra,
      alternateMedal: b('alternateMedal', false),
      civilianColor: b('civilianColor', true),
      colorMode: c('colorMode', 'Light'),
      fill: b('fill', true),
      fillColor: s('fillColor'),
      fillOpacity: n('fillOpacity', 1),
      fontfamily: json['fontfamily'] == null ? 'Arial' : s('fontfamily'),
      frame: b('frame', true),
      frameColor: c('frameColor', ''),
      hqStaffLength: n('hqStaffLength', 0),
      icon: b('icon', true),
      iconColor: c('iconColor', ''),
      infoBackground: c('infoBackground', ''),
      infoBackgroundFrame: c('infoBackgroundFrame', ''),
      infoColor: c('infoColor', ''),
      infoFields: b('infoFields', true),
      infoOutlineColor: json['infoOutlineColor'] == null
          ? 'rgb(239, 239, 239)'
          : s('infoOutlineColor'),
      infoOutlineWidth: iow == null || iow == false ? null : (iow is num ? iow : toNumber(iow)),
      infoSize: n('infoSize', 40),
      monoColor: s('monoColor'),
      outlineColor: c('outlineColor', 'rgb(239, 239, 239)'),
      outlineWidth: n('outlineWidth', 0),
      padding: n('padding', 0),
      simpleStatusModifier: b('simpleStatusModifier', false),
      size: n('size', 100),
      square: b('square', false),
      standard: s('standard'),
      strokeWidth: n('strokeWidth', 4),
      styleFill: b('styleFill', false),
    );
  }

  final String quantity,
      reinforcedReduced,
      staffComments,
      additionalInformation,
      evaluationRating,
      combatEffectiveness,
      signatureEquipment,
      higherFormation,
      hostile,
      iffSif,
      sigint,
      uniqueDesignation,
      type,
      dtg,
      altitudeDepth,
      location,
      speed,
      specialHeadquarters,
      country,
      platformType,
      equipmentTeardownTime,
      commonIdentifier,
      auxiliaryEquipmentIndicator,
      headquartersElement,
      installationComposition,
      engagementBar,
      engagementType,
      guardedUnit,
      specialDesignator;

  /// Direction of movement in degrees, `null` for none.
  final num? direction;

  /// Length of the speed leader in pixels; 0 draws a direction arrow instead.
  final num speedLeader;

  /// Number of stacked frames behind the symbol, `null` for none.
  final num? stack;

  /// Options milsymbol does not define itself (for example label keys of
  /// control measures); looked up by name like the JS options object.
  final Map<String, Object?> extra;

  /// Alternate MEDAL icons for sea mines (2525D).
  final bool alternateMedal;

  /// Use the civilian purple of 2525 for civilian symbols.
  final bool civilianColor;

  /// `Light`, `Medium`, `Dark` (or another registered mode name), or a [ColorMode].
  final Object colorMode;

  final bool fill;

  /// Overrides the frame fill color when not empty.
  final String fillColor;
  final num fillOpacity;
  final String fontfamily;
  final bool frame;

  /// A [ColorMode] overrides the frame colors; a string is ignored, as in milsymbol.
  final Object frameColor;

  /// Length of the headquarters staff, 0 for the global default.
  final num hqStaffLength;
  final bool icon;

  /// A [ColorMode] overrides the icon colors; a string is ignored, as in milsymbol.
  final Object iconColor;
  final Object infoBackground;
  final Object infoBackgroundFrame;
  final Object infoColor;
  final bool infoFields;
  final String infoOutlineColor;

  /// Width of the text outline, `null` to follow [outlineWidth] (JS `false`).
  final num? infoOutlineWidth;
  final num infoSize;

  /// Draw the whole symbol in this single color when not empty.
  final String monoColor;
  final Object outlineColor;
  final num outlineWidth;
  final num padding;
  final bool simpleStatusModifier;

  /// Size of the octagon in pixels (the L of the standards).
  final num size;
  final bool square;

  /// `APP6` or `2525` to override the global standard, empty for the default.
  final String standard;
  final num strokeWidth;
  final bool styleFill;

  /// Text option keys of milsymbol's options object (style keys excluded).
  static const optionKeys = [
    'quantity',
    'reinforcedReduced',
    'staffComments',
    'additionalInformation',
    'evaluationRating',
    'combatEffectiveness',
    'signatureEquipment',
    'higherFormation',
    'hostile',
    'iffSif',
    'direction',
    'sigint',
    'uniqueDesignation',
    'type',
    'dtg',
    'altitudeDepth',
    'location',
    'speed',
    'speedLeader',
    'specialHeadquarters',
    'country',
    'platformType',
    'equipmentTeardownTime',
    'commonIdentifier',
    'auxiliaryEquipmentIndicator',
    'headquartersElement',
    'installationComposition',
    'engagementBar',
    'engagementType',
    'guardedUnit',
    'specialDesignator',
  ];

  static const styleKeys = [
    'alternateMedal',
    'civilianColor',
    'colorMode',
    'fill',
    'fillColor',
    'fillOpacity',
    'fontfamily',
    'frame',
    'frameColor',
    'hqStaffLength',
    'icon',
    'iconColor',
    'infoBackground',
    'infoBackgroundFrame',
    'infoColor',
    'infoFields',
    'infoOutlineColor',
    'infoOutlineWidth',
    'infoSize',
    'monoColor',
    'outlineColor',
    'outlineWidth',
    'padding',
    'simpleStatusModifier',
    'size',
    'square',
    'standard',
    'strokeWidth',
    'styleFill',
  ];

  static final _knownKeys = {...optionKeys, ...styleKeys, 'stack', 'sidc', 'SIDC'};

  /// Whether the JS options object of the symbol would have own property [key].
  bool hasOption(String key) =>
      optionKeys.contains(key) ||
      key == 'sidc' ||
      (key == 'stack' && stack != null) ||
      extra.containsKey(key);

  /// Option value by its JS name (text amplifiers and [extra]).
  Object? operator [](String key) => switch (key) {
    'quantity' => quantity,
    'reinforcedReduced' => reinforcedReduced,
    'staffComments' => staffComments,
    'additionalInformation' => additionalInformation,
    'evaluationRating' => evaluationRating,
    'combatEffectiveness' => combatEffectiveness,
    'signatureEquipment' => signatureEquipment,
    'higherFormation' => higherFormation,
    'hostile' => hostile,
    'iffSif' => iffSif,
    'direction' => direction,
    'sigint' => sigint,
    'uniqueDesignation' => uniqueDesignation,
    'type' => type,
    'dtg' => dtg,
    'altitudeDepth' => altitudeDepth,
    'location' => location,
    'speed' => speed,
    'speedLeader' => speedLeader,
    'specialHeadquarters' => specialHeadquarters,
    'country' => country,
    'platformType' => platformType,
    'equipmentTeardownTime' => equipmentTeardownTime,
    'commonIdentifier' => commonIdentifier,
    'auxiliaryEquipmentIndicator' => auxiliaryEquipmentIndicator,
    'headquartersElement' => headquartersElement,
    'installationComposition' => installationComposition,
    'engagementBar' => engagementBar,
    'engagementType' => engagementType,
    'guardedUnit' => guardedUnit,
    'specialDesignator' => specialDesignator,
    'stack' => stack,
    _ => extra[key],
  };

  /// JS-style options object (non-default values only).
  Map<String, Object?> toJson() {
    const d = SymbolOptions();
    Object? enc(Object? v) => v is ColorMode ? v.toJson() : v;
    return {
      for (final k in [...optionKeys, 'stack'])
        if (this[k] != d[k]) k: this[k],
      for (final k in styleKeys)
        if (!_sameStyle(style(k), d.style(k))) k: enc(style(k)),
      ...extra,
    };
  }

  static bool _sameStyle(Object? a, Object? b) => a is ColorMode || b is ColorMode ? false : a == b;

  /// Style value by its JS name.
  Object? style(String key) => switch (key) {
    'alternateMedal' => alternateMedal,
    'civilianColor' => civilianColor,
    'colorMode' => colorMode,
    'fill' => fill,
    'fillColor' => fillColor,
    'fillOpacity' => fillOpacity,
    'fontfamily' => fontfamily,
    'frame' => frame,
    'frameColor' => frameColor,
    'hqStaffLength' => hqStaffLength,
    'icon' => icon,
    'iconColor' => iconColor,
    'infoBackground' => infoBackground,
    'infoBackgroundFrame' => infoBackgroundFrame,
    'infoColor' => infoColor,
    'infoFields' => infoFields,
    'infoOutlineColor' => infoOutlineColor,
    'infoOutlineWidth' => infoOutlineWidth ?? false,
    'infoSize' => infoSize,
    'monoColor' => monoColor,
    'outlineColor' => outlineColor,
    'outlineWidth' => outlineWidth,
    'padding' => padding,
    'simpleStatusModifier' => simpleStatusModifier,
    'size' => size,
    'square' => square,
    'standard' => standard,
    'strokeWidth' => strokeWidth,
    'styleFill' => styleFill,
    _ => null,
  };
}
