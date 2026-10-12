import 'dart:math' as math;

import 'package:horyzontal_geo/horyzontal_geo.dart';

import '../../core/data/model.dart';

/// GeoJSON for the map's object layers. Coordinates are [lon, lat].
List<double> lonLat(Geodetic g) => [g.lon, g.lat];

String hexColor(int argb) => '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

Map<String, Object?> collection(Iterable<Map<String, Object?>> features) =>
    {'type': 'FeatureCollection', 'features': features.toList()};

Map<String, Object?> pointsGeoJson(Iterable<MapFeature> fs, Map<String, int> layerColors,
        {required bool Function(String sidc) hasIcon, List<double> Function(String sidc)? offset}) =>
    collection([
      for (final f in fs)
        if (f.kind == FeatureKind.point)
          {
            'type': 'Feature',
            'id': f.id,
            'properties': {
              'id': f.id,
              'name': f.name,
              'color': hexColor(f.color ?? layerColors[f.layerId] ?? 0xFF1565C0),
              if (f.sidc != null && hasIcon(f.sidc!)) ...{
                'icon': 'sidc-${f.sidc}',
                'offset': offset?.call(f.sidc!) ?? const [0.0, 0.0],
              },
            },
            'geometry': {'type': 'Point', 'coordinates': lonLat(f.position)},
          },
    ]);

Map<String, Object?> linesGeoJson(Iterable<MapFeature> fs, Map<String, int> layerColors) =>
    collection([
      for (final f in fs)
        if (f.kind != FeatureKind.point && f.vertices.length >= 2)
          {
            'type': 'Feature',
            'id': f.id,
            'properties': {
              'id': f.id,
              'name': f.name,
              'color': hexColor(f.color ?? layerColors[f.layerId] ?? 0xFF1565C0),
              'polygon': f.kind == FeatureKind.polygon,
            },
            'geometry': f.kind == FeatureKind.polygon
                ? {
                    'type': 'Polygon',
                    'coordinates': [
                      [...f.vertices.map(lonLat), lonLat(f.vertices.first)],
                    ],
                  }
                : {'type': 'LineString', 'coordinates': f.vertices.map(lonLat).toList()},
          },
    ]);

/// Circles of [MapFeature.radius] around points, as geodesic polygons.
Map<String, Object?> radiusGeoJson(Iterable<MapFeature> fs, Map<String, int> layerColors) =>
    collection([
      for (final f in fs)
        if (f.kind == FeatureKind.point && (f.radius ?? 0) > 0)
          {
            'type': 'Feature',
            'id': '${f.id}-r',
            'properties': {
              'id': f.id,
              'color': hexColor(f.color ?? layerColors[f.layerId] ?? 0xFF1565C0),
            },
            'geometry': {
              'type': 'Polygon',
              'coordinates': [geodesicCircle(f.position, f.radius!)],
            },
          },
    ]);

List<List<double>> geodesicCircle(Geodetic c, double radius, {int segments = 72}) => [
      for (var i = 0; i <= segments; i++)
        () {
          final r = Geodesic.wgs84.direct(c.lat, c.lon, i * 360 / segments, radius);
          return [r.lon2, r.lat2];
        }(),
    ];

/// Metres per logical pixel at [lat] for MapLibre's 512 px tiles.
double metresPerPixel(double lat, double zoom) =>
    40075016.686 * math.cos(lat * math.pi / 180) / (512 * math.pow(2, zoom));
