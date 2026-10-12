import 'package:flutter/material.dart';

/// Colour ramp of the elevation tint, metres above sea level to colour. The
/// steps are dense below 400 m, where almost all of Ukraine lies, and sparse
/// up to Hoverla (2061 m).
const reliefStops = <(double, Color)>[
  (0, Color(0xFF1A9850)),
  (50, Color(0xFF66BD63)),
  (100, Color(0xFFA6D96A)),
  (150, Color(0xFFD9EF8B)),
  (200, Color(0xFFFEE08B)),
  (250, Color(0xFFFDAE61)),
  (300, Color(0xFFF46D43)),
  (400, Color(0xFFD73027)),
  (600, Color(0xFFA50026)),
  (1000, Color(0xFF7F3B08)),
  (1500, Color(0xFFB08C6B)),
  (2100, Color(0xFFFFFFFF)),
];

const reliefOpacity = 0.55;

/// Prefix of the tint layer ids, one layer per elevation pack.
const reliefLayerPrefix = 'color_relief_';

String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// MapLibre `color-relief-color` expression for [reliefStops].
List<Object> reliefColorExpression() => [
  'interpolate',
  ['linear'],
  ['elevation'],
  for (final (h, c) in reliefStops) ...[h, _hex(c)],
];

/// raster-dem source for an elevation pack, as the map pipeline builds them.
Map<String, Object?> demSource(String path) => {
  'type': 'raster-dem',
  'url': 'pmtiles://file://$path',
  'encoding': 'mapbox',
  'tileSize': 256,
  'attribution': 'Copernicus DEM GLO-30 © ESA/DLR/Airbus',
};

/// Adds one tint layer per raster-dem source in [demSourceIds], below the
/// water, roads and labels (before the first layer whose id starts with
/// `water`, else before the first symbol layer). Hidden unless [visible]:
/// MapLibre does not load tiles for a source whose layers are all hidden.
void addReliefLayers(Map<String, Object?> style, List<String> demSourceIds, {required bool visible}) {
  if (demSourceIds.isEmpty) return;
  final layers = (style['layers']! as List<Object?>).cast<Map<String, Object?>>().toList();
  var at = layers.indexWhere((l) => (l['id']! as String).startsWith('water'));
  if (at < 0) at = layers.indexWhere((l) => l['type'] == 'symbol');
  if (at < 0) at = layers.length;
  layers.insertAll(at, [
    for (final (i, src) in demSourceIds.indexed)
      {
        'id': '$reliefLayerPrefix$i',
        'type': 'color-relief',
        'source': src,
        'layout': {'visibility': visible ? 'visible' : 'none'},
        'paint': {'color-relief-color': reliefColorExpression(), 'color-relief-opacity': reliefOpacity},
      },
  ]);
  style['layers'] = layers;
}
