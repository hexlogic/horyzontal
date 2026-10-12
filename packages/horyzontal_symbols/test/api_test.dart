import 'package:horyzontal_symbols/horyzontal_symbols.dart';
import 'package:test/test.dart';

import 'reference_test.dart' show check, readFixture;

void main() {
  tearDown(MilSymbol.reset);

  test('friendly infantry', () {
    final s = MilSymbol('10031000001211000000');
    expect(s.isValid, isTrue);
    expect(s.asSvg(), startsWith('<svg xmlns="http://www.w3.org/2000/svg" version="1.2"'));
    expect(s.size, const SymbolSize(158, 108));
    expect(s.anchor, const SymbolPoint(79, 54));
    expect(s.octagonAnchor, const SymbolPoint(79, 54));
    expect(s.metadata.affiliation, 'Friend');
    expect(s.metadata.dimension, 'Ground');
    expect(s.metadata.unit, isTrue);
    expect(s.colors.fillColor['Friend'], 'rgb(128,224,255)');
    expect(s.toDataUrl(), startsWith('data:image/svg+xml;utf8,%3Csvg'));
  });

  test('SIDC is normalized', () {
    expect(MilSymbol('1003 1000 0012 1100 0000').sidc, '10031000001211000000');
    expect(MilSymbol('10031000001211000*00').sidc, '10031000001211000-00');
  });

  test('symbol set without a ported module draws the unknown icon', () {
    // Air (01) is not ported yet: frame and question mark, not valid.
    final s = MilSymbol('10030100001101000000');
    expect(s.isValid, isFalse);
    expect(s.validity().icon, isFalse);
    expect(s.asSvg(), contains('M 155,150 C 155,50 115,30 100,30 85,30 45,50 45,150'));
    expect(s.asSvg(), contains('m 94.8206,78.1372'));
    // Frame only codes stay valid.
    expect(MilSymbol('10030100000000000000').isValid, isTrue);
  });

  test('letter SIDCs render the unknown icon instead of failing', () {
    final s = MilSymbol('SFGPUCI----K');
    expect(s.metadata.numberSIDC, isFalse);
    expect(s.isValid, isFalse);
    expect(s.asSvg(), contains('m 94.8206,78.1372'));
  });

  test('global standard matches the standard option', () {
    const sidc = '10031000001211000000';
    final app6 = MilSymbol(sidc, const SymbolOptions(standard: 'APP6')).asSvg();
    expect(MilSymbol.setStandard('APP6'), isTrue);
    expect(MilSymbol(sidc).asSvg(), app6);
    expect(MilSymbol.setStandard('X'), isFalse);
  });

  test('named and inline color modes', () {
    final mode = ColorMode(friend: 'red', hostile: 'blue', neutral: 'green', unknown: 'yellow');
    MilSymbol.setColorMode('Mine', mode);
    final byName = MilSymbol('10031000001211000000', const SymbolOptions(colorMode: 'Mine'));
    final inline = MilSymbol('10031000001211000000', SymbolOptions(colorMode: mode));
    expect(byName.asSvg(), inline.asSvg());
    expect(byName.asSvg(), contains('fill="red"'));
    expect(
      () => MilSymbol('10031000001211000000', const SymbolOptions(colorMode: 'Nope')),
      throwsArgumentError,
    );
  });

  test('options from and to JS-style maps', () {
    final o = SymbolOptions.fromJson({
      'size': 35,
      'uniqueDesignation': 'A',
      'outlineColor': {'Friend': 'red'},
      'direction': '90',
      'custom_key': 1,
    });
    expect(o.size, 35);
    expect(o.direction, 90);
    expect(o.outlineColor, isA<ColorMode>());
    expect(o['custom_key'], 1);
    expect(o.hasOption('custom_key'), isTrue);
    expect(o.hasOption('size'), isFalse);
    final json = o.toJson();
    expect(json['size'], 35);
    expect(json['uniqueDesignation'], 'A');
    expect(json['outlineColor'], {'Friend': 'red'});
    expect(json.containsKey('fill'), isFalse);
  });

  test('octagon debug part', () {
    MilSymbol.showOctagon();
    expect(MilSymbol('10031000001211000000').asSvg(), contains('stroke="rgb(0,0,255)"'));
  });

  test('results do not depend on rendering order (icon cache)', () {
    final records = [...readFixture('land-scaled.jsonl.gz'), ...readFixture('land.jsonl.gz')];
    final picked = [for (var i = 0; i < records.length; i += 7) records[i]];
    for (final r in picked.reversed) {
      expect(check(r), isEmpty, reason: '#${r['id']} ${r['sidc']}');
    }
  });
}
