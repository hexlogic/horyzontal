// Ported from milsymbol src/ms/colormode.js and src/colormodes.js, MIT (c) Måns Beckman.

/// One color per affiliation. Values are CSS colors, or `false` for "no
/// color" (the `None` mode), like the JS objects milsymbol uses.
class ColorMode {
  ColorMode({this.civilian, this.friend, this.hostile, this.neutral, this.unknown, this.suspect});

  /// The same color for every affiliation.
  ColorMode.all(Object color)
    : this(
        civilian: color,
        friend: color,
        hostile: color,
        neutral: color,
        unknown: color,
        suspect: color,
      );

  /// From a JS-style object `{Civilian: ..., Friend: ..., ...}`.
  factory ColorMode.fromJson(Map<String, Object?> json) => ColorMode(
    civilian: json['Civilian'],
    friend: json['Friend'],
    hostile: json['Hostile'],
    neutral: json['Neutral'],
    unknown: json['Unknown'],
    suspect: json['Suspect'],
  );

  Object? civilian, friend, hostile, neutral, unknown, suspect;

  /// Color for an affiliation name (`Friend`, `Hostile`, ...), `null` for
  /// anything else, like a JS property lookup.
  Object? operator [](String? affiliation) => switch (affiliation) {
    'Civilian' => civilian,
    'Friend' => friend,
    'Hostile' => hostile,
    'Neutral' => neutral,
    'Unknown' => unknown,
    'Suspect' => suspect,
    _ => null,
  };

  void operator []=(String affiliation, Object? color) {
    switch (affiliation) {
      case 'Civilian':
        civilian = color;
      case 'Friend':
        friend = color;
      case 'Hostile':
        hostile = color;
      case 'Neutral':
        neutral = color;
      case 'Unknown':
        unknown = color;
      case 'Suspect':
        suspect = color;
    }
  }

  ColorMode copy() => ColorMode(
    civilian: civilian,
    friend: friend,
    hostile: hostile,
    neutral: neutral,
    unknown: unknown,
    suspect: suspect,
  );

  Map<String, Object?> toJson() => {
    'Civilian': ?civilian,
    'Friend': ?friend,
    'Hostile': ?hostile,
    'Neutral': ?neutral,
    'Unknown': ?unknown,
    'Suspect': ?suspect,
  };

  @override
  String toString() => 'ColorMode(${toJson()})';
}

ColorMode _mode(String c, String f, String h, String n, String u, String s) =>
    ColorMode(civilian: c, friend: f, hostile: h, neutral: n, unknown: u, suspect: s);

/// Default color modes of milsymbol, by name.
Map<String, ColorMode> defaultColorModes() => {
  'Black': _mode('black', 'black', 'black', 'black', 'black', 'black'),
  'Dark': _mode(
    'rgb(80,0,80)',
    'rgb(0,107,140)',
    'rgb(200,0,0)',
    'rgb(0,160,0)',
    'rgb(225,220,0)',
    'rgb(255, 188, 1)',
  ),
  'FrameColor': _mode(
    'rgb(255,0,255)',
    'rgb(0, 255, 255)',
    'rgb(255, 0, 0)',
    'rgb(0, 255, 0)',
    'rgb(255, 255, 0)',
    'rbg(255, 188, 1)',
  ),
  'IconColor': _mode(
    'rgb(255,0,255)',
    'rgb(0, 255, 255)',
    'rgb(255, 0, 0)',
    'rgb(0, 255, 0)',
    'rgb(255, 255, 0)',
    'rgb(255, 188, 1)',
  ),
  'Light': _mode(
    'rgb(255,161,255)',
    'rgb(128,224,255)',
    'rgb(255,128,128)',
    'rgb(170,255,170)',
    'rgb(255,255,128)',
    'rgb(255, 229, 153)',
  ),
  'Medium': _mode(
    'rgb(128,0,128)',
    'rgb(0,168,220)',
    'rgb(255,48,49)',
    'rgb(0,226,110)',
    'rgb(255,255,0)',
    'rgb(255, 217, 107)',
  ),
  'None': ColorMode(
    civilian: false,
    friend: false,
    hostile: false,
    neutral: false,
    unknown: false,
    suspect: false,
  ),
  'OffWhite': _mode(
    'rgb(239, 239, 239)',
    'rgb(239, 239, 239)',
    'rgb(239, 239, 239)',
    'rgb(239, 239, 239)',
    'rgb(239, 239, 239)',
    'rgb(239, 239, 239)',
  ),
  'White': _mode('white', 'white', 'white', 'white', 'white', 'white'),
};
