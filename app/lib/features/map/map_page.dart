import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:horyzontal_geo/horyzontal_geo.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/data/model.dart';
import '../../core/data/repository.dart';
import '../../core/labels.dart';
import '../../core/sensors.dart';
import '../../core/settings.dart';
import '../../core/widgets/copy_tile.dart';
import '../objects/feature_sheet.dart';
import '../objects/symbol_icons.dart';
import 'geojson.dart';
import 'map_focus.dart';
import 'map_layers_sheet.dart';
import 'map_style.dart';
import 'packs.dart';
import 'scale_bar.dart';
import 'search_sheet.dart';

const _emptyStyle =
    '{"version":8,"sources":{},"layers":[{"id":"bg","type":"background","paint":{"background-color":"#ece8df"}}]}';

const _src = (points: 'hrz-points', lines: 'hrz-lines', radius: 'hrz-radius', search: 'hrz-search');

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  MapLibreMapController? _map;
  String? _style;
  bool _styleReady = false;
  bool _noPacks = false;
  String? _styleKey;
  MyLocationTrackingMode _tracking = MyLocationTrackingMode.none;
  bool _locationAllowed = false;
  CameraPosition? _camera;
  Geodetic? _searchMarker;
  final _iconsAdded = <String>{};
  Timer? _saveCamera;

  @override
  void initState() {
    super.initState();
    ensureLocationPermission().then((_) {
      if (mounted) setState(() => _locationAllowed = true);
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _saveCamera?.cancel();
    super.dispose();
  }

  /// Rebuilds the style when the base map choice or the installed packs change.
  Future<void> _loadStyle(AppSettings s, List<PackFile> packs) async {
    // Nothing goes to OpenFreeMap before the user has read the privacy note.
    final online = s.onlineMap && !s.offlineOnly && s.privacyNoticeSeen;
    final key = online ? 'online' : 'offline:${packs.map((p) => p.path).join('|')}';
    if (key == _styleKey) return;
    _styleKey = key;
    String style;
    var noPacks = false;
    try {
      if (online) {
        style = await onlineStyle(ref.read(netProvider));
      } else if (packs.any((p) => p.kind == PackKind.basemap)) {
        style = await offlineStyle(packs);
      } else {
        style = _emptyStyle;
        noPacks = true;
      }
    } catch (e) {
      debugPrint('map style: $e');
      // No network and no cached online style: fall back to the packs.
      style = packs.any((p) => p.kind == PackKind.basemap) ? await offlineStyle(packs) : _emptyStyle;
      noPacks = !packs.any((p) => p.kind == PackKind.basemap);
    }
    if (!mounted || key != _styleKey) return;
    setState(() {
      _style = style;
      _styleReady = false;
      _noPacks = noPacks;
      _iconsAdded.clear();
    });
  }

  Future<void> _onStyleLoaded() async {
    final map = _map;
    if (map == null) return;
    try {
      await _addObjectLayers(map);
    } catch (e) {
      // The map was rebuilt with another style while this ran; the new
      // controller sets its layers up itself.
      if (identical(map, _map)) rethrow;
      return;
    }
    if (!mounted || !identical(map, _map)) return;
    setState(() => _styleReady = true);
    await _syncFeatures(ref.read(visibleFeaturesProvider).value ?? const []);
    await _syncSearch();
  }

  Future<void> _addObjectLayers(MapLibreMapController map) async {
    final empty = collection(const []);
    await map.addGeoJsonSource(_src.radius, empty, promoteId: 'id');
    await map.addGeoJsonSource(_src.lines, empty, promoteId: 'id');
    await map.addGeoJsonSource(_src.points, empty, promoteId: 'id');
    await map.addGeoJsonSource(_src.search, empty, promoteId: 'id');
    await map.addFillLayer(
      _src.radius,
      'hrz-radius-fill',
      const FillLayerProperties(fillColor: [Expressions.get, 'color'], fillOpacity: 0.12),
      enableInteraction: false,
    );
    await map.addLineLayer(
      _src.radius,
      'hrz-radius-line',
      const LineLayerProperties(lineColor: [Expressions.get, 'color'], lineWidth: 1.5, lineDasharray: [3, 2]),
      enableInteraction: false,
    );
    await map.addFillLayer(
      _src.lines,
      'hrz-polygons',
      const FillLayerProperties(fillColor: [Expressions.get, 'color'], fillOpacity: 0.2),
      filter: ['==', ['get', 'polygon'], true],
    );
    await map.addLineLayer(
      _src.lines,
      'hrz-lines',
      const LineLayerProperties(lineColor: [Expressions.get, 'color'], lineWidth: 3),
    );
    await map.addCircleLayer(
      _src.points,
      'hrz-dots',
      const CircleLayerProperties(
        circleRadius: 7,
        circleColor: [Expressions.get, 'color'],
        circleStrokeColor: '#ffffff',
        circleStrokeWidth: 2,
      ),
      filter: ['!', ['has', 'icon']],
    );
    await map.addSymbolLayer(
      _src.points,
      'hrz-symbols',
      const SymbolLayerProperties(
        iconImage: [Expressions.get, 'icon'],
        // Icons are rendered at 3x for sharpness; MapLibre takes image
        // pixels as points.
        iconSize: 1 / symbolPixelRatio,
        iconOffset: [Expressions.get, 'offset'],
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        textField: [Expressions.get, 'name'],
        textFont: ['Noto Sans Regular'],
        textSize: 12,
        textOffset: [0, 1.6],
        textAnchor: 'top',
        textHaloColor: '#ffffff',
        textHaloWidth: 1.5,
        textOptional: true,
      ),
    );
    await map.addCircleLayer(
      _src.search,
      'hrz-search',
      const CircleLayerProperties(
        circleRadius: 9,
        circleColor: '#00000000',
        circleStrokeColor: '#d32f2f',
        circleStrokeWidth: 3,
      ),
      enableInteraction: false,
    );
  }

  Future<void> _syncFeatures(List<MapFeature> features) async {
    final map = _map;
    if (map == null || !_styleReady) return;
    final layers = await ref.read(repositoryProvider).layers();
    final colors = {for (final l in layers) l.id: l.color};
    final icons = ref.read(symbolIconsProvider);
    for (final sidc in {for (final f in features) if (f.sidc != null) f.sidc!}) {
      if (_iconsAdded.contains(sidc)) continue;
      final png = await icons.png(sidc);
      if (png == null) continue;
      await map.addImage('sidc-$sidc', png);
      _iconsAdded.add(sidc);
    }
    await map.setGeoJsonSource(_src.radius, radiusGeoJson(features, colors));
    await map.setGeoJsonSource(_src.lines, linesGeoJson(features, colors));
    await map.setGeoJsonSource(
      _src.points,
      pointsGeoJson(features, colors, hasIcon: _iconsAdded.contains, offset: icons.offset),
    );
  }

  Future<void> _syncSearch() async {
    final map = _map;
    if (map == null || !_styleReady) return;
    final m = _searchMarker;
    await map.setGeoJsonSource(
      _src.search,
      collection([
        if (m != null)
          {
            'type': 'Feature',
            'properties': <String, Object?>{},
            'geometry': {'type': 'Point', 'coordinates': lonLat(m)},
          },
      ]),
    );
  }

  Future<void> _focus(MapFocus f) async {
    ref.read(mapFocusProvider.notifier).consumed();
    if (f.marker) {
      _searchMarker = f.point;
      await _syncSearch();
    }
    final zoom = math.max(_camera?.zoom ?? 14, 14).toDouble();
    await _map?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(f.point.lat, f.point.lon), zoom));
  }

  void _onCameraIdle() {
    final c = _map?.cameraPosition;
    if (c == null) return;
    setState(() => _camera = c);
    _saveCamera?.cancel();
    _saveCamera = Timer(const Duration(seconds: 2), () {
      ref.read(settingsProvider.notifier).update(
            (s) => s.copyWith(camera: MapCamera(c.target.latitude, c.target.longitude, c.zoom)),
          );
    });
  }

  void _cycleTracking() {
    if (!_locationAllowed) {
      ensureLocationPermission().then((_) {
        if (mounted) setState(() => _locationAllowed = true);
        _cycleTracking();
      }, onError: (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.errLocation)));
        }
      });
      return;
    }
    final next = switch (_tracking) {
      MyLocationTrackingMode.none => MyLocationTrackingMode.tracking,
      MyLocationTrackingMode.tracking => MyLocationTrackingMode.trackingCompass,
      _ => MyLocationTrackingMode.none,
    };
    setState(() => _tracking = next);
    _map?.updateMyLocationTrackingMode(next);
    if (next == MyLocationTrackingMode.none) {
      _map?.animateCamera(CameraUpdate.bearingTo(0));
    }
  }

  void _onFeatureTap(String id) {
    showFeatureSheet(context, id);
  }

  Future<void> _onLongPress(LatLng p) async {
    context.go('/map/new?lat=${p.latitude}&lon=${p.longitude}');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = ref.watch(settingsProvider);
    final packsState = ref.watch(packsProvider);
    // Wait for the pack list: building a style without it first would throw
    // the map away a moment later.
    if (packsState.hasValue) _loadStyle(settings, packsState.value!);
    ref.listen(visibleFeaturesProvider, (_, next) => _syncFeatures(next.value ?? const []));
    ref.listen(mapFocusProvider, (_, f) {
      if (f != null && _styleReady) _focus(f);
    });

    final cam = _camera;
    final center = cam == null ? null : Geodetic(cam.target.latitude, cam.target.longitude);
    final style = _style;

    return Scaffold(
      body: Stack(
        children: [
          if (style != null)
            MapLibreMap(
              key: ValueKey(_styleKey),
              styleString: style,
              initialCameraPosition: CameraPosition(
                target: LatLng(settings.camera.lat, settings.camera.lon),
                zoom: settings.camera.zoom,
              ),
              trackCameraPosition: true,
              compassEnabled: true,
              compassViewPosition: CompassViewPosition.topLeft,
              compassViewMargins: const math.Point(16, 110),
              logoEnabled: false,
              // Above the scale bar, clear of the buttons: OSM (ODbL), OpenFreeMap,
              // Protomaps and Copernicus credits come from the style's sources.
              attributionButtonPosition: AttributionButtonPosition.bottomLeft,
              attributionButtonMargins: const math.Point(12, 150),
              myLocationEnabled: _locationAllowed,
              myLocationTrackingMode: _tracking,
              myLocationRenderMode:
                  _locationAllowed ? MyLocationRenderMode.compass : MyLocationRenderMode.normal,
              onMapCreated: (c) {
                _map = c;
                _styleReady = false;
                c.onFeatureTapped.add((_, _, id, layerId, _) {
                  // Radius polygons carry '<id>-r'; everything else the object id.
                  if (layerId.startsWith('hrz-')) _onFeatureTap(id.replaceAll(RegExp(r'-r$'), ''));
                });
              },
              onStyleLoadedCallback: () async {
                await _onStyleLoaded();
                final f = ref.read(mapFocusProvider);
                if (f != null) await _focus(f);
              },
              onCameraIdle: _onCameraIdle,
              onMapLongClick: (_, p) => _onLongPress(p),
              onCameraTrackingDismissed: () => setState(() => _tracking = MyLocationTrackingMode.none),
            ),
          // Crosshair at the centre: the readout below is its position.
          const IgnorePointer(child: Center(child: Icon(Icons.add, size: 28, color: Colors.black54))),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _TopBar(onSearch: () => showSearchSheet(context)),
                  if (_noPacks)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.download_for_offline_outlined),
                        title: Text(l.noPacksTitle),
                        subtitle: Text(settings.offlineOnly ? l.noPacksOffline : l.noPacksHint),
                        onTap: () => context.go('/map/packs'),
                      ),
                    ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (cam != null) ScaleBar(lat: cam.target.latitude, zoom: cam.zoom),
                      const Spacer(),
                      Column(
                        children: [
                          FloatingActionButton.small(
                            heroTag: 'layers',
                            tooltip: l.mapLayers,
                            onPressed: () => showMapLayersSheet(context),
                            child: const Icon(Icons.layers_outlined),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton.small(
                            heroTag: 'location',
                            tooltip: l.myLocation,
                            onPressed: _cycleTracking,
                            child: Icon(switch (_tracking) {
                              MyLocationTrackingMode.none => Icons.location_searching,
                              MyLocationTrackingMode.tracking => Icons.my_location,
                              _ => Icons.explore,
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (center != null) _CenterReadout(center: center),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSearch});
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(28),
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onSearch,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.search),
              const SizedBox(width: 12),
              Expanded(child: Text(l.searchCoordinates, style: Theme.of(context).textTheme.bodyLarge)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Map centre in the default system; tap copies it.
class _CenterReadout extends ConsumerWidget {
  const _CenterReadout({required this.center});
  final Geodetic center;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    String text;
    try {
      text = formatPoint(center, s.system, s.geoFormat);
    } on RangeError {
      text = formatPoint(center, CoordinateSystem.wgs84, s.geoFormat);
    }
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => copyToClipboard(context, text),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Text('${systemName(context.l10n, s.system)}  ', style: Theme.of(context).textTheme.labelSmall),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.copy, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
