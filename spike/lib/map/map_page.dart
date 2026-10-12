import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'dem_reader.dart';
import 'map_packs.dart';

const _onlineStyle = 'https://tiles.openfreemap.org/styles/liberty';
const _kyiv = LatLng(50.45, 30.52);

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  MapLibreMapController? _map;
  List<PackFile> _packs = [];
  PackFile? _basemap;
  PackFile? _dem;
  DemReader? _reader;
  String? _style; // null = online
  String _info = 'Онлайн: OpenFreeMap';
  LatLng? _profileStart;
  Completer<void>? _styleLoaded;

  DemReader? get reader => _reader;

  /// Autotest: switch to the offline pack, ms until MapLibre reports the style loaded.
  Future<int> goOfflineAndWait() async {
    final sw = Stopwatch()..start();
    final loaded = _styleLoaded = Completer<void>();
    await _goOffline();
    await loaded.future.timeout(const Duration(seconds: 30));
    return sw.elapsedMilliseconds;
  }

  Future<void> moveTo(double lat, double lon, double zoom) async {
    await _map?.moveCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lon), zoom));
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _reader?.close();
    super.dispose();
  }

  Future<void> _reload() async {
    final packs = await MapPacks.list();
    setState(() {
      _packs = packs;
      _basemap ??= packs.where((p) => p.isVector).firstOrNull;
      _dem ??= packs.where((p) => !p.isVector).firstOrNull;
    });
  }

  Future<void> _goOffline() async {
    await _reload(); // packs may have been dropped in through Files/Finder
    final basemap = _basemap;
    if (basemap == null) {
      _toast('Немає векторного пакета. Імпортуйте .pmtiles');
      return;
    }
    final sw = Stopwatch()..start();
    final style = await MapPacks.offlineStyle(basemap, _dem);
    await _reader?.close();
    _reader = _dem == null ? null : await DemReader.open(_dem!.path);
    setState(() {
      _style = style;
      _info = 'Офлайн: ${basemap.name} (${basemap.sizeLabel})'
          '${_dem == null ? '' : ' + ${_dem!.name} (${_dem!.sizeLabel})'}'
          ', стиль ${sw.elapsedMilliseconds} мс';
    });
  }

  void _goOnline() => setState(() {
        _style = null;
        _info = 'Онлайн: OpenFreeMap';
      });

  Future<void> _import() async {
    final files = await FilePicker.pickFiles();
    for (final f in files) {
      if (f.path == null) continue;
      final pack = await MapPacks.import(f.path!);
      if (pack == null) _toast('${f.name}: не PMTiles');
    }
    await _reload();
  }

  Future<void> _onTap(LatLng p) async {
    final reader = _reader;
    if (reader == null) return;
    final sw = Stopwatch()..start();
    final h = await reader.elevation(p.latitude, p.longitude);
    _toast('${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}: '
        '${h == null ? 'немає даних' : '${h.toStringAsFixed(1)} м'} (${sw.elapsedMilliseconds} мс)');
  }

  /// Long press twice: profile between the two points.
  Future<void> _onLongPress(LatLng p) async {
    final reader = _reader;
    final map = _map;
    if (reader == null || map == null) return;
    final start = _profileStart;
    if (start == null) {
      _profileStart = p;
      await map.clearLines();
      await map.clearCircles();
      await map.addCircle(CircleOptions(geometry: p, circleRadius: 6, circleColor: '#c0392b'));
      _toast('Точка А. Довге натискання ще раз — точка Б');
      return;
    }
    _profileStart = null;
    await map.addCircle(CircleOptions(geometry: p, circleRadius: 6, circleColor: '#c0392b'));
    await map.addLine(LineOptions(geometry: [start, p], lineColor: '#c0392b', lineWidth: 3));
    final sw = Stopwatch()..start();
    final heights = await reader.profile(start.latitude, start.longitude, p.latitude, p.longitude);
    final ms = sw.elapsedMilliseconds;
    final valid = heights.whereType<double>().toList();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => _ProfileSheet(heights: heights, ms: ms, valid: valid),
    );
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мапа'),
        actions: [
          IconButton(icon: const Icon(Icons.file_open_outlined), tooltip: 'Імпорт PMTiles', onPressed: _import),
          IconButton(icon: const Icon(Icons.layers_outlined), tooltip: 'Пакети', onPressed: _showPacks),
        ],
      ),
      body: Stack(
        children: [
          MapLibreMap(
            key: ValueKey(_style ?? 'online'),
            styleString: _style ?? _onlineStyle,
            initialCameraPosition: const CameraPosition(target: _kyiv, zoom: 10),
            onMapCreated: (c) => _map = c,
            onStyleLoadedCallback: () {
              final c = _styleLoaded;
              if (c != null && !c.isCompleted && _style != null) c.complete();
            },
            onMapClick: (_, p) => _onTap(p),
            onMapLongClick: (_, p) => _onLongPress(p),
            compassEnabled: true,
            scaleControlEnabled: true,
            attributionButtonPosition: AttributionButtonPosition.bottomRight,
          ),
          Positioned(
            left: 8,
            right: 8,
            top: 8,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(_info, style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _style == null ? _goOffline : _goOnline,
        icon: Icon(_style == null ? Icons.cloud_off : Icons.cloud_outlined),
        label: Text(_style == null ? 'Офлайн' : 'Онлайн'),
      ),
    );
  }

  Future<void> _showPacks() async {
    await _reload();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Пакети в Documents/packs')),
            if (_packs.isEmpty) const ListTile(title: Text('Порожньо')),
            for (final p in _packs)
              ListTile(
                leading: Icon(p.isVector ? Icons.map : Icons.terrain),
                title: Text(p.name),
                subtitle: Text('${p.isVector ? 'векторна карта' : 'висоти'}, '
                    '${p.sizeLabel}, z${p.minZoom}–${p.maxZoom}'),
                trailing: (p.isVector ? _basemap : _dem)?.path == p.path
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  setState(() => p.isVector ? _basemap = p : _dem = p);
                  setSheet(() {});
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSheet extends StatelessWidget {
  const _ProfileSheet({required this.heights, required this.ms, required this.valid});

  final List<double?> heights;
  final List<double> valid;
  final int ms;

  @override
  Widget build(BuildContext context) {
    final summary = valid.isEmpty
        ? 'Немає даних висот'
        : 'Мін ${valid.reduce((a, b) => a < b ? a : b).toStringAsFixed(0)} м, '
            'макс ${valid.reduce((a, b) => a > b ? a : b).toStringAsFixed(0)} м; '
            '${heights.length} точок за $ms мс';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Профіль висот', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(summary),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(painter: _ProfilePainter(heights, Theme.of(context).colorScheme.primary)),
          ),
          const SizedBox(height: 8),
          Text('Copernicus DEM: висота поверхні, включно з лісом і забудовою',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ProfilePainter extends CustomPainter {
  _ProfilePainter(this.heights, this.color);

  final List<double?> heights;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final valid = heights.whereType<double>();
    if (valid.isEmpty) return;
    final lo = valid.reduce((a, b) => a < b ? a : b);
    final hi = valid.reduce((a, b) => a > b ? a : b);
    final span = (hi - lo).clamp(1.0, double.infinity);
    final path = Path();
    var started = false;
    for (var i = 0; i < heights.length; i++) {
      final h = heights[i];
      if (h == null) continue;
      final x = size.width * i / (heights.length - 1);
      final y = size.height - (h - lo) / span * size.height;
      started ? path.lineTo(x, y) : path.moveTo(x, y);
      started = true;
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_ProfilePainter old) => old.heights != heights;
}
