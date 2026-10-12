import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/labels.dart';
import '../../core/net/network.dart';
import '../../core/settings.dart';
import '../../l10n/app_localizations.dart';
import '../map/map_view.dart';
import '../map/packs.dart' show netProvider;
import '../map/packs_page.dart' show formatBytes;
import 'area_download.dart';
import 'map_source.dart';
import 'source_store.dart';
import 'sources_page.dart' show templateTokens;
import 'sources_repository.dart';

String templateErrorText(AppLocalizations l, TemplateError e) => switch (e) {
  TemplateError.empty => l.errTemplateEmpty,
  TemplateError.notHttps => l.errTemplateHttps,
  TemplateError.noHost => l.errTemplateHost,
  TemplateError.noTileCoordinates => l.errTemplateTiles(templateTokens.xyz, templateTokens.tms, templateTokens.wms),
  TemplateError.quadkey => l.errTemplateQuadkey,
  TemplateError.subdomainsMissing => l.errTemplateSubdomains(templateTokens.sub),
};

/// Rough size of a raster tile, for the download estimate.
const _bytesPerTile = 25000;

/// Adds or edits a URL source; for a file source, its name and attribution.
class SourceEditPage extends ConsumerStatefulWidget {
  const SourceEditPage({super.key, this.id});
  final String? id;

  @override
  ConsumerState<SourceEditPage> createState() => _SourceEditPageState();
}

