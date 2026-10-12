// Compares the port with milsymbol output recorded by
// tools/symbols-reference/generate.mjs.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:horyzontal_symbols/horyzontal_symbols.dart';
import 'package:horyzontal_symbols/src/js.dart' show jsNumber;
import 'package:test/test.dart';

const _dir = 'test/fixtures';

/// Fixture records of one `.jsonl.gz` file.
List<Map<String, Object?>> readFixture(String name) {
  final bytes = File('$_dir/$name').readAsBytesSync();
  final text = utf8.decode(gzip.decode(bytes));
  return [
    for (final line in const LineSplitter().convert(text))
      if (line.isNotEmpty) jsonDecode(line) as Map<String, Object?>,
  ];
}

bool _numEq(Object? expected, num actual) =>
    expected == null ? actual.isNaN : (expected as num) == actual;

bool _pairEq(Object? expected, num a, num b) {
  final e = expected as List<Object?>;
  return _numEq(e[0], a) && _numEq(e[1], b);
}

/// JSON equality ignoring map key order.
bool _jsonEq(Object? a, Object? b) => jsonEncode(_sorted(a)) == jsonEncode(_sorted(b));

Object? _sorted(Object? v) => switch (v) {
  Map<String, Object?> m => {for (final k in m.keys.toList()..sort()) k: _sorted(m[k])},
  List<Object?> l => [for (final e in l) _sorted(e)],
  _ => v,
};

/// First difference of two strings with some context.
String _diff(String expected, String actual) {
  var i = 0;
  while (i < expected.length && i < actual.length && expected[i] == actual[i]) {
    i++;
  }
  String cut(String s) => s.substring((i - 60).clamp(0, s.length), (i + 100).clamp(0, s.length));
  return 'at $i\n    milsymbol: ...${cut(expected)}...\n    dart:      ...${cut(actual)}...';
}

/// Problems of one record, empty when it matches.
List<String> check(Map<String, Object?> r) {
  final sidc = r['sidc'] as String;
  final options = SymbolOptions.fromJson(r['options'] as Map<String, Object?>);
  final problems = <String>[];
  if (r.containsKey('error')) {
    try {
      MilSymbol(sidc, options).asSvg();
      problems.add('milsymbol throws "${r['error']}", dart does not');
    } catch (_) {}
    return problems;
  }
  final MilSymbol s;
  final String svg;
  try {
    s = MilSymbol(sidc, options);
    svg = s.asSvg();
  } catch (e, st) {
    return ['dart throws $e\n${st.toString().split('\n').take(6).join('\n')}'];
  }
  final expectedSvg = r['svg'] as String;
  if (svg != expectedSvg) problems.add('svg ${_diff(expectedSvg, svg)}');
  if (!_pairEq(r['size'], s.size.width, s.size.height)) {
    problems.add('size ${r['size']} != ${s.size}');
  }
  if (!_pairEq(r['anchor'], s.anchor.x, s.anchor.y)) {
    problems.add('anchor ${r['anchor']} != ${s.anchor}');
  }
  if (!_pairEq(r['octagonAnchor'], s.octagonAnchor.x, s.octagonAnchor.y)) {
    problems.add('octagonAnchor ${r['octagonAnchor']} != ${s.octagonAnchor}');
  }
  if (r['isValid'] != s.isValid) problems.add('isValid ${r['isValid']} != ${s.isValid}');
  final v = r['validity'] as Map<String, Object?>;
  final dv = s.validity();
  if (v['drawInstructions'] != dv.drawInstructions ||
      v['icon'] != dv.icon ||
      v['mobility'] != dv.mobility) {
    problems.add('validity $v != ${dv.drawInstructions}/${dv.icon}/${dv.mobility}');
  }
  final meta = r['metadata'] as Map<String, Object?>;
  final dartMeta = s.metadata.toJson();
  for (final k in {...meta.keys, ...dartMeta.keys}) {
    final ok = meta.containsKey(k)
        ? _jsonEq(meta[k], dartMeta[k])
        : (dartMeta[k] == null || dartMeta[k] == false);
    if (!ok) problems.add('metadata.$k ${meta[k]} != ${dartMeta[k]}');
  }
  if (r['colors'] case final Map<String, Object?> colors) {
    if (!_jsonEq(colors, s.colors.toJson())) {
      problems.add('colors $colors != ${s.colors.toJson()}');
    }
  }
  return problems;
}

void main() {
  final manifest =
      jsonDecode(File('$_dir/manifest.json').readAsStringSync()) as Map<String, Object?>;
  final files = (manifest['files'] as List<Object?>).cast<Map<String, Object?>>();

  for (final f in files) {
    final name = f['name'] as String;
    test('$name (symbol sets ${f['sets']})', () {
      final records = readFixture(name);
      expect(records, hasLength(f['count']));
      final failures = <String>[];
      var failed = 0;
      for (final r in records) {
        final p = check(r);
        if (p.isEmpty) continue;
        failed++;
        if (failures.length < 5) {
          failures.add('#${r['id']} ${r['sidc']} ${jsonEncode(r['options'])}\n  ${p.join('\n  ')}');
        }
      }
      print('$name: ${records.length - failed}/${records.length} identical');
      expect(
        failed,
        0,
        reason: '$failed of ${records.length} differ, first:\n${failures.join('\n')}',
      );
    });
  }

  test('JS number formatting', () {
    final rows = jsonDecode(File('$_dir/js_number.json').readAsStringSync()) as List<Object?>;
    final bytes = ByteData(8);
    var bad = 0;
    final first = <String>[];
    for (final row in rows.cast<List<Object?>>()) {
      final hex = row[0] as String;
      bytes.setUint32(0, int.parse(hex.substring(0, 8), radix: 16));
      bytes.setUint32(4, int.parse(hex.substring(8), radix: 16));
      final v = bytes.getFloat64(0);
      if (jsNumber(v) != row[1]) {
        bad++;
        if (first.length < 5) first.add('$hex: ${row[1]} != ${jsNumber(v)}');
      }
    }
    expect(bad, 0, reason: first.join('\n'));
  });
}
