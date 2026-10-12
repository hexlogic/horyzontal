/// Level of an entry in the entity hierarchy of a symbol set (positions 11-16 of a SIDC).
enum EntityLevel {
  /// Positions 11-12, e.g. `120000` "Movement and Maneuver".
  entity,

  /// Positions 13-14, e.g. `121100` "Infantry".
  type,

  /// Positions 15-16, e.g. `121102` "Armored/Mechanized/Tracked".
  subtype,
}

/// A symbol set (positions 5-6 of a SIDC).
class SymbolSet {
  const SymbolSet(this.code, this.nameUk, this.nameEn);

  /// Two-digit code, e.g. `10`.
  final String code;
  final String nameUk;
  final String nameEn;

  @override
  String toString() => 'SymbolSet($code $nameEn)';
}

/// An entity, entity type or entity subtype of a symbol set.
class SymbolEntity {
  const SymbolEntity({
    required this.setCode,
    required this.code,
    required this.nameUk,
    required this.nameEn,
    required this.parentCode,
    required this.level,
    this.remarks,
    this.aliases = const [],
  });

  /// Two-digit symbol set code.
  final String setCode;

  /// Six-digit entity code (positions 11-16), e.g. `121100`.
  final String code;

  /// Ukrainian name. It is meant to be read under its parent in a picker, so a subtype may
  /// omit what the parent already says ("Коло" under "Район вільного вогню").
  final String nameUk;

  /// English name as in MIL-STD-2525D / JMSML.
  final String nameEn;

  /// Code of the entity type or entity this entry belongs to, `null` for a top-level entity.
  final String? parentCode;

  final EntityLevel level;

  /// Notes from the source tables (English), e.g. "Reserved for hierarchical purposes.".
  final String? remarks;

  /// Extra search terms: abbreviations and colloquial names.
  final List<String> aliases;

  @override
  String toString() => 'SymbolEntity($setCode:$code $nameEn)';
}

/// A sector 1 (top) or sector 2 (bottom) icon modifier of a symbol set
/// (positions 17-18 and 19-20 of a SIDC).
class SymbolModifier {
  const SymbolModifier({
    required this.setCode,
    required this.sector,
    required this.code,
    required this.nameUk,
    required this.nameEn,
    this.category,
    this.remarks,
  });

  final String setCode;

  /// 1 or 2.
  final int sector;

  /// Two-digit code.
  final String code;
  final String nameUk;
  final String nameEn;

  /// Modifier category from the source tables (English), e.g. "Mobility", "Capability".
  final String? category;
  final String? remarks;

  @override
  String toString() => 'SymbolModifier($setCode:m$sector:$code $nameEn)';
}

/// A special entity subtype: positions 15-16 that apply to any entity type of the set
/// (land units: 95 headquarters element, 96-98 support echelons).
class SpecialSubtype {
  const SpecialSubtype(this.setCode, this.code, this.nameUk, this.nameEn);

  final String setCode;

  /// Two-digit code, e.g. `95`.
  final String code;
  final String nameUk;
  final String nameEn;

  @override
  String toString() => 'SpecialSubtype($setCode:xxxx$code $nameEn)';
}

/// A one-digit SIDC field value: context, standard identity, status or HQ/TF/dummy.
class SidcValue {
  const SidcValue(this.code, this.nameUk, this.nameEn);

  final String code;
  final String nameUk;
  final String nameEn;

  @override
  String toString() => 'SidcValue($code $nameEn)';
}

/// Echelon or mobility amplifier (positions 9-10 of a SIDC). Position 9 selects the group
/// (1-2 echelon, 3-5 mobility on land, snow and water, 6 towed sonar array).
class SidcAmplifier {
  const SidcAmplifier({
    required this.code,
    required this.nameUk,
    required this.nameEn,
    required this.groupUk,
    required this.groupEn,
  });

  /// Two-digit code, e.g. `16` (battalion).
  final String code;
  final String nameUk;
  final String nameEn;
  final String groupUk;
  final String groupEn;

  /// Group digit (position 9).
  String get group => code[0];

  bool get isEchelon => group == '1' || group == '2';

  bool get isMobility => group == '3' || group == '4' || group == '5';

  bool get isTowedArray => group == '6';

  @override
  String toString() => 'SidcAmplifier($code $nameEn)';
}
