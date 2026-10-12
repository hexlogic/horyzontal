// Ported from milsymbol src/ms/symbol/assvg.js, MIT (c) Måns Beckman.

import 'js.dart';
import 'ms.dart';
import 'symbol.dart';

const _attrEscape = {'&': '&amp;', '"': '&quot;', "'": '&apos;', '<': '&lt;', '>': '&gt;'};
const _textEscape = {'&': '&amp;', '<': '&lt;', '>': '&gt;'};

final _rawSvgBlocklist = RegExp(
  r'<\s*(script|foreignObject|iframe|object|embed)[\s>]|on[a-z]+\s*=|javascript:',
  caseSensitive: false,
);
final _dasharrayPattern = RegExp(r'^[0-9.,\s-]+$');
final _fontFamilyPattern = RegExp(r'''^[a-zA-Z0-9 ,"'_:-]+$''');
const _linecapValues = {'butt', 'round', 'square'};
const _textAnchorValues = {'start', 'middle', 'end'};
const _baselineValues = {
  'auto',
  'text-bottom',
  'alphabetic',
  'ideographic',
  'middle',
  'central',
  'mathematical',
  'hanging',
  'text-top',
  'text-before-edge',
  'text-after-edge',
};

String _escapeAttr(Object? value) =>
    jsString(value ?? '')
        .replaceAllMapped(RegExp('[&"\'<>]'), (m) => _attrEscape[m[0]]!)
        .replaceAll(RegExp('[\r\n\t]'), ' ');

String _escapeText(Object? value) =>
    jsString(value ?? '').replaceAllMapped(RegExp('[&<>]'), (m) => _textEscape[m[0]]!);

String _attr(String name, Object? value) {
  if (value == null) return '';
  return ' $name="${_escapeAttr(value)}"';
}

num _safeNumber(Object? value, [num fallback = 0]) {
  final n = toNumber(value);
  return n.isFinite ? n : fallback;
}

String _sanitizeDashArray(Object? value) {
  if (value == null) return '';
  final normalized = _jsTrim(jsString(value));
  return _dasharrayPattern.hasMatch(normalized) ? normalized : '';
}

String _lower(Object? value) => truthy(value) ? jsString(value).toLowerCase() : '';

String _sanitizeLineCap(Object? value) {
  final n = _lower(value);
  return _linecapValues.contains(n) ? n : '';
}

String _sanitizeFontWeight(Object? value) {
  final n = _lower(value);
  return RegExp(r'^(normal|bold|bolder|lighter|[1-9]00)$').hasMatch(n) ? n : '';
}

String _sanitizeTextAnchor(Object? value) {
  final n = _lower(value);
  return _textAnchorValues.contains(n) ? n : '';
}

String _sanitizeBaseline(Object? value) {
  final n = _lower(value);
  return _baselineValues.contains(n) ? n : '';
}

String _sanitizeFontFamily(Object? value, [String fallback = 'sans-serif']) {
  if (value == null) return fallback;
  final normalized = _jsTrim(jsString(value));
  return _fontFamilyPattern.hasMatch(normalized)
      ? (normalized.isEmpty ? fallback : normalized)
      : fallback;
}

String _sanitizeColor(Object? value, [String fallback = 'none']) {
  if (value == null) return fallback;
  final normalized = _jsTrim(jsString(value));
  if (normalized.isEmpty) return fallback;
  if (RegExp(r'url\s*\(', caseSensitive: false).hasMatch(normalized) ||
      RegExp('javascript:', caseSensitive: false).hasMatch(normalized) ||
      RegExp('^data:', caseSensitive: false).hasMatch(normalized)) {
    return fallback;
  }
  return normalized;
}

String _sanitizeSvgFragment(Object? value) {
  if (value == null) return '';
  final fragment = jsString(value);
  return _rawSvgBlocklist.hasMatch(fragment) ? '' : fragment;
}

String _sanitizeId(Object? value, [String fallback = '']) {
  if (value == null) return fallback;
  var normalized = _jsTrim(jsString(value));
  if (normalized.isEmpty) return fallback;
  normalized = normalized.replaceAll(RegExp('[^A-Za-z0-9._:-]'), '_');
  if (!RegExp('^[A-Za-z_]').hasMatch(normalized)) {
    normalized = 'id_$normalized';
  }
  return normalized.isEmpty ? fallback : normalized;
}

