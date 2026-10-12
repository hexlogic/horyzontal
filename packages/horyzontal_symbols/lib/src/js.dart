// JavaScript value semantics used by the milsymbol port.
//
// Draw instructions and icon tables are kept as plain maps and lists, exactly
// like the JS objects and arrays they come from. Dart `null` stands for JS
// `undefined`; milsymbol never produces JS `null`.

/// A JS object literal: draw instruction, icon table, bounding box literal.
typedef JsObject = Map<String, Object?>;

/// A JS array.
typedef JsArray = List<Object?>;

/// JS truthiness.
bool truthy(Object? v) => switch (v) {
  null => false,
  bool b => b,
  num n => n != 0 && !n.isNaN,
  String s => s.isNotEmpty,
  _ => true,
};

/// `Number.prototype.toString()`: shortest round-trip digits, no trailing
/// `.0`, exponent outside 1e-7..1e21, `0` for negative zero.
String jsNumber(num n) {
  if (n is int) return n.toString();
  final d = n.toDouble();
  if (d.isNaN) return 'NaN';
  if (d.isInfinite) return d > 0 ? 'Infinity' : '-Infinity';
  if (d == 0) return '0';
  // Dart's double.toString uses the same shortest digits and switches to
  // exponent form at the same thresholds as JS, it only adds `.0` to
  // integral values.
  final s = d.toString();
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

/// `String(v)`.
String jsString(Object? v) => switch (v) {
  null => 'undefined',
  String s => s,
  num n => jsNumber(n),
  bool b => b ? 'true' : 'false',
  List<Object?> l => l.map((e) => e == null ? '' : jsString(e)).join(','),
  Map<Object?, Object?> _ => '[object Object]',
  _ => v.toString(),
};

final _decimal = RegExp(r'^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?$');
final _radix = RegExp(r'^0([xXoObB])([0-9a-fA-F]+)$');
final _jsSpace = RegExp(
  '^[\\s\\uFEFF\\u00A0\\u1680\\u2000-\\u200A\\u2028\\u2029\\u202F\\u205F\\u3000]+|'
  '[\\s\\uFEFF\\u00A0\\u1680\\u2000-\\u200A\\u2028\\u2029\\u202F\\u205F\\u3000]+\$',
);

/// `Number(s)` for a string.
double jsParseNumber(String s) {
  final t = s.replaceAll(_jsSpace, '');
  if (t.isEmpty) return 0;
  if (t == 'Infinity' || t == '+Infinity') return double.infinity;
  if (t == '-Infinity') return double.negativeInfinity;
  if (_decimal.hasMatch(t)) return double.parse(t);
  final m = _radix.firstMatch(t);
  if (m != null) {
    final radix = switch (m.group(1)!.toLowerCase()) {
      'x' => 16,
      'o' => 8,
      _ => 2,
    };
    final v = BigInt.tryParse(m.group(2)!, radix: radix);
    if (v != null) return v.toDouble();
  }
  return double.nan;
}

/// `Number(v)`.
num toNumber(Object? v) => switch (v) {
  null => double.nan,
  num n => n,
  bool b => b ? 1 : 0,
  String s => jsParseNumber(s),
  List<Object?> l => jsParseNumber(jsString(l)),
  _ => double.nan,
};

/// Global `isNaN(v)`.
bool jsIsNaN(Object? v) => toNumber(v).isNaN;

/// `parseFloat(v)` for the numeric style values milsymbol passes to it.
num parseFloat(Object? v) {
  if (v is num) return v;
  final m = RegExp(r'^[+-]?(Infinity|\d+\.?\d*([eE][+-]?\d+)?|\.\d+([eE][+-]?\d+)?)')
      .firstMatch(jsString(v).trimLeft());
  if (m == null) return double.nan;
  final t = m.group(0)!;
  if (t.endsWith('Infinity')) return t.startsWith('-') ? double.negativeInfinity : double.infinity;
  return double.parse(t);
}

/// `parseInt(s)` for the short digit strings of a SIDC (NaN when no digits).
num parseInt(String s) {
  final m = RegExp(r'^[+-]?\d+').firstMatch(s.trimLeft());
  return m == null ? double.nan : int.parse(m.group(0)!);
}

/// `String.prototype.substr(start, length)`.
String substr(String s, int start, [int? length]) {
  if (start < 0) start = (s.length + start).clamp(0, s.length);
  if (start >= s.length) return '';
  final end = length == null ? s.length : (start + length).clamp(start, s.length);
  return s.substring(start, end);
}

/// `String.prototype.substring(start, end)`.
String substring(String s, int start, [int? end]) {
  var a = start.clamp(0, s.length);
  var b = (end ?? s.length).clamp(0, s.length);
  if (a > b) (a, b) = (b, a);
  return s.substring(a, b);
}

/// Loose `a == b` for the primitive values milsymbol compares.
bool looseEquals(Object? a, Object? b) {
  if (a == null || b == null) return a == null && b == null;
  if (a is String && b is String) return a == b;
  if (a is bool) return looseEquals(a ? 1 : 0, b);
  if (b is bool) return looseEquals(a, b ? 1 : 0);
  if (a is num || b is num) {
    if ((a is num || a is String) && (b is num || b is String)) {
      return toNumber(a) == toNumber(b);
    }
  }
  return identical(a, b);
}

/// Relational `a < b` etc. with JS coercion (strings compare as numbers
/// against numbers, NaN compares false).
num _rel(Object? v) => v is num ? v : toNumber(v);
bool lt(Object? a, Object? b) => _rel(a) < _rel(b);
bool le(Object? a, Object? b) => _rel(a) <= _rel(b);
bool gt(Object? a, Object? b) => _rel(a) > _rel(b);
bool ge(Object? a, Object? b) => _rel(a) >= _rel(b);

/// `x.length` for arrays and strings, `undefined` otherwise.
int? jsLength(Object? v) => switch (v) {
  List<Object?> l => l.length,
  String s => s.length,
  _ => null,
};

/// `[].concat(a, b, ...)`: arrays are spread one level, other values appended.
JsArray concat(List<Object?> parts) {
  final r = <Object?>[];
  for (final p in parts) {
    if (p is List<Object?>) {
      r.addAll(p);
    } else {
      r.add(p);
    }
  }
  return r;
}

/// Whether `JSON.stringify(v)` contains the text "null"; milsymbol uses this
/// to detect missing icon parts in the draw instructions.
bool jsonContainsNull(Object? v) {
  if (v == null) return true; // array element or top level
  if (v is num) return v.isNaN || v.isInfinite;
  if (v is String) return _jsonQuote(v).contains('null');
  if (v is List<Object?>) return v.any(jsonContainsNull);
  if (v is Map<String, Object?>) {
    for (final e in v.entries) {
      if (e.value == null) continue; // undefined properties are skipped
      if (_jsonQuote(e.key).contains('null') || jsonContainsNull(e.value)) return true;
    }
  }
  return false;
}

String _jsonQuote(String s) {
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    switch (c) {
      case 0x22:
        b.write(r'\"');
      case 0x5c:
        b.write(r'\\');
      case 0x08:
        b.write(r'\b');
      case 0x0c:
        b.write(r'\f');
      case 0x0a:
        b.write(r'\n');
      case 0x0d:
        b.write(r'\r');
      case 0x09:
        b.write(r'\t');
      default:
        final lone =
            (c >= 0xd800 &&
                c <= 0xdbff &&
                (i + 1 >= s.length || (s.codeUnitAt(i + 1) & 0xfc00) != 0xdc00)) ||
            (c >= 0xdc00 && c <= 0xdfff && (i == 0 || (s.codeUnitAt(i - 1) & 0xfc00) != 0xd800));
        if (c < 0x20 || lone) {
          b.write('\\u${c.toRadixString(16).padLeft(4, '0')}');
        } else {
          b.writeCharCode(c);
        }
    }
  }
  return b.toString();
}

/// Non-index properties of JS arrays. milsymbol's `ms._scale` sets
/// `non_scaling_stroke` on nested arrays too, and `ms.outline` iterates
/// arrays with `for...in`, which visits those properties after the elements.
final Expando<Map<String, Object?>> _arrayProps = Expando('jsArrayProps');

/// `array[key] = value` for a non-index [key].
void setArrayProperty(List<Object?> array, String key, Object? value) {
  (_arrayProps[array] ??= {})[key] = value;
}

/// Non-index properties of [array], in insertion order.
Map<String, Object?> arrayProperties(List<Object?> array) => _arrayProps[array] ?? const {};

/// Values visited by `for (const i in array) array[i]`: elements, then
/// non-index properties.
Iterable<Object?> forInValues(List<Object?> array) sync* {
  yield* array;
  yield* arrayProperties(array).values;
}