class _SourceEditPageState extends ConsumerState<SourceEditPage> {
  MapSource? _source;
  bool _loaded = false;
  final _name = TextEditingController();
  final _url = TextEditingController();
  final _subdomains = TextEditingController(text: 'a,b,c');
  final _minZoom = TextEditingController(text: '0');
  final _maxZoom = TextEditingController(text: '19');
  final _attribution = TextEditingController();
  bool _tms = false;
  int _tileSize = 256;
  String? _urlError, _zoomError;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.id;
    final s = id == null ? null : await ref.read(sourcesRepositoryProvider).byId(id);
    if (!mounted) return;
    setState(() {
      _source = s;
      _loaded = true;
      if (s != null) {
        _name.text = s.name;
        _url.text = s.url ?? '';
        _subdomains.text = s.subdomains.join(',');
        _minZoom.text = '${s.minZoom}';
        _maxZoom.text = '${s.maxZoom}';
        _attribution.text = s.attribution;
        _tms = s.tms;
        _tileSize = s.tileSize;
      }
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _url, _subdomains, _minZoom, _maxZoom, _attribution]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isFile => _source?.kind == MapSourceKind.file;

  List<String> get _subs => [
    for (final s in _subdomains.text.split(',')) if (s.trim().isNotEmpty) s.trim(),
  ];

  /// The source as typed, or null with the errors shown.
  MapSource? _build() {
    final l = context.l10n;
    final lo = int.tryParse(_minZoom.text), hi = int.tryParse(_maxZoom.text);
    final zoomOk = lo != null && hi != null && lo >= 0 && hi <= 24 && lo <= hi;
    final name = _name.text.trim();
    if (_isFile) {
      setState(() => _zoomError = null);
      return _source!.copyWith(
        name: name.isEmpty ? _source!.name : name,
        attribution: _attribution.text.trim(),
        tileSize: _tileSize,
      );
    }
    final parsed = parseTemplate(_url.text, subdomains: _url.text.contains('{s}') ? _subs : const []);
    setState(() {
      _urlError = parsed.error == null ? null : templateErrorText(l, parsed.error!);
      _zoomError = zoomOk ? null : l.errZoomRange;
    });
    final t = parsed.template;
    if (t == null || !zoomOk) return null;
    final fields = (
      name: name.isEmpty ? t.host : name,
      url: t.url,
      tms: _tms || t.tms,
      subdomains: t.url.contains('{s}') ? _subs : const <String>[],
      minZoom: lo,
      maxZoom: hi,
      tileSize: _tileSize,
      attribution: _attribution.text.trim(),
    );
    final cur = _source;
    if (cur != null) {
      return cur.copyWith(
        name: fields.name,
        url: fields.url,
        tms: fields.tms,
        subdomains: fields.subdomains,
        minZoom: fields.minZoom,
        maxZoom: fields.maxZoom,
        tileSize: fields.tileSize,
        attribution: fields.attribution,
      );
    }
    return ref.read(sourcesRepositoryProvider).create(
      name: fields.name,
      kind: MapSourceKind.url,
      url: fields.url,
      tms: fields.tms,
      subdomains: fields.subdomains,
      minZoom: fields.minZoom,
      maxZoom: fields.maxZoom,
      tileSize: fields.tileSize,
      attribution: fields.attribution,
    );
  }

  Future<void> _save() async {
    final s = _build();
    if (s == null) return;
    await ref.read(sourcesRepositoryProvider).save(s);
    if (mounted) context.pop();
  }

  /// Fetches one tile at the map's centre (or Kyiv) through the app's
  /// network client, as the area download would.
  Future<void> _test() async {
    final l = context.l10n;
    final s = _build();
    if (s == null) return;
    setState(() => _testing = true);
    final messenger = ScaffoldMessenger.of(context);
    String message;
    try {
      final b = ref.read(visibleBoundsProvider);
      final lat = b == null ? 50.45 : (b.north + b.south) / 2, lon = b == null ? 30.52 : (b.east + b.west) / 2;
      final z = 12.clamp(s.minZoom, s.maxZoom);
      final (x, y) = tileOf(lat, lon, z);
      final net = Net(
        offlineOnly: () => ref.read(settingsProvider).offlineOnly,
        userHosts: () => sourceHosts(s),
      );
      final res = await net.get(Uri.parse(tileUrl(s, z, x, y)));
      final bytes = BytesBuilder(copy: false);
      await for (final c in res) {
        bytes.add(c);
      }
      final data = bytes.takeBytes();
      final format = imageFormat(data);
      message = res.statusCode == 404 || res.statusCode == 204
          ? l.sourceTestEmpty
          : res.statusCode != 200
          ? l.sourceTestFailed('HTTP ${res.statusCode}')
          : format == null
          ? l.sourceTestFailed('not an image')
          : l.sourceTestOk(formatBytes(l, data.length), format);
    } on NetworkBlocked catch (e) {
      message = e.reason == 'offline-only' ? l.sourceOfflineBlocked : l.sourceTestFailed(e.reason);
    } catch (e) {
      message = l.sourceTestFailed(e is SocketException ? e.message : '$e');
    }
    if (!mounted) return;
    setState(() => _testing = false);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final s = _source!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.sourceDeleteQuestion(s.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.delete)),
        ],
      ),
    );
    if (ok != true) return;
    final store = ref.read(sourceStoreProvider);
    await ref.read(sourcesRepositoryProvider).delete(s.id);
    if (s.file != null) await store.deleteFile(s.file!);
    await store.deleteFile(s.downloadFile);
    ref.invalidate(sourceFilesProvider);
    if (mounted) context.pop();
  }

  Future<void> _deleteDownloaded() async {
    await ref.read(sourceStoreProvider).deleteFile(_source!.downloadFile);
    ref.invalidate(sourceFilesProvider);
  }

  Future<void> _download() async {
    final s = _source;
    if (s == null) return;
    final saved = _build();
    if (saved == null) return;
    await ref.read(sourcesRepositoryProvider).save(saved);
    if (!mounted) return;
    await showAreaDownload(context, ref, saved);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final files = ref.watch(sourceFilesProvider).value ?? const {};
    final s = _source;
    final downloaded = s == null ? null : files[s.downloadFile];
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(
        title: Text(s?.name ?? l.sourceNew),
        actions: [
          if (s != null) IconButton(icon: const Icon(Icons.delete_outline), tooltip: l.delete, onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_isFile) ...[
            Text(l.sourcesNote, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: l.sourceName, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          if (_isFile)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: Text(l.sourceFileInfo(s!.minZoom, s.maxZoom, formatBytes(l, files[s.file]?.$1 ?? 0))),
            )
          else ...[
            TextField(
              controller: _url,
              keyboardType: TextInputType.url,
              autocorrect: false,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                labelText: l.sourceUrl,
                hintText: 'https://…/${templateTokens.xyz}.png',
                helperText: l.sourceUrlHelp(templateTokens.xyz, templateTokens.sub, templateTokens.tms, templateTokens.wms),
                helperMaxLines: 3,
                errorText: _urlError,
                errorMaxLines: 3,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subdomains,
              autocorrect: false,
              decoration: InputDecoration(labelText: l.sourceSubdomains, border: const OutlineInputBorder()),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.sourceTms),
              value: _tms,
              onChanged: (v) => setState(() => _tms = v),
            ),
            Row(
              children: [
                Expanded(child: _zoomField(_minZoom, l.sourceMinZoom)),
                const SizedBox(width: 12),
                Expanded(child: _zoomField(_maxZoom, l.sourceMaxZoom)),
              ],
            ),
            if (_zoomError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(_zoomError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text(l.sourceTileSize)),
              SegmentedButton<int>(
                segments: const [ButtonSegment(value: 256, label: Text('256')), ButtonSegment(value: 512, label: Text('512'))],
                selected: {_tileSize},
                showSelectedIcon: false,
                onSelectionChanged: (v) => setState(() => _tileSize = v.single),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _attribution,
            decoration: InputDecoration(labelText: l.sourceAttribution, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: Text(l.save)),
              if (!_isFile)
                OutlinedButton.icon(
                  onPressed: _testing ? null : _test,
                  icon: const Icon(Icons.network_check),
                  label: Text(l.sourceTest),
                ),
            ],
          ),
          if (s != null && !_isFile) ...[
            const Divider(height: 32),
            if (downloaded != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.offline_pin_outlined),
                title: Text(l.sourceDownloaded(formatBytes(l, downloaded.$1))),
                trailing: TextButton(onPressed: _deleteDownloaded, child: Text(l.sourceDeleteDownloaded)),
              ),
            OutlinedButton.icon(
              onPressed: _download,
              icon: const Icon(Icons.download_for_offline_outlined),
              label: Text(l.sourceDownloadArea),
            ),
          ],
        ],
      ),
    );
  }

  Widget _zoomField(TextEditingController c, String label) => TextField(
    controller: c,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
  );
}

