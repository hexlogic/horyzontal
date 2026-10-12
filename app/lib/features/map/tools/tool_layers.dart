import 'package:maplibre_gl/maplibre_gl.dart';

import '../geojson.dart';
import 'tool_geojson.dart';

const _blue = '#1565c0';

Future<void> addToolLayers(MapLibreMapController map) async {
  await map.addGeoJsonSource(toolSource, collection(const []));
  await map.addFillLayer(
    toolSource,
    'hrz-tool-fill',
    const FillLayerProperties(fillColor: _blue, fillOpacity: 0.15),
    filter: [
      '==',
      ['get', 'kind'],
      'fill',
    ],
    enableInteraction: false,
  );
  await map.addLineLayer(
    toolSource,
    'hrz-tool-line',
    const LineLayerProperties(lineColor: _blue, lineWidth: 3),
    filter: [
      '==',
      ['get', 'kind'],
      'line',
    ],
    enableInteraction: false,
  );
  await map.addLineLayer(
    toolSource,
    'hrz-tool-rubber',
    const LineLayerProperties(lineColor: _blue, lineWidth: 2, lineDasharray: [2, 2]),
    filter: [
      '==',
      ['get', 'kind'],
      'rubber',
    ],
    enableInteraction: false,
  );
  await map.addCircleLayer(
    toolSource,
    'hrz-tool-vertex',
    const CircleLayerProperties(
      circleRadius: 6,
      circleColor: '#ffffff',
      circleStrokeColor: _blue,
      circleStrokeWidth: 3,
    ),
    filter: [
      '==',
      ['get', 'kind'],
      'vertex',
    ],
    enableInteraction: false,
  );
  await map.addSymbolLayer(
    toolSource,
    'hrz-tool-label',
    const SymbolLayerProperties(
      textField: [Expressions.get, 'label'],
      textFont: ['Noto Sans Regular'], // in both the online and offline glyphs
      textSize: 13,
      textOffset: [0, -1.3],
      textColor: _blue,
      textHaloColor: '#ffffff',
      textHaloWidth: 2,
      textAllowOverlap: true,
      textIgnorePlacement: true,
    ),
    filter: [
      '==',
      ['get', 'kind'],
      'vertex',
    ],
    enableInteraction: false,
  );
}
