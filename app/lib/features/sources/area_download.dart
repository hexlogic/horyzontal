import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../../core/net/network.dart';
import 'map_source.dart';
import 'source_store.dart';

typedef Bounds = ({double south, double west, double north, double east});

/// Most tiles one download may fetch: about 1–2 GB of imagery and hours of
/// a tile server's time. Bigger areas go at lower zooms or in parts.
const maxDownloadTiles = 50000;

class DownloadProgress {
  const DownloadProgress(this.done, this.total, this.failed, this.bytes);
  final int done, total, failed, bytes;
  bool get finished => done >= total;
}

/// Fetches the tiles of a URL source over an area through [Net] (so the
/// allow list and offline-only mode hold) into the source's MBTiles file,
/// which the map then shows without the network. Already stored tiles are
/// fetched again: a second run refreshes the area.
class AreaDownload {
  AreaDownload({
    required this.net,
    required this.source,
    required this.bounds,
    required this.minZoom,
    required this.maxZoom,
    required this.path,
    this.parallel = 4,
  }) : assert(source.kind == MapSourceKind.url);

  final Net net;
  final MapSource source;
  final Bounds bounds;
  final int minZoom, maxZoom, parallel;

  /// The MBTiles file to write.
  final String path;

  bool _cancelled = false;
  void cancel() => _cancelled = true;

  int get total => tileCount(bounds, minZoom, maxZoom);

  Stream<DownloadProgress> run() {
    final out = StreamController<DownloadProgress>();
    () async {
      final total = this.total;
      if (total > maxDownloadTiles) {
        out.addError(StateError('too many tiles: $total'));
        await out.close();
        return;
      }
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 20)
        ..userAgent = 'Horyzontal';
      final writer = MbTilesWriter.open(path, name: source.name, attribution: source.attribution);
      final tiles = tilesIn(bounds, minZoom, maxZoom).iterator;
      var done = 0, failed = 0, bytes = 0;
      String? format;
      Object? fatal;

      Future<void> worker() async {
        while (!_cancelled && fatal == null && tiles.moveNext()) {
          final (z, x, y) = tiles.current;
          try {
            final data = await _fetch(client, Uri.parse(tileUrl(source, z, x, y)));
            if (data != null) {
              writer.put(z, x, y, data);
              format ??= imageFormat(data);
              bytes += data.length;
            }
          } on NetworkBlocked catch (e) {
            fatal = e;
          } catch (_) {
            failed++;
          }
          done++;
          if (!out.isClosed) out.add(DownloadProgress(done, total, failed, bytes));
        }
      }

      try {
        await Future.wait([for (var i = 0; i < parallel; i++) worker()]);
        writer.finish(format: format);
        if (fatal != null) out.addError(fatal!);
      } finally {
        writer.close();
        client.close(force: true);
        await out.close();
      }
    }();
    return out.stream;
  }

  /// Tile bytes, or null where the server has none (404, 204).
  Future<Uint8List?> _fetch(HttpClient client, Uri u) async {
    final res = await net.get(u, client: client);
    if (res.statusCode == 404 || res.statusCode == 204) {
      await res.drain<void>();
      return null;
    }
    if (res.statusCode != 200) {
      await res.drain<void>();
      throw HttpException('HTTP ${res.statusCode}');
    }
    final b = BytesBuilder(copy: false);
    await for (final chunk in res) {
      b.add(chunk);
    }
    final data = b.takeBytes();
    if (imageFormat(data) == null) throw const FormatException('not an image');
    return data;
  }
}
