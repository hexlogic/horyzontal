import 'data.g.dart';
import 'model.dart';
import 'sidc.dart';

/// APP-6D / MIL-STD-2525D number-SIDC symbol catalogue with English and Ukrainian names.
///
/// The data is compiled in (see `tools/symbol-catalog`); indexes are built on first use.
class SymbolCatalog {
  SymbolCatalog._();

  /// The shared catalogue.
  static final SymbolCatalog instance = SymbolCatalog._();

  factory SymbolCatalog() => instance;

  // ---- base tables ----

  /// Symbol sets in picker order.
  late final List<SymbolSet> sets = List.unmodifiable([
    for (final (code, en, uk) in symbolSetData) SymbolSet(code, uk, en),
  ]);

  late final Map<String, SymbolSet> _setIndex = {for (final s in sets) s.code: s};

  /// Context values (position 3).
  late final List<SidcValue> contexts = _values(contextData);

  /// Standard identities (position 4).
  late final List<SidcValue> standardIdentities = _values(identityData);

  /// Statuses (position 7).
  late final List<SidcValue> statuses = _values(statusData);

  /// Headquarters / task force / dummy values (position 8).
  late final List<SidcValue> hqTfDummies = _values(hqtfdData);

  /// Echelon and mobility amplifiers (positions 9-10), including `00` (none).
  late final List<SidcAmplifier> amplifiers = List.unmodifiable([
    for (final (code, groupEn, en, groupUk, uk) in amplifierData)
      SidcAmplifier(code: code, nameUk: uk, nameEn: en, groupUk: groupUk, groupEn: groupEn),
  ]);

  /// Echelon amplifiers only (team/crew ... command).
  List<SidcAmplifier> get echelons => [
    for (final a in amplifiers)
      if (a.isEchelon) a,
  ];

  /// Mobility amplifiers only (land, snow, water).
  List<SidcAmplifier> get mobilities => [
    for (final a in amplifiers)
      if (a.isMobility) a,
  ];

  static List<SidcValue> _values(List<(String, String, String)> rows) =>
      List.unmodifiable([for (final (code, en, uk) in rows) SidcValue(code, uk, en)]);

  SymbolSet? symbolSet(String code) => _setIndex[code];

  SidcValue? context(String code) => _find(contexts, code);

  SidcValue? standardIdentity(String code) => _find(standardIdentities, code);

  SidcValue? status(String code) => _find(statuses, code);

  SidcValue? hqTfDummy(String code) => _find(hqTfDummies, code);

  SidcAmplifier? amplifier(String code) {
    for (final a in amplifiers) {
      if (a.code == code) return a;
    }
    return null;
  }

  static SidcValue? _find(List<SidcValue> values, String code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }

  // ---- entities ----

  final Map<String, List<SymbolEntity>> _entities = {};
  final Map<String, Map<String, SymbolEntity>> _entityIndex = {};
  final Map<String, Map<String?, List<SymbolEntity>>> _childIndex = {};

  /// All entities of a set in source order (entities, each followed by its types and
  /// subtypes). Empty for an unknown set.
  List<SymbolEntity> entities(String setCode) => _entities.putIfAbsent(setCode, () {
    final rows = entityData[setCode];
    if (rows == null) return const [];
    return List.unmodifiable([
      for (final (code, parent, level, en, uk, remarks) in rows)
        SymbolEntity(
          setCode: setCode,
          code: code,
          nameUk: uk,
          nameEn: en,
          parentCode: parent,
          level: EntityLevel.values[level],
          remarks: remarks,
          aliases: aliasData['$setCode:$code'] ?? const [],
        ),
    ]);
  });

  /// The entity with the six-digit [code], or `null`.
  SymbolEntity? entity(String setCode, String code) =>
      _entityIndex.putIfAbsent(setCode, () => {for (final e in entities(setCode)) e.code: e})[code];

  /// Direct children of [code]; with `null` the top-level entities of the set.
  List<SymbolEntity> children(String setCode, [String? code]) {
    final index = _childIndex.putIfAbsent(setCode, () {
      final map = <String?, List<SymbolEntity>>{};
      for (final e in entities(setCode)) {
        (map[e.parentCode] ??= []).add(e);
      }
      return map;
    });
    return List.unmodifiable(index[code] ?? const <SymbolEntity>[]);
  }

  /// The chain from the top-level entity down to [code], e.g. Movement and Maneuver ›
  /// Infantry › Armored/Mechanized/Tracked. Empty if [code] is unknown.
  List<SymbolEntity> path(String setCode, String code) {
    final out = <SymbolEntity>[];
    for (var e = entity(setCode, code); e != null;) {
      out.insert(0, e);
      final parent = e.parentCode;
      e = parent == null ? null : entity(setCode, parent);
    }
    return out;
  }

  /// Special subtypes of the set (positions 15-16 valid with any entity type), e.g. land
  /// unit `95` headquarters element.
  List<SpecialSubtype> specialSubtypes(String setCode) => List.unmodifiable([
    for (final (code, en, uk) in specialSubtypeData[setCode] ?? const <(String, String, String)>[])
      SpecialSubtype(setCode, code, uk, en),
  ]);

  // ---- modifiers ----

  final Map<String, List<SymbolModifier>> _modifiers = {};

  /// Sector 1 or 2 modifiers of a set, including `00`. Empty if the set has none.
  List<SymbolModifier> modifiers(String setCode, int sector) =>
      _modifiers.putIfAbsent('$setCode:$sector', () {
        final rows = modifierData[setCode]?[sector];
        if (rows == null) return const [];
        return List.unmodifiable([
          for (final (code, en, uk, category, remarks) in rows)
            SymbolModifier(
              setCode: setCode,
              sector: sector,
              code: code,
              nameUk: uk,
              nameEn: en,
              category: category,
              remarks: remarks,
            ),
        ]);
      });

