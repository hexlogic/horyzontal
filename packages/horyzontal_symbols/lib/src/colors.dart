// Ported from milsymbol src/ms/symbol/getcolors.js, MIT (c) Måns Beckman.

import 'color_mode.dart';
import 'ms.dart';
import 'symbol.dart';

/// Colors a symbol is drawn with, each by affiliation.
class SymbolColors {
  SymbolColors({
    required this.fillColor,
    required this.frameColor,
    required this.iconColor,
    required this.iconFillColor,
    required this.none,
    required this.black,
    required this.white,
  });

  ColorMode fillColor, frameColor, iconColor, iconFillColor, none, black, white;

  Map<String, Object?> toJson() => {
    'fillColor': fillColor.toJson(),
    'frameColor': frameColor.toJson(),
    'iconColor': iconColor.toJson(),
    'iconFillColor': iconFillColor.toJson(),
    'none': none.toJson(),
    'black': black.toJson(),
    'white': white.toJson(),
  };

  /// Cache key part: every color of every mode.
  String cacheKey() {
    final b = StringBuffer();
    for (final m in [fillColor, frameColor, iconColor, iconFillColor, none, black, white]) {
      b
        ..write(m.civilian)
        ..write('|')
        ..write(m.friend)
        ..write('|')
        ..write(m.hostile)
        ..write('|')
        ..write(m.neutral)
        ..write('|')
        ..write(m.unknown)
        ..write('|')
        ..write(m.suspect)
        ..write(';');
    }
    return b.toString();
  }
}

/// `Symbol.prototype.getColors`.
///
/// Object style values ([ColorMode]) are copied before use; milsymbol
/// modifies them in place, which leaks between symbols sharing an options
/// object.
SymbolColors getColors(MilSymbol symbol) {
  final style = symbol.options;
  final metadata = symbol.metadata;
  final colorMode = style.colorMode;
  var baseFillColor = colorMode is ColorMode
      ? colorMode.copy()
      : ms.getColorMode(colorMode as String);
  final frameColorStyle = style.frameColor;
  final iconColorStyle = style.iconColor;
  final baseFrameColor = frameColorStyle is ColorMode
      ? frameColorStyle.copy()
      : ms.getColorMode('FrameColor');
  final baseIconColor = iconColorStyle is ColorMode
      ? iconColorStyle.copy()
      : ms.getColorMode('IconColor');
  final baseIconFillColor = baseFillColor;
  var baseColorBlack = ms.getColorMode('Black');
  var baseColorWhite = ms.getColorMode('White');
  final baseColorOffWhite = ms.getColorMode('OffWhite');
  final baseColorNone = ms.getColorMode('None');

  //If it is a Civilian Symbol and civilian colors not are turned off, use civilian colors...
  if (style.civilianColor && metadata.civilian) {
    baseFillColor.friend = baseFillColor.neutral = baseFillColor.unknown = baseFillColor.civilian;
    baseFrameColor.friend = baseFrameColor.neutral = baseFrameColor.unknown =
        baseFrameColor.civilian;
    baseIconColor.friend = baseIconColor.neutral = baseIconColor.unknown = baseIconColor.civilian;
  }
  //Joker and Faker
  if (metadata.joker || metadata.faker) {
    baseFillColor.friend = baseFillColor.hostile;
    baseFrameColor.friend = baseFrameColor.hostile;
    baseIconColor.friend = baseIconColor.hostile;
  }

  //Joker and Faker
  if (metadata.suspect) {
    baseFillColor.friend = baseFillColor.hostile = baseFillColor.suspect;
    baseFrameColor.friend = baseFrameColor.hostile = baseFrameColor.suspect;
    baseIconColor.friend = baseIconColor.hostile = baseIconColor.suspect;
  }

  //If the user has specified a mono color to use for all symbols.
  if (style.monoColor != '') {
    baseFrameColor.friend = baseFrameColor.neutral = baseFrameColor.hostile =
        baseFrameColor.unknown = baseFrameColor.civilian = style.monoColor;
    baseColorBlack = baseFrameColor;
    baseColorWhite = baseFillColor = baseColorNone;
  }

  final colors = SymbolColors(
    fillColor: baseFillColor,
    frameColor: baseFrameColor,
    iconColor: baseIconColor,
    iconFillColor: baseIconFillColor,
    none: baseColorNone,
    black: baseColorBlack,
    white: baseColorWhite,
  );
  //Turn of the frame
  if (metadata.frame) {
    // A ColorMode style value is baseFrameColor itself in milsymbol.
    colors.frameColor = frameColorStyle is ColorMode ? baseFrameColor : baseColorBlack;
  } else {
    colors.frameColor = baseColorNone;
  }
  //Filled or not.
  if (metadata.fill) {
    //I don't think you can have an unframed but filled icon so we turn off the fill as well, unless you have turned off the icon as well.
    colors.fillColor = !metadata.frame && !(!metadata.frame && !style.icon)
        ? baseColorNone
        : baseFillColor;
    colors.iconColor = iconColorStyle is ColorMode ? baseIconColor : baseColorBlack;
    //Dirty override, we want colors in the icon if we just turn off the frame. This is a special fix for filled icn in 2525.
    colors.iconFillColor = !metadata.frame ? baseFillColor : baseColorOffWhite;
    colors.white = baseColorOffWhite;
  } else {
    colors.fillColor = baseColorNone;
    //Fix frame color if it should be turned off.
    colors.frameColor = !metadata.frame ? baseColorNone : baseFrameColor;
    colors.iconColor = baseFrameColor;
    colors.iconFillColor = baseColorNone;
    //If everything turned off, make everything black.
    if (!metadata.frame && !metadata.fill && !style.icon) {
      colors.frameColor = baseColorBlack;
      colors.fillColor = baseColorBlack;
    }
  }
  return colors;
}
