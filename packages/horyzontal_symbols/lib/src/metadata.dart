// Ported from milsymbol src/ms/symbol/getmetadata.js, MIT (c) Måns Beckman.

import 'bbox.dart';
import 'js.dart';
import 'ms.dart';
import 'numbersidc/metadata.dart';
import 'symbol.dart';
import 'symbol_geometries.dart';

/// What milsymbol knows about a symbol after parsing its SIDC.
///
/// Field names follow milsymbol (including its spelling of
/// `baseAffilation`). Nullable strings are `undefined` in JS, for example
/// [affiliation] for an unknown standard identity digit.
class SymbolMetadata {
  SymbolMetadata({required this.fill, required this.frame, required this.std2525});

  /// Activity/event symbol set.
  bool activity = false;

  /// Affiliation the symbol is shown as: Friend, Hostile, Neutral, Unknown.
  String? affiliation = 'undefined';

  /// Affiliation the symbol belongs to.
  String? baseAffilation = '';

  /// Dimension the symbol belongs to: Air, Ground, Sea, Subsurface.
  String baseDimension = '';

  /// Frame geometry for the dimension and affiliation.
  SymbolGeometry baseGeometry = SymbolGeometry(null, BBox());
  bool civilian = false;

  /// FullyCapable, Damaged, Destroyed or FullToCapacity, empty for none.
  String? condition = '';

  /// Reality, Exercise or Simulation.
  String? context = '';

  /// Dimension the symbol is shown as (frame shape).
  String dimension = 'undefined';
  bool dimensionUnknown = false;

  /// Echelon name such as `Platoon/detachment`, empty for none.
  String? echelon = '';
  bool faker = false;

  /// Spelling of milsymbol, always false; see [feintDummy].
  bool fenintDummy = false;
  bool fill;
  bool frame;

  /// The 10 digits of the entity, entity type, subtype and modifiers.
  String functionid = '';
  bool headquarters = false;
  bool installation = false;
  bool joker = false;

  /// Mobility amplifier such as `Tracked`, empty for none, `null` for an
  /// unknown code (the symbol is then invalid).
  String? mobility = '';

  /// Dash array for planned/anticipated or pending frames, empty for solid.
  String notpresent = '';
  bool numberSIDC = false;
  bool space = false;
  bool std2525;
  bool taskForce = false;
  bool unit = false;

  /// `D` for versions 10-12, `E` for 13-14.
  String? edition;
  bool suspect = false;
  bool feintDummy = false;
  bool landequipment = false;
  bool controlMeasure = false;
  bool cyberspace = false;
  bool dismounted = false;

  /// Leader/Deputy Individual for dismounted individuals.
  String? leadership;

  /// Bottom of the icon when unframed (not set for number SIDCs).
  num? iconBottom;
  bool unframed = false;

  /// Sector 1 modifier code (3 digits, first digit from SIDC position 21).
  String modifier1 = '';

  /// Sector 2 modifier code (3 digits, first digit from SIDC position 22).
  String modifier2 = '';

  /// JS-style map with milsymbol's keys (`STD2525`, `_modifier1`, ...).
  Map<String, Object?> toJson() => {
    'activity': activity,
    'affiliation': affiliation,
    'baseAffilation': baseAffilation,
    'baseDimension': baseDimension,
    'civilian': civilian,
    'condition': condition,
    'context': context,
    'dimension': dimension,
    'dimensionUnknown': dimensionUnknown,
    'echelon': echelon,
    'faker': faker,
    'fenintDummy': fenintDummy,
    'fill': fill,
    'frame': frame,
    'functionid': functionid,
    'headquarters': headquarters,
    'installation': installation,
    'joker': joker,
    'mobility': mobility,
    'notpresent': notpresent,
    'numberSIDC': numberSIDC,
    'space': space,
    'STD2525': std2525,
    'taskForce': taskForce,
    'unit': unit,
    'edition': edition,
    'suspect': suspect,
    '_modifier1': modifier1,
    '_modifier2': modifier2,
    'landequipment': landequipment,
    'controlMeasure': controlMeasure,
    'cyberspace': cyberspace,
    'dismounted': dismounted,
    'feintDummy': feintDummy,
    'leadership': leadership,
    'iconBottom': iconBottom,
    'unframed': unframed,
  };
}

/// Lookup tables shared by the metadata functions.
class MetadataMapping {
  const MetadataMapping();
  List<String> get context => const ['Reality', 'Exercise', 'Simulation'];
  List<String> get status => const [
    'Present',
    'Planned',
    'FullyCapable',
    'Damaged',
    'Destroyed',
    'FullToCapacity',
  ];
  Map<String, String> get echelonMobility => const {
    '11': 'Team/Crew',
    '12': 'Squad',
    '13': 'Section',
    '14': 'Platoon/detachment',
    '15': 'Company/battery/troop',
    '16': 'Battalion/squadron',
    '17': 'Regiment/group',
    '18': 'Brigade',
    '21': 'Division',
    '22': 'Corps/MEF',
    '23': 'Army',
    '24': 'Army Group/front',
    '25': 'Region/Theater',
    '26': 'Command',
    '31': 'Wheeled limited cross country',
    '32': 'Wheeled cross country',
    '33': 'Tracked',
    '34': 'Wheeled and tracked combination',
    '35': 'Towed',
    '36': 'Rail',
    '37': 'Pack animals',
    '41': 'Over snow (prime mover)',
    '42': 'Sled',
    '51': 'Barge',
    '52': 'Amphibious',
    '61': 'Short towed array',
    '62': 'Long towed Array',
    '71': 'Leader Individual',
    '72': 'Deputy Individual',
  };
  List<String> get affiliation => const ['Hostile', 'Friend', 'Neutral', 'Unknown'];
  List<String> get dimension => const ['Air', 'Ground', 'Sea', 'Subsurface'];
}

/// `Symbol.prototype.getMetadata`; also normalizes `symbol.sidc` like JS does
/// with `this.options.sidc`.
SymbolMetadata getMetadata(MilSymbol symbol) {
  final style = symbol.options;
  var metadata = SymbolMetadata(fill: style.fill, frame: style.frame, std2525: ms.std2525);
  const mapping = MetadataMapping();
  metadata.context = mapping.context[0];

  if (truthy(style.standard)) {
    metadata.std2525 = style.standard == 'APP6' ? false : true;
  }
  if (style.monoColor != '') {
    metadata.fill = false;
  }
  symbol.sidc = symbol.sidc.replaceAll('*', '-').replaceAll(' ', '');

  metadata.numberSIDC = !jsIsNaN(substr(symbol.sidc, 0, 2));
  if (metadata.numberSIDC) {
    metadata = numberMetadata(symbol, ms, metadata, mapping);
  }
  // Letter based SIDCs are not ported: their metadata stays at the defaults,
  // as in milsymbol when no letter SIDC module is loaded.

  final g = symbolGeometries['${metadata.dimension}${jsString(metadata.affiliation)}'];
  if (g != null) {
    metadata.baseGeometry = g;
  } else {
    metadata.baseGeometry = SymbolGeometry(metadata.baseGeometry.g, BBox());
  }
  // If both frame and icon is turned off we should just have a position marker
  if (!style.frame && !style.icon) {
    metadata.baseGeometry = symbolGeometries['PositionMarker']!;
  }
  return metadata;
}