/// Asks for the zoom range over the visible area and downloads it.
Future<void> showAreaDownload(BuildContext context, WidgetRef ref, MapSource s) async {
  final l = context.l10n;
  final bounds = ref.read(visibleBoundsProvider);
  if (bounds == null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.sourceDownloadNoArea)));
    return;
  }
  final range = await showDialog<RangeValues>(
    context: context,
    builder: (_) => _ZoomRangeDialog(source: s, bounds: bounds),
  );
  if (range == null || !context.mounted) return;
  final store = ref.read(sourceStoreProvider);
  final job = AreaDownload(
    net: ref.read(netProvider),
    source: s,
    bounds: bounds,
    minZoom: range.start.round(),
    maxZoom: range.end.round(),
    path: await store.path(s.downloadFile),
  );
  if (!context.mounted) return;
  final result = await showDialog<DownloadProgress?>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ProgressDialog(job: job),
  );
  ref.invalidate(sourceFilesProvider);
  if (result != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.sourceDownloadDone(result.done - result.failed, result.failed))),
    );
  }
}

class _ZoomRangeDialog extends StatefulWidget {
  const _ZoomRangeDialog({required this.source, required this.bounds});
  final MapSource source;
  final Bounds bounds;

  @override
  State<_ZoomRangeDialog> createState() => _ZoomRangeDialogState();
}

class _ZoomRangeDialogState extends State<_ZoomRangeDialog> {
  late RangeValues _range = RangeValues(
    widget.source.minZoom.clamp(10, widget.source.maxZoom).toDouble(),
    widget.source.maxZoom.clamp(widget.source.minZoom, 15).toDouble(),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = widget.source;
    final lo = _range.start.round(), hi = _range.end.round();
    final n = tileCount(widget.bounds, lo, hi);
    final tooMany = n > maxDownloadTiles;
    return AlertDialog(
      title: Text(l.sourceDownloadTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.sourceDownloadZooms(lo, hi)),
          if (s.maxZoom > s.minZoom)
            RangeSlider(
              values: _range,
              min: s.minZoom.toDouble(),
              max: s.maxZoom.toDouble(),
              divisions: s.maxZoom - s.minZoom,
              onChanged: (v) => setState(() => _range = v),
            ),
          Text(
            tooMany ? l.sourceDownloadTooMany(maxDownloadTiles) : l.sourceDownloadTiles(n, formatBytes(l, n * _bytesPerTile)),
            style: tooMany ? TextStyle(color: Theme.of(context).colorScheme.error) : null,
          ),
          const SizedBox(height: 12),
          Text(l.sourceDownloadTerms, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          onPressed: tooMany ? null : () => Navigator.pop(context, _range),
          child: Text(l.sourceDownloadStart),
        ),
      ],
    );
  }
}

class _ProgressDialog extends StatefulWidget {
  const _ProgressDialog({required this.job});
  final AreaDownload job;

  @override
  State<_ProgressDialog> createState() => _ProgressDialogState();
}

class _ProgressDialogState extends State<_ProgressDialog> {
  DownloadProgress? _p;
  StreamSubscription<DownloadProgress>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.job.run().listen(
      (p) => setState(() => _p = p),
      onError: (Object e) {
        if (!mounted) return;
        final l = context.l10n;
        final text = e is NetworkBlocked && e.reason == 'offline-only' ? l.sourceOfflineBlocked : l.sourceTestFailed('$e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
      },
      onDone: () {
        if (mounted) Navigator.pop(context, _p);
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = _p;
    return AlertDialog(
      title: Text(l.sourceDownloadTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: p == null ? null : p.done / p.total),
          const SizedBox(height: 12),
          if (p != null) Text(l.sourceDownloading(p.done, p.total, formatBytes(l, p.bytes))),
        ],
      ),
      actions: [TextButton(onPressed: widget.job.cancel, child: Text(l.cancel))],
    );
  }
}