  SymbolModifier? modifier(String setCode, int sector, String code) {
    for (final m in modifiers(setCode, sector)) {
      if (m.code == code) return m;
    }
    return null;
  }

  // ---- search ----

  late final List<(SymbolEntity, List<String>)> _searchIndex = [
    for (final s in sets)
      for (final e in entities(s.code))
        (
          e,
          [
            for (final n in [e.nameUk, e.nameEn, ...e.aliases]) normalize(n),
          ],
        ),
  ];

  /// Lower-cases and unifies apostrophes (’ ' ʼ ` ´ ‘) so that "зв'язок" finds "Зв’язок".
  static String normalize(String text) => text.toLowerCase().replaceAll(RegExp('[’ʼ‘`´]'), "'");

  static final _wordChar = RegExp(r"[\p{L}\p{N}']", unicode: true);

  /// Entities whose Ukrainian or English name (or alias) contains [query], case-insensitively.
  ///
  /// Ranked: names starting with the query first, then names containing it as a whole word,
  /// then names with a word starting with it, then any substring. Within a rank shorter
  /// Ukrainian names come first, then catalogue order. [setCode] limits the search to one set.
  List<SymbolEntity> search(String query, {String? setCode, int? limit}) {
    final q = normalize(query.trim());
    if (q.isEmpty) return const [];
    final hits = <(int, int, SymbolEntity)>[];
    var order = 0;
    for (final (e, names) in _searchIndex) {
      order++;
      if (setCode != null && e.setCode != setCode) continue;
      var best = 4;
      for (final n in names) {
        final r = _rank(n, q);
        if (r < best) best = r;
        if (best == 0) break;
      }
      if (best < 4) hits.add((best, order, e));
    }
    hits.sort((a, b) {
      var c = a.$1.compareTo(b.$1);
      if (c != 0) return c;
      c = a.$3.nameUk.length.compareTo(b.$3.nameUk.length);
      if (c != 0) return c;
      return a.$2.compareTo(b.$2);
    });
    final out = [for (final h in hits) h.$3];
    return limit == null || out.length <= limit ? out : out.sublist(0, limit);
  }

  /// 0 prefix of the name, 1 whole word, 2 word prefix, 3 substring, 4 no match.
  static int _rank(String name, String q) {
    var i = name.indexOf(q);
    if (i < 0) return 4;
    if (i == 0) return 0;
    var best = 3;
    while (i >= 0) {
      final startsWord = !_wordChar.hasMatch(name[i - 1]);
      if (startsWord) {
        final end = i + q.length;
        final endsWord = end == name.length || !_wordChar.hasMatch(name[end]);
        if (endsWord) return 1;
        best = 2;
      }
      i = name.indexOf(q, i + 1);
    }
    return best;
  }

  // ---- describe ----

  /// A Ukrainian, human-readable breakdown of a 20- or 30-digit SIDC, one field per line.
  ///
  /// Throws [FormatException] if [sidc] is not a number SIDC. Codes missing from the
  /// catalogue are shown as "невідомий код".
  String describe(String sidc) {
    final s = Sidc.parse(sidc);
    final lines = <String>[];
    String name(String? uk, String code) => uk ?? 'невідомий код $code';

    final set = symbolSet(s.symbolSet);
    lines.add('Набір: ${name(set?.nameUk, s.symbolSet)}');
    lines.add('Належність: ${name(standardIdentity(s.identity)?.nameUk, s.identity)}');
    if (s.context != '0') {
      lines.add('Контекст: ${name(context(s.context)?.nameUk, s.context)}');
    }
    lines.add('Знак: ${_entityText(s)}');
    lines.add('Статус: ${name(status(s.status)?.nameUk, s.status)}');
    if (s.hqTfDummy != '0') {
      lines.add(
        'Штаб / тактична група / хибний: '
        '${name(hqTfDummy(s.hqTfDummy)?.nameUk, s.hqTfDummy)}',
      );
    }
    if (s.amplifier != '00') {
      final a = amplifier(s.amplifier);
      final label = a == null
          ? 'Ешелон / рухомість'
          : a.isEchelon
          ? 'Ешелон'
          : a.isMobility
          ? 'Рухомість'
          : a.groupUk;
      lines.add('$label: ${name(a?.nameUk, s.amplifier)}');
    }
    if (s.modifier1 != '00') {
      lines.add(
        'Модифікатор 1: ${name(modifier(s.symbolSet, 1, s.modifier1)?.nameUk, s.modifier1)}',
      );
    }
    if (s.modifier2 != '00') {
      lines.add(
        'Модифікатор 2: ${name(modifier(s.symbolSet, 2, s.modifier2)?.nameUk, s.modifier2)}',
      );
    }
    if (s.version != Sidc.versionApp6D) lines.add('Версія: ${s.version}');
    if (s.extension.isNotEmpty) lines.add('Позиції 21–30: ${s.extension}');
    return lines.join('\n');
  }

  String _entityText(Sidc s) {
    final p = path(s.symbolSet, s.entity);
    if (p.isNotEmpty) return p.map((e) => e.nameUk).join(' › ');
    // A special subtype (e.g. land unit 95) attached to an entity type.
    for (final sp in specialSubtypes(s.symbolSet)) {
      if (sp.code == s.entitySubtypeCode) {
        final base = path(s.symbolSet, '${s.entityCode}${s.entityTypeCode}00');
        if (base.isNotEmpty) return '${base.map((e) => e.nameUk).join(' › ')} › ${sp.nameUk}';
      }
    }
    return 'невідомий код ${s.entity}';
  }
}
