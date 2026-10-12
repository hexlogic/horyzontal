import 'package:horyzontal_symbols/catalog.dart';
import 'package:test/test.dart';

/// Entity counts per set as listed in JMSML instance/*.xml (commit 094e764).
const _entityCounts = {
  '01': 52,
  '02': 2,
  '05': 35,
  '06': 2,
  '10': 198,
  '11': 12,
  '15': 223,
  '20': 129,
  '25': 603,
  '30': 94,
  '35': 21,
  '36': 66,
  '40': 152,
  '50': 5,
  '51': 5,
  '52': 5,
  '53': 5,
  '54': 5,
  '60': 51,
};

/// Sector 1 and sector 2 modifier counts per set, same source.
const _modifierCounts = {
  '01': (40, 12),
  '02': (9, 17),
  '05': (7, 5),
  '06': (4, 13),
  '10': (79, 58),
  '11': (25, 2),
  '15': (10, 0),
  '20': (14, 9),
  '25': (0, 0),
  '30': (24, 16),
  '35': (21, 17),
  '36': (0, 0),
  '40': (19, 0),
  '50': (32, 0),
  '51': (55, 0),
  '52': (53, 0),
  '53': (49, 0),
  '54': (38, 0),
  '60': (0, 0),
};

final _cyrillic = RegExp('[Ѐ-ӿ]');

void _expectUkrainian(String uk, String en, String what) {
  expect(uk.trim(), isNotEmpty, reason: '$what has no Ukrainian name');
  expect(_cyrillic.hasMatch(uk), isTrue, reason: '$what: "$uk" is not Ukrainian');
  expect(uk, isNot(contains("'")), reason: '$what: use ’ as the apostrophe');
}

