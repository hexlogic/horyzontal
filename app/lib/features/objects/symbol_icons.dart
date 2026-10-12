import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'symbols.dart';

/// Map symbols are rendered at this scale and drawn at 1/this size.
const symbolPixelRatio = 3.0;

/// PNG images of APP-6 symbols for the map, rendered once per SIDC.
class SymbolIcons {
  final _png = <String, Future<Uint8List?>>{};

  /// [size] is the symbol size in logical pixels at [pixelRatio].
  Future<Uint8List?> png(String sidc, {double size = 34, double pixelRatio = 3}) =>
      _png.putIfAbsent('$sidc@$size@$pixelRatio', () => _render(sidc, size, pixelRatio));

  Future<Uint8List?> _render(String sidc, double size, double pixelRatio) async {
    final svg = symbolSvg(sidc, size: size * pixelRatio);
    if (svg == null) return null;
    final info = await vg.loadPicture(SvgStringLoader(svg), null);
    try {
      final w = info.size.width.ceil(), h = info.size.height.ceil();
      final image = await info.picture.toImage(w, h);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return bytes?.buffer.asUint8List();
    } finally {
      info.picture.dispose();
    }
  }
}

final symbolIconsProvider = Provider<SymbolIcons>((ref) => SymbolIcons());

/// An APP-6 symbol as a widget, [height] logical pixels tall.
class SymbolView extends StatelessWidget {
  const SymbolView(this.sidc, {super.key, this.height = 40});
  final String sidc;
  final double height;

  @override
  Widget build(BuildContext context) {
    final svg = symbolSvg(sidc, size: height * 0.6);
    if (svg == null) return SizedBox.square(dimension: height);
    return SvgPicture.string(svg, height: height, fit: BoxFit.contain);
  }
}
