import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/net/network.dart';
import 'packs.dart';

/// Offline style for any number of region packs. The template from
/// tools/map-pipeline/style has one `protomaps` and one `dem` source; each
/// pack gets its own copy of them, and every template layer is repeated per
/// pack right after itself so that draw order stays the same across regions
/// (all water below all roads below all labels).
String buildOfflineStyle(String template, List<PackFile> packs, String assetsPath) {
  final style = jsonDecode(template.replaceAll('{ASSETS_URL}', 'file://$assetsPath'))
      as Map<String, Object?>;
  final srcTemplates = (style['sources']! as Map<String, Object?>).cast<String, Object?>();
  final sources = <String, Object?>{};
  final basemaps = [for (final p in packs) if (p.kind == PackKind.basemap) p];
  final dems = [for (final p in packs) if (p.kind == PackKind.dem) p];
  String sourceId(String base, int i) => '${base}_$i';

  for (final (i, p) in basemaps.indexed) {
    sources[sourceId('protomaps', i)] = {
      ...(srcTemplates['protomaps']! as Map<String, Object?>),
      'url': 'pmtiles://file://${p.path}',
    };
  }
  for (final (i, p) in dems.indexed) {
    sources[sourceId('dem', i)] = {
      ...(srcTemplates['dem']! as Map<String, Object?>),
      'url': 'pmtiles://file://${p.path}',
    };
  }

  final layers = <Object?>[];
  for (final l in (style['layers']! as List<Object?>).cast<Map<String, Object?>>()) {
    final src = l['source'] as String?;
    final copies = switch (src) {
      'protomaps' => basemaps.length,
      'dem' => dems.length,
      _ => 1,
    };
    for (var i = 0; i < copies; i++) {
      layers.add(src == null ? l : {...l, 'id': '${l['id']}_$i', 'source': sourceId(src, i)});
    }
  }
  style['sources'] = sources;
  style['layers'] = layers;
  return jsonEncode(style);
}

Future<String> offlineStyle(List<PackFile> packs) async {
  final template = await rootBundle.loadString('assets/map/style-offline.json');
  return buildOfflineStyle(template, packs, await PackStore.installAssets());
}

/// Rewrites every label of the OpenFreeMap style to prefer Ukrainian names,
/// and drops anything in it that would make MapLibre contact a host outside
/// [allowedHosts]: MapLibre fetches tiles, glyphs and sprites itself, past
/// the app's own HTTP client.
String ukrainianLabels(String styleJson) {
  final style = jsonDecode(styleJson) as Map<String, Object?>;
  restrictHosts(style);
  const name = ['coalesce', ['get', 'name:uk'], ['get', 'name']];
  for (final l in (style['layers']! as List<Object?>).cast<Map<String, Object?>>()) {
    final layout = l['layout'] as Map<String, Object?>?;
    final field = layout?['text-field'];
    if (field == null) continue;
    final text = jsonEncode(field);
    // Road refs and house numbers stay as they are; place, water, POI and
    // street names switch language.
    if (text.contains('name')) layout!['text-field'] = name;
  }
  return jsonEncode(style);
}

/// Online style, patched for Ukrainian labels and cached so the map still
/// opens (with cached tiles) when the network is gone.
Future<String> onlineStyle(Net net) async {
  final cache = File('${(await getApplicationSupportDirectory()).path}/online-style.json');
  try {
    final style = ukrainianLabels(await net.getString(Uri.parse(onlineStyleUrl)));
    await cache.writeAsString(style);
    return style;
  } catch (_) {
    if (await cache.exists()) return cache.readAsString();
    rethrow;
  }
}

bool _allowedUrl(Object? url) {
  if (url is! String) return false;
  final u = Uri.tryParse(url.replaceAll('{', '').replaceAll('}', ''));
  return u != null && u.scheme == 'https' && allowedHosts.contains(u.host);
}

/// Removes sources, glyphs and sprites pointing outside [allowedHosts], and
/// the layers that used those sources.
void restrictHosts(Map<String, Object?> style) {
  final sources = (style['sources'] as Map<String, Object?>?) ?? {};
  final dropped = <String>{};
  for (final e in sources.entries.toList()) {
    final src = e.value as Map<String, Object?>;
    final urls = [?src['url'], ...((src['tiles'] as List<Object?>?) ?? const [])];
    if (urls.isEmpty || !urls.every(_allowedUrl)) {
      sources.remove(e.key);
      dropped.add(e.key);
    }
  }
  final layers = (style['layers'] as List<Object?>?) ?? [];
  layers.removeWhere((l) => dropped.contains((l as Map<String, Object?>)['source']));
  if (style['glyphs'] != null && !_allowedUrl(style['glyphs'])) style.remove('glyphs');
  final sprite = style['sprite'];
  if (sprite is String && !_allowedUrl(sprite)) style.remove('sprite');
  if (sprite is List && !sprite.every((s) => _allowedUrl((s as Map<String, Object?>)['url']))) {
    style.remove('sprite');
  }
}
