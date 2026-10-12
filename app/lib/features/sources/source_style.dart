import 'map_source.dart';

/// Prefix of the user source layers and sources in the map style.
const userSourcePrefix = 'usersrc-';

String userLayerId(MapSource s, {bool downloaded = false}) => '$userSourcePrefix${s.id}${downloaded ? '-dl' : ''}';

String _fileUrl(String path) =>
    path.toLowerCase().endsWith('.mbtiles') ? 'mbtiles://$path' : 'pmtiles://file://$path';

/// MapLibre raster source for an online URL source.
Map<String, Object?> onlineSourceJson(MapSource s) => {
  'type': 'raster',
  'tiles': tileUrls(s),
  'scheme': s.tms ? 'tms' : 'xyz',
  'tileSize': s.tileSize,
  'minzoom': s.minZoom,
  'maxzoom': s.maxZoom,
  if (s.attribution.isNotEmpty) 'attribution': s.attribution,
};

/// MapLibre raster source for a local MBTiles or PMTiles file; zoom range
/// and bounds come from the file.
Map<String, Object?> fileSourceJson(String path, MapSource s) => {
  'type': 'raster',
  'url': _fileUrl(path),
  'tileSize': s.tileSize,
  if (s.attribution.isNotEmpty) 'attribution': s.attribution,
};

/// Lays the enabled user sources over the base map, later ones on top.
///
/// A URL source is drawn from the network only when [network] (not
/// offline-only, privacy note read), and from its downloaded area file when
/// there is one ([downloaded] holds the file names in [dir]). With both, the
/// downloaded tiles go underneath, so they show wherever the network does
/// not deliver.
void addUserSources(
  Map<String, Object?> style,
  List<MapSource> sources, {
  required bool network,
  required String dir,
  required Set<String> downloaded,
}) {
  final srcs = (style['sources']! as Map<String, Object?>);
  final layers = (style['layers']! as List<Object?>).toList();
  void add(String id, Map<String, Object?> source, double opacity) {
    srcs[id] = source;
    layers.add({
      'id': id,
      'type': 'raster',
      'source': id,
      'paint': {'raster-opacity': opacity, 'raster-fade-duration': 0},
    });
  }

  for (final s in sources) {
    if (!s.enabled) continue;
    switch (s.kind) {
      case MapSourceKind.file:
        final f = s.file;
        if (f != null) add(userLayerId(s), fileSourceJson('$dir/$f', s), s.opacity);
      case MapSourceKind.url:
        if (downloaded.contains(s.downloadFile)) {
          add(userLayerId(s, downloaded: true), fileSourceJson('$dir/${s.downloadFile}', s), s.opacity);
        }
        if (network && s.url != null) add(userLayerId(s), onlineSourceJson(s), s.opacity);
    }
  }
  style['layers'] = layers;
}

/// Layer ids of [s] in a style built by [addUserSources].
List<String> userLayerIds(MapSource s) => [userLayerId(s), userLayerId(s, downloaded: true)];

/// What the map's style depends on; opacity is applied without a rebuild.
String userSourcesKey(List<MapSource> sources, Map<String, (int, DateTime)> files, {required bool network}) => [
  'net:$network',
  for (final s in sources)
    if (s.enabled)
      [
        s.id,
        s.url,
        s.tms,
        s.subdomains.join(','),
        s.minZoom,
        s.maxZoom,
        s.tileSize,
        s.attribution,
        s.file,
        files[s.downloadFile]?.$2.millisecondsSinceEpoch,
      ].join('|'),
].join(';');