void main() {
  final catalog = SymbolCatalog.instance;

  group('tables', () {
    test('symbol sets', () {
      expect(catalog.sets.map((s) => s.code), _entityCounts.keys);
      expect(catalog.symbolSet('10')!.nameEn, 'Land Units');
      expect(catalog.symbolSet('27'), isNull);
    });

    test('entity counts match the source tables', () {
      for (final MapEntry(key: set, value: count) in _entityCounts.entries) {
        expect(catalog.entities(set), hasLength(count), reason: 'set $set');
      }
    });

    test('modifier counts match the source tables', () {
      for (final MapEntry(key: set, value: (m1, m2)) in _modifierCounts.entries) {
        expect(catalog.modifiers(set, 1), hasLength(m1), reason: 'set $set sector 1');
        expect(catalog.modifiers(set, 2), hasLength(m2), reason: 'set $set sector 2');
      }
    });

    test('every name has a Ukrainian translation', () {
      for (final s in catalog.sets) {
        _expectUkrainian(s.nameUk, s.nameEn, 'set ${s.code}');
        for (final e in catalog.entities(s.code)) {
          _expectUkrainian(e.nameUk, e.nameEn, '${e.setCode}:${e.code} ${e.nameEn}');
        }
        for (final sector in [1, 2]) {
          for (final m in catalog.modifiers(s.code, sector)) {
            _expectUkrainian(m.nameUk, m.nameEn, '${m.setCode}:m$sector:${m.code} ${m.nameEn}');
          }
        }
        for (final sp in catalog.specialSubtypes(s.code)) {
          _expectUkrainian(sp.nameUk, sp.nameEn, '${sp.setCode}:xxxx${sp.code}');
        }
      }
      for (final v in [
        ...catalog.contexts,
        ...catalog.standardIdentities,
        ...catalog.statuses,
        ...catalog.hqTfDummies,
      ]) {
        _expectUkrainian(v.nameUk, v.nameEn, v.toString());
      }
      for (final a in catalog.amplifiers) {
        _expectUkrainian(a.nameUk, a.nameEn, a.toString());
        _expectUkrainian(a.groupUk, a.groupEn, a.toString());
      }
    });

    test('codes are unique and well formed', () {
      for (final s in catalog.sets) {
        final codes = catalog.entities(s.code).map((e) => e.code).toList();
        expect(codes.toSet(), hasLength(codes.length), reason: 'set ${s.code}');
        expect(codes.every(RegExp(r'^\d{6}$').hasMatch), isTrue);
        for (final sector in [1, 2]) {
          final m = catalog.modifiers(s.code, sector).map((m) => m.code).toList();
          expect(m.toSet(), hasLength(m.length));
          if (m.isNotEmpty) expect(m.first, '00');
        }
      }
    });

    test('siblings have distinct Ukrainian names', () {
      // JMSML itself lists "Navigational Reference Point" twice among maritime control points.
      const sourceDuplicates = {'25:213800'};
      for (final s in catalog.sets) {
        final seen = <String>{};
        for (final e in catalog.entities(s.code)) {
          if (sourceDuplicates.contains('${s.code}:${e.code}')) continue;
          expect(
            seen.add('${e.parentCode}|${e.nameUk}'),
            isTrue,
            reason: '${s.code}:${e.code} "${e.nameUk}"',
          );
        }
        for (final sector in [1, 2]) {
          final names = catalog.modifiers(s.code, sector).map((m) => m.nameUk).toList();
          expect(names.toSet(), hasLength(names.length), reason: 'set ${s.code} sector $sector');
        }
      }
    });

    test('parent links resolve', () {
      for (final s in catalog.sets) {
        for (final e in catalog.entities(s.code)) {
          final parent = e.parentCode;
          if (e.level == EntityLevel.entity) {
            expect(parent, isNull);
            expect(e.code.substring(2), '0000');
            continue;
          }
          final p = catalog.entity(s.code, parent!);
          expect(p, isNotNull, reason: '${s.code}:${e.code} -> $parent');
          expect(p!.level.index, e.level.index - 1);
          expect(catalog.children(s.code, parent), contains(e));
          final prefix = e.level == EntityLevel.type ? 2 : 4;
          expect(e.code.substring(0, prefix), parent.substring(0, prefix));
        }
      }
    });

    test('hierarchy navigation', () {
      final top = catalog.children('10');
      expect(top.first.code, '000000');
      expect(top.map((e) => e.code), contains('120000'));
      final infantry = catalog.children('10', '121100');
      expect(infantry.map((e) => e.code), containsAll(['121102', '121104', '121105']));
      expect(catalog.entity('10', '121102')!.nameUk, 'Механізована піхота');
      expect(catalog.path('10', '121102').map((e) => e.code), ['120000', '121100', '121102']);
      expect(catalog.path('10', '999999'), isEmpty);
      expect(catalog.entities('99'), isEmpty);
      expect(catalog.specialSubtypes('10').map((s) => s.code), ['95', '96', '97', '98']);
    });

    test('base tables', () {
      expect(catalog.standardIdentities.map((v) => v.code), [
        '0',
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '9',
      ]);
      expect(catalog.standardIdentity('3')!.nameUk, 'Свій');
      expect(catalog.standardIdentity('6')!.nameEn, 'Hostile/Faker');
      expect(catalog.statuses.map((v) => v.code), ['0', '1', '2', '3', '4', '5', '9']);
      expect(catalog.hqTfDummy('2')!.nameUk, 'Штаб');
      expect(catalog.amplifier('16')!.nameUk, 'Батальйон/дивізіон');
      expect(catalog.echelons.map((a) => a.code), containsAll(['11', '18', '21', '26']));
      expect(catalog.mobilities.map((a) => a.code), containsAll(['31', '33', '42', '52']));
      expect(catalog.modifier('10', 1, '41')!.nameUk, 'РСЗВ');
    });
  });

  group('search', () {
    String key(SymbolEntity e) => '${e.setCode}:${e.code}';

    test('Ukrainian prefix: піхот', () {
      final r = catalog.search('піхот');
      expect(key(r.first), '10:121100');
      expect(r.map(key), containsAll(['10:121102', '10:121104', '10:121105']));
      // Prefix of the whole name ranks before a word inside the name.
      expect(
        r.indexWhere((e) => e.code == '121100'),
        lessThan(r.indexWhere((e) => e.code == '121102')),
      );
    });

    test('танк', () {
      final r = catalog.search('танк');
      expect(key(r.first), '15:120200');
      expect(r.map(key), containsAll(['10:120500', '15:120201', '15:120300']));
      expect(catalog.search('танк', setCode: '15').every((e) => e.setCode == '15'), isTrue);
    });

    test('English: minefield', () {
      final r = catalog.search('minefield');
      expect(key(r.first), '25:270700');
      expect(r.map(key), contains('25:270706'));
    });

    test('мінометн', () {
      final r = catalog.search('мінометн');
      expect(key(r.first), '10:130800');
      expect(r.map(key), containsAll(['10:130801', '10:130803', '40:110604']));
    });

    test('abbreviation via alias: КП', () {
      final r = catalog.search('КП');
      expect(key(r.first), '01:110115');
      expect(catalog.search('рсзв').map(key), containsAll(['15:111600', '15:111601']));
      expect(key(catalog.search('БМП').first), '10:121105');
    });

    test('case-insensitive, apostrophe variants', () {
      final a = catalog.search("зв'язок").map(key).toList();
      expect(a, isNotEmpty);
      expect(catalog.search('ЗВ’ЯЗОК').map(key), a);
      expect(catalog.search('звʼязок').map(key), a);
      expect(a, contains('10:111000'));
    });

    test('ranking: prefix, whole word, word prefix, substring', () {
      final r = catalog.search('розвідка', setCode: '10');
      expect(r.first.nameUk, startsWith('Розвідка'));
      final i = r.indexWhere((e) => e.code == '121303'); // Моторизована розвідка
      final j = r.indexWhere((e) => e.code == '121301'); // Розвідка і спостереження
      expect(j, lessThan(i));
      expect(catalog.search(''), isEmpty);
      expect(catalog.search('піхот', limit: 2), hasLength(2));
    });
  });

  group('Sidc', () {
    test('parse and print round trip', () {
      const text = '10031000141211000000';
      final s = Sidc.parse(text);
      expect(s.version, '10');
      expect(s.context, '0');
      expect(s.identity, '3');
      expect(s.symbolSet, '10');
      expect(s.status, '0');
      expect(s.hqTfDummy, '0');
      expect(s.amplifier, '14');
      expect(s.entity, '121100');
      expect(s.entityCode, '12');
      expect(s.entityTypeCode, '11');
      expect(s.entitySubtypeCode, '00');
      expect(s.modifier1, '00');
      expect(s.modifier2, '00');
      expect(s.toString(), text);
      expect(Sidc.parse(s.toString()), s);

      const long = '100360001612110527011234567890';
      expect(Sidc.parse(long).toString(), long);
      expect(Sidc.parse(long).extension, '1234567890');
    });

    test('defaults and setters', () {
      final s = Sidc();
      expect(s.version, Sidc.versionApp6D);
      expect(s.toString(), '10031000000000000000');
      final t = s.withIdentity('6').withEntity('121102').withAmplifier('16').withModifier1('27');
      expect(t.toString(), '10061000161211022700');
      expect(s.toString(), '10031000000000000000', reason: 'immutable');
      expect(t.withSymbolSet('15').toString(), '10061500160000000000');
      expect(t.withSymbolSet('15', keepEntity: true).entity, '121102');
      expect(
        t.withStatus('1').withHqTfDummy('2').withContext('1').withVersion('11').toString(),
        '11161012161211022700',
      );
      expect(t.withModifier2('01').modifier2, '01');
      expect(t.withExtension('0000000000').toString(), hasLength(30));
    });

    test('rejects malformed input', () {
      expect(() => Sidc.parse('1003100014121100000'), throwsFormatException);
      expect(() => Sidc.parse('1003100014121100000a'), throwsFormatException);
      expect(Sidc.tryParse('abc'), isNull);
      expect(() => Sidc(entity: '1211'), throwsArgumentError);
      expect(() => Sidc().withIdentity('x'), throwsArgumentError);
    });
  });

  group('describe', () {
    test('friendly infantry platoon', () {
      final d = catalog.describe('10031000141211000000');
      expect(
        d,
        'Набір: Підрозділи\n'
        'Належність: Свій\n'
        'Знак: Рух і маневр › Піхота\n'
        'Статус: Наявний\n'
        'Ешелон: Взвод/загін',
      );
    });

    test('hostile mechanized infantry battalion HQ, exercise, with modifiers', () {
      final d = catalog.describe('10161012161211022701');
      expect(d, contains('Належність: Ворожий/фейкер'));
      expect(d, contains('Контекст: Навчання'));
      expect(d, contains('Знак: Рух і маневр › Піхота › Механізована піхота'));
      expect(d, contains('Статус: Запланований/очікуваний/імовірний'));
      expect(d, contains('Штаб / тактична група / хибний: Штаб'));
      expect(d, contains('Ешелон: Батальйон/дивізіон'));
      expect(d, contains('Модифікатор 1: Передовий'));
      expect(d, contains('Модифікатор 2: Повітряно-десантний'));
    });

    test('equipment mobility, special subtype, unknown codes, 30 digits', () {
      expect(
        catalog.describe('10031500331202020000'),
        contains('Знак: Транспортні засоби › Танк › Середній танк'),
      );
      expect(catalog.describe('10031500331202000000'), contains('Рухомість: Гусеничний'));
      expect(
        catalog.describe('10031000001211950000'),
        contains('Знак: Рух і маневр › Піхота › Штабний елемент'),
      );
      expect(catalog.describe('10031000009999990000'), contains('невідомий код 999999'));
      expect(
        catalog.describe('100310000012110000001234567890'),
        contains('Позиції 21–30: 1234567890'),
      );
      expect(() => catalog.describe('123'), throwsFormatException);
    });
  });
}
