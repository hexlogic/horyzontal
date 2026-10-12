/// A number SIDC (symbol identification code) of APP-6D / MIL-STD-2525D.
///
/// Layout of the 20 digits (1-based positions):
///
/// | Positions | Field |
/// | --- | --- |
/// | 1-2 | version (`10` = APP-6D / 2525D) |
/// | 3 | context (0 reality, 1 exercise, 2 simulation) |
/// | 4 | standard identity (0 pending ... 6 hostile) |
/// | 5-6 | symbol set |
/// | 7 | status |
/// | 8 | headquarters / task force / dummy |
/// | 9-10 | echelon or mobility amplifier |
/// | 11-16 | entity, entity type, entity subtype |
/// | 17-18 | sector 1 modifier |
/// | 19-20 | sector 2 modifier |
///
/// A 30-digit SIDC carries ten more digits (21-30). They are kept verbatim in [extension] and
/// not interpreted here.
///
/// The value is immutable; the `with...` methods return modified copies.
class Sidc {
  /// Creates a SIDC from field values. Every field must consist of digits and have the width
  /// given in the table above; [extension] is empty or ten digits.
  Sidc({
    this.version = versionApp6D,
    this.context = '0',
    this.identity = '3',
    this.symbolSet = '10',
    this.status = '0',
    this.hqTfDummy = '0',
    this.amplifier = '00',
    this.entity = '000000',
    this.modifier1 = '00',
    this.modifier2 = '00',
    this.extension = '',
  }) {
    _check(version, 2, 'version');
    _check(context, 1, 'context');
    _check(identity, 1, 'identity');
    _check(symbolSet, 2, 'symbolSet');
    _check(status, 1, 'status');
    _check(hqTfDummy, 1, 'hqTfDummy');
    _check(amplifier, 2, 'amplifier');
    _check(entity, 6, 'entity');
    _check(modifier1, 2, 'modifier1');
    _check(modifier2, 2, 'modifier2');
    if (extension.isNotEmpty) _check(extension, 10, 'extension');
  }

  /// Parses a 20- or 30-digit SIDC. Spaces are ignored.
  factory Sidc.parse(String text) {
    final s = text.replaceAll(' ', '');
    if ((s.length != 20 && s.length != 30) || !_digits.hasMatch(s)) {
      throw FormatException('A number SIDC has 20 or 30 digits', text);
    }
    return Sidc(
      version: s.substring(0, 2),
      context: s.substring(2, 3),
      identity: s.substring(3, 4),
      symbolSet: s.substring(4, 6),
      status: s.substring(6, 7),
      hqTfDummy: s.substring(7, 8),
      amplifier: s.substring(8, 10),
      entity: s.substring(10, 16),
      modifier1: s.substring(16, 18),
      modifier2: s.substring(18, 20),
      extension: s.length == 30 ? s.substring(20) : '',
    );
  }

  /// Like [Sidc.parse], but returns `null` for malformed input.
  static Sidc? tryParse(String text) {
    try {
      return Sidc.parse(text);
    } on FormatException {
      return null;
    }
  }

  /// Version digits of APP-6D (MIL-STD-2525D), the default for new symbols. This is the only
  /// version the JMSML tables define.
  static const versionApp6D = '10';

  static final _digits = RegExp(r'^[0-9]+$');

  static void _check(String value, int width, String name) {
    if (value.length != width || !_digits.hasMatch(value)) {
      throw ArgumentError.value(value, name, 'must be $width digit(s)');
    }
  }

  final String version;
  final String context;
  final String identity;
  final String symbolSet;
  final String status;
  final String hqTfDummy;
  final String amplifier;
  final String entity;
  final String modifier1;
  final String modifier2;

  /// Positions 21-30 of a 30-digit SIDC, empty for a 20-digit one.
  final String extension;

  /// Positions 11-12.
  String get entityCode => entity.substring(0, 2);

  /// Positions 13-14.
  String get entityTypeCode => entity.substring(2, 4);

  /// Positions 15-16.
  String get entitySubtypeCode => entity.substring(4, 6);

  Sidc copyWith({
    String? version,
    String? context,
    String? identity,
    String? symbolSet,
    String? status,
    String? hqTfDummy,
    String? amplifier,
    String? entity,
    String? modifier1,
    String? modifier2,
    String? extension,
  }) => Sidc(
    version: version ?? this.version,
    context: context ?? this.context,
    identity: identity ?? this.identity,
    symbolSet: symbolSet ?? this.symbolSet,
    status: status ?? this.status,
    hqTfDummy: hqTfDummy ?? this.hqTfDummy,
    amplifier: amplifier ?? this.amplifier,
    entity: entity ?? this.entity,
    modifier1: modifier1 ?? this.modifier1,
    modifier2: modifier2 ?? this.modifier2,
    extension: extension ?? this.extension,
  );

  Sidc withVersion(String value) => copyWith(version: value);

  Sidc withContext(String value) => copyWith(context: value);

  Sidc withIdentity(String value) => copyWith(identity: value);

  /// Changes the symbol set. Entity and modifier codes are set-specific, so by default they
  /// are reset to zeros; pass [keepEntity] to keep them.
  Sidc withSymbolSet(String value, {bool keepEntity = false}) => keepEntity
      ? copyWith(symbolSet: value)
      : copyWith(symbolSet: value, entity: '000000', modifier1: '00', modifier2: '00');

  Sidc withStatus(String value) => copyWith(status: value);

  Sidc withHqTfDummy(String value) => copyWith(hqTfDummy: value);

  Sidc withAmplifier(String value) => copyWith(amplifier: value);

  Sidc withEntity(String value) => copyWith(entity: value);

  Sidc withModifier1(String value) => copyWith(modifier1: value);

  Sidc withModifier2(String value) => copyWith(modifier2: value);

  Sidc withExtension(String value) => copyWith(extension: value);

  /// The 20 digits (30 with [extension]).
  @override
  String toString() =>
      '$version$context$identity$symbolSet$status$hqTfDummy$amplifier$entity'
      '$modifier1$modifier2$extension';

  @override
  bool operator ==(Object other) => other is Sidc && other.toString() == toString();

  @override
  int get hashCode => toString().hashCode;
}