String _jsTrim(String s) => s.replaceAll(
  RegExp(
    '^[\\s\\uFEFF\\u00A0\\u1680\\u2000-\\u200A\\u2028\\u2029\\u202F\\u205F\\u3000]+|'
    '[\\s\\uFEFF\\u00A0\\u1680\\u2000-\\u200A\\u2028\\u2029\\u202F\\u205F\\u3000]+\$',
  ),
  '',
);

/// `Symbol.prototype.asSVG`.
String asSVG(MilSymbol symbol) {
  final style = symbol.options;
  var clipCounter = 0;

  String processInstructions(Object? instructions) {
    final b = StringBuffer();
    // Only arrays are walked; JS iterates `instruction.length` elements.
    if (instructions is! List<Object?>) return '';
    for (final ins in instructions) {
      if (ins is List<Object?>) {
        if (ins.isNotEmpty) b.write(processInstructions(ins));
      } else if (ins is Map<String, Object?>) {
        final svg = StringBuffer();
        final type = ins['type'];
        if (type == 'svg') {
          svg.write(_sanitizeSvgFragment(ins['svg']));
        } else {
          var inlineClipId = '';
          if (ins.containsKey('clipPath') && type != 'clip') {
            inlineClipId = 'clip-inline-${clipCounter++}';
            svg
              ..write('<clipPath')
              ..write(_attr('id', inlineClipId))
              ..write('>')
              ..write('<path')
              ..write(_attr('d', ins['clipPath']))
              ..write(_attr('clip-rule', 'nonzero'))
              ..write(' />')
              ..write('</clipPath>');
          }
          void clipAttr() {
            if (inlineClipId.isNotEmpty) svg.write(_attr('clip-path', 'url(#$inlineClipId)'));
          }

          switch (type) {
            case 'path':
              svg
                ..write('<path')
                ..write(_attr('d', ins['d']));
              clipAttr();
            case 'circle':
              svg
                ..write('<circle')
                ..write(_attr('cx', _safeNumber(ins['cx'], 0)))
                ..write(_attr('cy', _safeNumber(ins['cy'], 0)))
                ..write(_attr('r', _safeNumber(ins['r'], 0)));
              clipAttr();
            case 'text':
              svg
                ..write('<text')
                ..write(_attr('x', _safeNumber(ins['x'], 0)))
                ..write(_attr('y', _safeNumber(ins['y'], 0)))
                ..write(_attr('text-anchor', _or(_sanitizeTextAnchor(ins['textanchor']), 'start')))
                ..write(_attr('font-size', _safeNumber(ins['fontsize'], 12)))
                ..write(_attr('font-family', _sanitizeFontFamily(ins['fontfamily'])));
              final fontWeight = _sanitizeFontWeight(ins['fontweight']);
              if (fontWeight.isNotEmpty) svg.write(_attr('font-weight', fontWeight));
              final baseline = _sanitizeBaseline(ins['alignmentBaseline']);
              if (baseline.isNotEmpty) svg.write(_attr('dominant-baseline', baseline));
              clipAttr();
            case 'translate':
              svg
                ..write('<g')
                ..write(
                  _attr(
                    'transform',
                    'translate(${jsNumber(_safeNumber(ins['x'], 0))},'
                        '${jsNumber(_safeNumber(ins['y'], 0))})',
                  ),
                );
              clipAttr();
            case 'rotate':
              svg
                ..write('<g')
                ..write(
                  _attr(
                    'transform',
                    'rotate(${jsNumber(_safeNumber(ins['degree'], 0))},'
                        '${jsNumber(_safeNumber(ins['x'], 0))},'
                        '${jsNumber(_safeNumber(ins['y'], 0))})',
                  ),
                );
              clipAttr();
            case 'scale':
              svg
                ..write('<g')
                ..write(_attr('transform', 'scale(${jsNumber(_safeNumber(ins['factor'], 1))})'));
              clipAttr();
            case 'clip':
              svg.write('<clipPath');
              final resolvedClipId = _or(
                _sanitizeId(ins['clipId']),
                'clip-custom-${clipCounter++}',
              );
              svg
                ..write(_attr('id', resolvedClipId))
                ..write('>')
                ..write('<path')
                ..write(_attr('d', ins['d']))
                ..write(_attr('clip-rule', 'nonzero'))
                ..write(' />')
                ..write('</clipPath>')
                ..write('<g')
                ..write(_attr('clip-path', 'url(#$resolvedClipId)'));
          }
          if (ins['stroke'] != null) {
            final nonScalingStroke = _safeNumber(ins['non_scaling_stroke'], 1);
            final strokeWidthSetting = ins['strokewidth'] != null
                ? _safeNumber(ins['strokewidth'], style.strokeWidth)
                : style.strokeWidth;
            final computedStrokeWidth = _safeNumber(
              nonScalingStroke * strokeWidthSetting,
              style.strokeWidth,
            );
            svg.write(_attr('stroke-width', computedStrokeWidth));
            final dashArray = _sanitizeDashArray(ins['strokedasharray']);
            if (dashArray.isNotEmpty) svg.write(_attr('stroke-dasharray', dashArray));
            final lineCap = _sanitizeLineCap(ins['linecap']);
            if (lineCap.isNotEmpty) {
              svg
                ..write(_attr('stroke-linecap', lineCap))
                ..write(_attr('stroke-linejoin', lineCap));
            }
            final strokeColor = truthy(ins['stroke'])
                ? _sanitizeColor(ins['stroke'], 'none')
                : 'none';
            svg.write(_attr('stroke', strokeColor));
          }
          if (ins['fill'] != null) {
            var fill = ins['fill'];
            if (truthy(ins['styleFill']) && style.styleFill) {
              fill = 'rgba(255,255,255,0.4)';
            }
            svg.write(_attr('fill', truthy(fill) ? _sanitizeColor(fill, 'none') : 'none'));
          }
          if (ins['fillopacity'] != null) {
            final fillOpacity = _clamp01(_safeNumber(ins['fillopacity'], 1));
            svg.write(_attr('fill-opacity', fillOpacity));
          }
          svg.write(' >');
          switch (type) {
            case 'path':
              svg.write('</path>');
            case 'circle':
              svg.write('</circle>');
            case 'text':
              svg.write('${_escapeText(ins['text'])}</text>');
            case 'translate' || 'rotate' || 'scale' || 'clip':
              svg
                ..write(processInstructions(ins['draw']))
                ..write('</g>');
          }
        }
        b.write(svg);
      }
    }
    return b.toString();
  }

  final strokeWidth = _safeNumber(style.strokeWidth, 0);
  final outlineWidth = _safeNumber(style.outlineWidth, 0);
  final bboxX = _safeNumber(symbol.bbox.x1, 0) - strokeWidth - outlineWidth;
  final bboxY = _safeNumber(symbol.bbox.y1, 0) - strokeWidth - outlineWidth;
  final width = _safeNumber(symbol.width, symbol.baseWidth);
  final height = _safeNumber(symbol.height, symbol.baseHeight);
  final baseWidth = _safeNumber(symbol.baseWidth, width);
  final baseHeight = _safeNumber(symbol.baseHeight, height);
  final viewBox =
      '${jsNumber(bboxX)} ${jsNumber(bboxY)} ${jsNumber(baseWidth)} ${jsNumber(baseHeight)}';

  final xml = StringBuffer('<svg')
    ..write(_attr('xmlns', Ms.svgNS))
    ..write(_attr('version', '1.2'))
    ..write(_attr('baseProfile', 'tiny'))
    ..write(_attr('width', width))
    ..write(_attr('height', height))
    ..write(_attr('viewBox', viewBox))
    ..write('>')
    ..write(processInstructions(symbol.drawInstructions))
    ..write('</svg>');
  return xml.toString();
}

String _or(String a, String b) => a.isEmpty ? b : a;

num _clamp01(num v) => v < 0 ? 0 : (v > 1 ? 1 : v);
